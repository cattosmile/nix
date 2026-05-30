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
        command: ["rfkill", "list", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split('\n');
                let hasAdapter = false;
                let softBlocked = false;
                for (const line of lines) {
                    if (line.includes('Wireless LAN') || line.includes('Wi-Fi')) {
                        hasAdapter = true;
                    }
                    if (line.includes('Soft blocked: yes')) {
                        softBlocked = true;
                    }
                }
                root.enabled = hasAdapter && !softBlocked;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Wifi status:", text.trim())
        }
    }

    Process {
        id: blockProc
        command: ["rfkill", "block", "wifi"]
        onExited: root.refresh()
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Wifi block:", text.trim())
        }
    }

    Process {
        id: unblockProc
        command: ["rfkill", "unblock", "wifi"]
        onExited: root.refresh()
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Wifi unblock:", text.trim())
        }
    }

    // Event-driven: react to rfkill state changes instantly (same mechanism as
    // Bluetooth). `rfkill event` streams every block/unblock — including those
    // triggered by NetworkManager (`nmcli radio wifi off` soft-blocks via rfkill).
    Process {
        running: true
        command: ["rfkill", "event"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Wifi rfkill event:", text.trim())
        }
    }

    // Slow fallback in case an event is ever missed.
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
