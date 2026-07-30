import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Rectangle {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real pipewireVolume:
        sink?.audio?.volume ?? 0
    readonly property real volume:
        pipewireVolume
    readonly property bool muted:
        sink?.audio?.muted ?? false
    property bool tockReady: false
    property bool pendingTock: false
    property real dragTockVolume: -1
    readonly property real tockGain: 0.35

    onSinkChanged: {
        tockReady = false;
        pendingTock = false;

        if (tockProcess.running)
            tockProcess.running = false;
        else
            tockRestartTimer.restart();
    }

    width: 32
    height: 90
    radius: width / 2
    color: Theme.audioIsland
    antialiasing: true

    function adjustVolume(delta) {
        if (sink?.audio == null)
            return;

        const nextVolume = Math.max(
            0,
            Math.min(1, volume + delta)
        );

        if (Math.abs(nextVolume - volume) < 0.001)
            return;

        sink.audio.volume = nextVolume;
        playTock();
    }

    function setVolumeFromPointer(pointerY) {
        if (sink?.audio == null)
            return;

        const trackPoint = track.mapFromItem(
            root,
            root.width / 2,
            pointerY
        );
        const nextVolume = Math.max(
            0,
            Math.min(1, 1 - trackPoint.y / track.height)
        );

        if (Math.abs(nextVolume - volume) < 0.001)
            return;

        sink.audio.volume = nextVolume;

        if (dragTockVolume < 0
                || Math.abs(nextVolume - dragTockVolume) >= 0.05) {
            dragTockVolume = nextVolume;
            playTock();
        }
    }

    function playTock() {
        if (tockProcess.running && tockReady) {
            tockProcess.write("p");
        } else {
            pendingTock = true;
        }
    }

    function toggleMute() {
        if (sink?.audio != null)
            sink.audio.muted = !sink.audio.muted;
    }

    function openVolumeControl() {
        if (!volumeControlProcess.running) {
            volumeControlProcess.command = ["pavucontrol"];
            volumeControlProcess.running = true;
        }
    }

    PwObjectTracker {
        objects: root.sink == null ? [] : [root.sink]
    }

    Component.onCompleted: {
        if (sink != null)
            tockProcess.running = true;
        else
            tockRestartTimer.restart();
    }

    Process {
        id: tockProcess

        // The helper stays alive and receives one-byte playback triggers.
        command: [
            Quickshell.shellPath(
                ".volume-tock-player/bin/volume-tock-player"
            ),
            Quickshell.shellPath(
                ".volume-tock-player/share/"
                    + "quickshell-volume-tock/tink.aiff"
            ),
            root.tockGain.toString(),
            root.sink?.name ?? ""
        ]
        stdinEnabled: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.trim() !== "ready")
                    return;

                root.tockReady = true;
                if (root.pendingTock) {
                    root.pendingTock = false;
                    tockProcess.write("p");
                }
            }
        }

        stderr: StdioCollector {}

        onExited: {
            root.tockReady = false;
            tockRestartTimer.restart();
        }
    }

    Timer {
        id: tockRestartTimer

        interval: 1000
        onTriggered: {
            if (root.sink != null)
                tockProcess.running = true;
            else
                restart();
        }
    }

    Process {
        id: volumeControlProcess
    }

    Rectangle {
        id: track

        anchors.centerIn: parent
        width: 7
        height: 60
        radius: width / 2
        color: Theme.audioTrackInactive
        antialiasing: true

        Rectangle {
            id: volumeFill

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            width: 10
            height: parent.height * root.volume
            radius: width / 2
            color: root.muted
                ? Theme.audioTrackMuted
                : Theme.audioTrackActive
            scale: rightClickHandler.pressed ? 0.92 : 1
            antialiasing: true

            Behavior on height {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 80
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        preventStealing: true

        onPressed: mouse => {
            root.dragTockVolume = -1;
            root.setVolumeFromPointer(mouse.y);
            mouse.accepted = true;
        }

        onPositionChanged: mouse => {
            if (pressed)
                root.setVolumeFromPointer(mouse.y);
        }

        onReleased: {
            root.dragTockVolume = -1;
        }

        onCanceled: {
            root.dragTockVolume = -1;
        }

        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.adjustVolume(0.05);
            else if (event.angleDelta.y < 0)
                root.adjustVolume(-0.05);

            event.accepted = true;
        }
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: root.toggleMute()
    }

    TapHandler {
        id: rightClickHandler

        acceptedButtons: Qt.RightButton
        onTapped: root.openVolumeControl()
    }
}
