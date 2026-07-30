import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: root

    readonly property real contentPadding: 4
    readonly property real slotHeight: 28
    readonly property var actions: [
        {
            name: "Network",
            glyph: "\uf6ff",
            fontFamily: "Font Awesome 7 Free",
            fontStyle: "Solid",
            inactiveSize: 12.5,
            activeSize: 16,
            inactiveOffsetX: -0.5,
            activeOffsetX: 1,
            networkIndicator: true
        },
        {
            name: "Bluetooth",
            glyph: "\uf294",
            fontFamily: "Font Awesome 7 Brands",
            fontStyle: "Regular",
            inactiveSize: 14,
            activeSize: 18.5,
            inactiveOffsetX: -0.5,
            activeOffsetX: -0.5,
            embolden: true,
            bluetoothIndicator: true
        },
        {
            name: "Lock",
            glyph: "\uf023",
            fontFamily: "Font Awesome 7 Free",
            fontStyle: "Solid",
            inactiveSize: 12.5,
            activeSize: 17,
            inactiveOffsetX: 0,
            activeOffsetX: -0.5,
            mullvadIndicator: true
        },
        {
            name: "Dot",
            glyph: "\uf111",
            fontFamily: "Font Awesome 7 Free",
            fontStyle: "Solid",
            inactiveSize: 12.5,
            activeSize: 17,
            inactiveOffsetX: 0.5,
            activeOffsetX: 0.75,
            screenShareIndicator: true
        }
    ]

    width: 32
    height: contentPadding * 2 + actions.length * slotHeight
    radius: width / 2
    color: Theme.quickActionsIsland
    antialiasing: true

    function openActionTerminal(action, terminalProcess) {
        if (terminalProcess.running)
            return;

        const terminal = [
            "alacritty",
            "--title",
            "alacritty_float"
        ];
        let command = [];

        if (action.networkIndicator === true) {
            command = terminal.concat(["-e", "nmtui"]);
        } else if (action.bluetoothIndicator === true) {
            command = terminal.concat(["-e", "bluetoothctl"]);
        } else if (action.mullvadIndicator === true) {
            command = terminal.concat([
                "-e",
                "bash",
                "-lc",
                "cd -- \"$HOME\"; mullvad status; "
                    + "exec \"${SHELL:-/bin/sh}\" -l"
            ]);
        }

        if (command.length === 0)
            return;

        terminalProcess.command = command;
        terminalProcess.running = true;
    }

    Column {
        anchors {
            top: parent.top
            topMargin: root.contentPadding
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: root.actions

            Item {
                id: actionSlot

                required property var modelData
                readonly property bool active:
                    modelData.networkIndicator === true
                        ? NetworkController.connected
                        : modelData.bluetoothIndicator === true
                            ? BluetoothController.enabled
                            : modelData.screenShareIndicator === true
                                ? ScreenShareController.active
                                : modelData.mullvadIndicator === true
                                    ? MullvadController.connected
                                    : false

                width: root.width
                height: root.slotHeight

                Process {
                    id: actionTerminalProcess

                    stdout: StdioCollector {}
                    stderr: StdioCollector {}
                }

                Text {
                    id: actionIcon

                    property real heartbeatScale: 1
                    property real heartbeatOpacity: 1

                    anchors {
                        centerIn: parent
                        horizontalCenterOffset: actionSlot.active
                            ? actionSlot.modelData.activeOffsetX
                            : actionSlot.modelData.inactiveOffsetX
                    }
                    text: actionSlot.modelData.glyph
                    scale: heartbeatScale
                    opacity: heartbeatOpacity
                    transformOrigin: Item.Center
                    color: actionSlot.active
                        ? Theme.quickActionActive
                        : Theme.quickActionInactive
                    font {
                        family: actionSlot.modelData.fontFamily
                        styleName: actionSlot.modelData.fontStyle
                        bold: actionSlot.modelData.embolden === true
                        pixelSize: actionSlot.active
                            ? actionSlot.modelData.activeSize
                            : actionSlot.modelData.inactiveSize
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on font.pixelSize {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on anchors.horizontalCenterOffset {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    SequentialAnimation {
                        running:
                            actionSlot.modelData.screenShareIndicator === true
                            && actionSlot.active
                        loops: Animation.Infinite
                        onStopped: {
                            actionIcon.heartbeatScale = 1;
                            actionIcon.heartbeatOpacity = 1;
                        }

                        PauseAnimation {
                            duration: 900
                        }

                        NumberAnimation {
                            target: actionIcon
                            property: "heartbeatScale"
                            to: 1.055
                            duration: 90
                            easing.type: Easing.OutCubic
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: actionIcon
                                property: "heartbeatScale"
                                to: 1
                                duration: 120
                                easing.type: Easing.InOutCubic
                            }

                            NumberAnimation {
                                target: actionIcon
                                property: "heartbeatOpacity"
                                to: 0.94
                                duration: 120
                                easing.type: Easing.InOutCubic
                            }
                        }

                        PauseAnimation {
                            duration: 60
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: actionIcon
                                property: "heartbeatScale"
                                to: 1.035
                                duration: 80
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: actionIcon
                                property: "heartbeatOpacity"
                                to: 1
                                duration: 80
                                easing.type: Easing.OutCubic
                            }
                        }

                        NumberAnimation {
                            target: actionIcon
                            property: "heartbeatScale"
                            to: 1
                            duration: 150
                            easing.type: Easing.InOutCubic
                        }

                        PauseAnimation {
                            duration: 900
                        }
                    }
                }

                HoverHandler {
                    enabled:
                        actionSlot.modelData.screenShareIndicator !== true
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    enabled:
                        actionSlot.modelData.bluetoothIndicator === true
                        || actionSlot.modelData.mullvadIndicator === true
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        if (actionSlot.modelData.bluetoothIndicator === true)
                            BluetoothController.toggle();
                        else
                            MullvadController.toggle();
                    }
                }

                TapHandler {
                    enabled:
                        actionSlot.modelData.screenShareIndicator !== true
                    acceptedButtons: Qt.RightButton
                    onTapped:
                        root.openActionTerminal(
                            actionSlot.modelData,
                            actionTerminalProcess
                        )
                }
            }
        }
    }
}
