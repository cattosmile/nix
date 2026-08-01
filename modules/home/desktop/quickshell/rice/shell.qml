import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    readonly property int borderThickness: 12
    readonly property int rightBarWidth: 51
    readonly property real innerCornerSmoothness: 32

    Variants {
        model: Quickshell.screens.filter(screen => screen.name === "DP-1")

        Scope {
            id: borderSet

            property var modelData
            BorderFrame {
                id: borderFrame

                screen: borderSet.modelData
                thickness: root.borderThickness
                rightThickness: root.rightBarWidth
                innerCornerSmoothness: root.innerCornerSmoothness
                borderColor: Theme.frame
            }

            // BorderFrame handles dismissal on its own screen. Create the
            // same transparent click-capture surface on every other screen so
            // dismissal never depends on a connector name such as DP-2.
            Variants {
                model: Quickshell.screens.filter(
                    screen => screen !== borderSet.modelData
                )

                Scope {
                    id: launcherDismissalSet

                    property var modelData

                    PanelWindow {
                        screen: launcherDismissalSet.modelData
                        visible: borderFrame.launcherDismissalCaptureActive
                            && launcherDismissalSet.modelData !== null
                        aboveWindows: true
                        exclusionMode: ExclusionMode.Ignore
                        WlrLayershell.layer: WlrLayer.Overlay
                        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                        mask: null
                        color: Theme.transparent

                        anchors {
                            top: true
                            bottom: true
                            left: true
                            right: true
                        }

                        Item {
                            anchors.fill: parent
                            focus: true

                            Component.onCompleted: forceActiveFocus()

                            Keys.onPressed: event => {
                                event.accepted = borderFrame.handleLauncherKey(
                                    event.key,
                                    event.text || "",
                                    event.modifiers
                                )
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    borderFrame.dismissLauncherFromPointer()
                                }
                            }
                        }
                    }
                }
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.borderThickness
                edgeTop: true
                edgeBottom: false
                edgeLeft: true
                edgeRight: true
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.borderThickness
                edgeTop: false
                edgeBottom: true
                edgeLeft: true
                edgeRight: true
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.borderThickness
                edgeTop: true
                edgeBottom: true
                edgeLeft: true
                edgeRight: false
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.rightBarWidth
                edgeTop: true
                edgeBottom: true
                edgeLeft: false
                edgeRight: true
            }
        }
    }
}
