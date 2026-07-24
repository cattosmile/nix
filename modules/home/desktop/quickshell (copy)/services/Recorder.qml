pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool recording: false

    // Combines process detection + Pipewire node inspection every 3 seconds.
    // This matches the proven shell logic the user had before:
    //   pgrecorder processes  ||  pw-cli nodes matching screen/desktop/screencast
    Timer {
        interval: 7500
        running: true
        repeat: true
        onTriggered: if (!checkProc.running) checkProc.running = true
    }

    Component.onCompleted: checkProc.running = true

    Process {
        id: checkProc
        command: ["sh", "-c",
            "pgrep -x 'obs' >/dev/null || " +
            "pgrep -x 'obs-studio' >/dev/null || " +
            "pgrep -f '[g]pu-screen-recorder' >/dev/null || " +
            "pgrep -x 'wl-screen-rec' >/dev/null || " +
            "pgrep -x 'wf-recorder' >/dev/null || " +
            "pgrep -x 'ffmpeg' >/dev/null || " +
            "pgrep -x 'kooha' >/dev/null || " +
            "pw-cli ls Node 2>/dev/null | grep -qiE 'screen|desktop|screencast'"
        ]
        onExited: code => {
            root.recording = (code === 0);
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Recorder check:", text.trim())
        }
    }
}
