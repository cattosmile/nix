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
const reconnectDelay = 3000;
const outputsEventSubscription = 1 << 6;

let recording = false;
let replayBuffer = false;
let lastPublishedState = "";
let reconnectTimer = null;

function sha256Base64(value) {
    return createHash("sha256").update(value).digest("base64");
}

function authenticationString(password, salt, challenge) {
    const secret = sha256Base64(password + salt);
    return sha256Base64(secret + challenge);
}

function publish(force = false) {
    const state = JSON.stringify({
        recording,
        replayBuffer,
        active: recording || replayBuffer
    });

    if (force || state !== lastPublishedState) {
        lastPublishedState = state;
        process.stdout.write(`${state}\n`);
    }
}

function clearOutputs() {
    recording = false;
    replayBuffer = false;
    publish();
}

function scheduleReconnect() {
    if (reconnectTimer !== null)
        return;

    clearOutputs();
    reconnectTimer = setTimeout(() => {
        reconnectTimer = null;
        connect();
    }, reconnectDelay);
}

function sendRequest(websocket, requestType, requestId) {
    websocket.send(JSON.stringify({
        op: 6,
        d: {
            requestType,
            requestId
        }
    }));
}

async function connect() {
    let config;

    try {
        config = JSON.parse(await readFile(configPath, "utf8"));
    } catch {
        scheduleReconnect();
        return;
    }

    if (!config.server_enabled) {
        scheduleReconnect();
        return;
    }

    const port = Number(config.server_port) || 4455;
    const websocket = new WebSocket(
        `ws://127.0.0.1:${port}`,
        "obswebsocket.json"
    );
    const recordRequestId = randomUUID();
    const replayRequestId = randomUUID();
    let recordStatusReceived = false;
    let replayStatusReceived = false;
    let connectionClosed = false;

    const handshakeTimeout = setTimeout(() => {
        websocket.close();
    }, 5000);

    function publishInitialStatus() {
        if (recordStatusReceived && replayStatusReceived)
            publish();
    }

    websocket.addEventListener("error", () => {
        websocket.close();
    });

    websocket.addEventListener("close", () => {
        if (connectionClosed)
            return;

        connectionClosed = true;
        clearTimeout(handshakeTimeout);
        scheduleReconnect();
    });

    websocket.addEventListener("message", event => {
        let message;

        try {
            message = JSON.parse(event.data);
        } catch {
            return;
        }

        if (message.op === 0) {
            const identify = {
                rpcVersion: 1,
                eventSubscriptions: outputsEventSubscription
            };
            const challenge = message.d.authentication;

            if (challenge) {
                if (!config.auth_required || !config.server_password) {
                    websocket.close();
                    return;
                }

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
            clearTimeout(handshakeTimeout);
            sendRequest(websocket, "GetRecordStatus", recordRequestId);
            sendRequest(
                websocket,
                "GetReplayBufferStatus",
                replayRequestId
            );
            return;
        }

        if (message.op === 5) {
            const eventType = message.d.eventType;
            const eventData = message.d.eventData ?? {};

            if (eventType === "RecordStateChanged") {
                recording = eventData.outputActive === true;
                publish();
            } else if (eventType === "ReplayBufferStateChanged") {
                replayBuffer = eventData.outputActive === true;
                publish();
            }
            return;
        }

        if (message.op !== 7 || !message.d.requestStatus.result)
            return;

        if (message.d.requestId === recordRequestId) {
            recording = message.d.responseData.outputActive === true;
            recordStatusReceived = true;
            publishInitialStatus();
        } else if (message.d.requestId === replayRequestId) {
            replayBuffer = message.d.responseData.outputActive === true;
            replayStatusReceived = true;
            publishInitialStatus();
        }
    });
}

publish(true);
connect();
