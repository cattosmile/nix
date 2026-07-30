pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool busy: false
    property string outcome: "idle"
    property string processOutput: ""

    function saveReplay() {
        if (busy)
            return;

        outcomeTimer.stop();
        outcome = "idle";
        processOutput = "";
        busy = true;
        saveProcess.running = true;
    }

    Process {
        id: saveProcess

        command: [
            "node",
            Quickshell.shellPath("scripts/obs-save-replay.mjs")
        ]

        stdout: StdioCollector {
            onStreamFinished: root.processOutput = text.trim()
        }

        stderr: StdioCollector {
            onStreamFinished: root.processOutput = text.trim()
        }

        onExited: exitCode => {
            root.busy = false;
            root.outcome = exitCode === 0 ? "success" : "error";
            outcomeTimer.restart();
        }
    }

    Timer {
        id: outcomeTimer

        interval: 2200
        onTriggered: {
            root.outcome = "idle";
            root.processOutput = "";
        }
    }
}
