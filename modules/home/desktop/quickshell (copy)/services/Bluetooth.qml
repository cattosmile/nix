pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        if (root.enabled)
            blockProc.running = true;
        else
            unblockProc.running = true;
    }

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: statusProc
        command: ["rfkill", "list", "bluetooth"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split('\n');
                let hasAdapter = false;
                let softBlocked = false;
                for (const line of lines) {
                    if (line.includes('Bluetooth')) {
                        hasAdapter = true;
                    }
                    if (line.includes('Soft blocked: yes')) {
                        softBlocked = true;
                    }
                }
                root.enabled = hasAdapter && !softBlocked;
            }
        }
    }

    Process {
        id: blockProc
        command: ["rfkill", "block", "bluetooth"]
        onExited: root.refresh()
    }

    Process {
        id: unblockProc
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: root.refresh()
    }

    // Event-driven: react to rfkill state changes instantly instead of polling.
    Process {
        running: true
        command: ["rfkill", "event"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Bluetooth rfkill event:", text.trim())
        }
    }
}
