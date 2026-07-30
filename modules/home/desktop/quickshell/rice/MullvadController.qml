pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string state: "unknown"
    readonly property bool connected: state === "connected"
    readonly property bool transitioning:
        state === "connecting"
        || state === "disconnecting"
        || state === "reconnecting"
    readonly property bool busy: toggleProcess.running || transitioning

    function updateState(rawLine) {
        const line = rawLine.trim().toLowerCase();

        if (line === "connected"
                || line === "disconnected"
                || line === "connecting"
                || line === "disconnecting"
                || line === "reconnecting") {
            state = line;
        } else if (line.startsWith("error")) {
            state = "error";
        }
    }

    function toggle() {
        if (busy || state === "unknown" || state === "error")
            return;

        toggleProcess.command = [
            "mullvad",
            connected ? "disconnect" : "connect"
        ];
        toggleProcess.running = true;
    }

    Component.onCompleted: statusListener.running = true

    Process {
        id: statusListener

        command: ["mullvad", "status", "listen"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.updateState(data)
        }

        onExited: {
            root.state = "unknown";
            listenerRestartTimer.restart();
        }
    }

    Process {
        id: toggleProcess

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Timer {
        id: listenerRestartTimer

        interval: 2000
        onTriggered: statusListener.running = true
    }
}
