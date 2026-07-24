pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property bool checking: false

    property bool expectingConnect: false
    property bool expectingDisconnect: false

    function toggle(): void {
        // Block only while the actual connect/disconnect command is still running.
        // Don't use root.checking here — it is inferred from mullvad status output
        // and can lag or get stuck, causing clicks to be silently swallowed.
        if (connectProc.running || disconnectProc.running)
            return;
        if (root.connected)
            disconnectProc.running = true;
        else
            connectProc.running = true;
    }

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: statusProc
        command: ["mullvad", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().toLowerCase();
                if (line.length === 0) {
                    root.connected = false;
                    root.checking = false;
                    return;
                }
                root.connected = line.startsWith("connected");
                root.checking = line.includes("connecting") || line.includes("disconnecting");

                // Stop rapid polling once the expected stable state is reached.
                if (rapidPollTimer.running) {
                    if (root.expectingConnect && root.connected) {
                        rapidPollTimer.stop();
                        root.expectingConnect = false;
                    } else if (root.expectingDisconnect && !root.connected) {
                        rapidPollTimer.stop();
                        root.expectingDisconnect = false;
                    }
                }
            }
        }
    }

    Process {
        id: connectProc
        command: ["mullvad", "connect"]
        onExited: {
            root.expectingConnect = true;
            root.expectingDisconnect = false;
            root.refresh();
            rapidPollTimer.restart();
        }
    }

    Process {
        id: disconnectProc
        command: ["mullvad", "disconnect"]
        onExited: {
            root.expectingConnect = false;
            root.expectingDisconnect = true;
            root.refresh();
            rapidPollTimer.restart();
        }
    }

    // Rapid-poll after toggling so the UI updates within ~1s of the state change
    // instead of waiting up to 10s for the background timer.
    Timer {
        id: rapidPollTimer
        interval: 300
        running: false
        repeat: true
        property int pollCount: 0
        onTriggered: {
            // Only count polls that actually started. If statusProc is still
            // in-flight we skip this tick rather than burning the budget.
            if (!statusProc.running) {
                statusProc.running = true;
                pollCount++;
            }
            // Safety cap: ~15s worth of successful polls.
            if (pollCount >= 50) {
                stop();
                pollCount = 0;
                root.expectingConnect = false;
                root.expectingDisconnect = false;
            }
        }
        onRunningChanged: if (!running) pollCount = 0
    }

    // Safety net: if checking gets stuck true (status parse lag, daemon hang,
    // etc.) force it false so toggle() never stays locked out indefinitely.
    Timer {
        interval: 30000
        running: root.checking
        repeat: false
        onTriggered: root.checking = false
    }

    // Event-driven: stream status changes instead of polling every 10s.
    Process {
        running: true
        command: ["mullvad", "status", "listen"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Mullvad status listen:", text.trim())
        }
    }
}
