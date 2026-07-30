import { createHash, randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const configHome = process.env.XDG_CONFIG_HOME
    || join(homedir(), ".config");
const configPath = join(
    configHome,
    "obs-studio",
    "plugin_config",
    "obs-websocket",
    "config.json"
);

function sha256Base64(value) {
    return createHash("sha256").update(value).digest("base64");
}

function authenticationString(password, salt, challenge) {
    const secret = sha256Base64(password + salt);
    return sha256Base64(secret + challenge);
}

function output(message, exitCode) {
    const stream = exitCode === 0 ? process.stdout : process.stderr;
    stream.write(`${message}\n`);
    process.exit(exitCode);
}

let config;

try {
    config = JSON.parse(await readFile(configPath, "utf8"));
} catch {
    output("OBS WebSocket configuration could not be read.", 1);
}

if (!config.server_enabled)
    output("OBS WebSocket server is disabled.", 1);

const port = Number(config.server_port) || 4455;
const websocket = new WebSocket(
    `ws://127.0.0.1:${port}`,
    "obswebsocket.json"
);
const statusRequestId = randomUUID();
const saveRequestId = randomUUID();
let finished = false;

const timeout = setTimeout(() => {
    if (!finished)
        output("OBS WebSocket request timed out.", 1);
}, 5000);

function sendRequest(requestType, requestId) {
    websocket.send(JSON.stringify({
        op: 6,
        d: {
            requestType,
            requestId
        }
    }));
}

websocket.addEventListener("error", () => {
    if (!finished)
        output("Could not connect to OBS WebSocket.", 1);
});

websocket.addEventListener("message", event => {
    let message;

    try {
        message = JSON.parse(event.data);
    } catch {
        output("OBS WebSocket returned invalid data.", 1);
    }

    if (message.op === 0) {
        const identify = {
            rpcVersion: 1,
            eventSubscriptions: 0
        };
        const challenge = message.d.authentication;

        if (challenge) {
            if (!config.auth_required || !config.server_password)
                output("OBS WebSocket authentication is unavailable.", 1);

            identify.authentication = authenticationString(
                config.server_password,
                challenge.salt,
                challenge.challenge
            );
        }

        websocket.send(JSON.stringify({
            op: 1,
            d: identify
        }));
        return;
    }

    if (message.op === 2) {
        sendRequest("GetReplayBufferStatus", statusRequestId);
        return;
    }

    if (message.op !== 7)
        return;

    const response = message.d;

    if (!response.requestStatus.result) {
        const reason = response.requestStatus.comment
            || "OBS rejected the request.";
        output(reason, 1);
    }

    if (response.requestId === statusRequestId) {
        if (!response.responseData.outputActive)
            output("Replay Buffer is not running.", 1);

        sendRequest("SaveReplayBuffer", saveRequestId);
        return;
    }

    if (response.requestId === saveRequestId) {
        finished = true;
        clearTimeout(timeout);
        websocket.close();
        output("Replay saved.", 0);
    }
});
