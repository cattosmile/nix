/*
 * Equicord user plugin native bridge
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { watch } from "fs";
import { readFile } from "fs/promises";
import { basename, dirname, join } from "path";

const runtimeDir = process.env.XDG_RUNTIME_DIR
    ?? `/run/user/${process.getuid()}`;
const routeFile = join(runtimeDir, "quickshell-discord-route");

async function readState() {
    try {
        return await readFile(routeFile, "utf8");
    } catch {
        return "";
    }
}

export function readRouteState() {
    return readState();
}

export async function waitForRoute(
    _event: unknown,
    previousState: string
): Promise<string> {
    const currentState = await readState();

    if (currentState !== previousState)
        return currentState;

    return new Promise(resolve => {
        let settled = false;

        const finish = (state: string) => {
            if (settled)
                return;

            settled = true;
            clearTimeout(timeout);
            watcher.close();
            resolve(state);
        };

        const watcher = watch(
            dirname(routeFile),
            { persistent: false },
            (_eventType, filename) => {
                if (filename?.toString() !== basename(routeFile))
                    return;

                void readState().then(state => {
                    if (state !== previousState)
                        finish(state);
                });
            }
        );

        const timeout = setTimeout(
            () => finish(previousState),
            30000
        );
    });
}
