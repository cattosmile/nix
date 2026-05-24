pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../services"

// Status widget island: Wifi · Bluetooth · VPN · Recording.
// Uses Font Awesome 7 (Free Solid + Brands).
Item {
    id: root

    readonly property int count:       4
    readonly property int slotSpacing: 28
    readonly property int islandPadH:  10
    readonly property int islandPadV:  9

    readonly property bool recordOn: Recorder.recording

    readonly property var icons:     ["", "", "", ""]
    readonly property var iconFonts: ["Font Awesome 7 Free Solid", "Font Awesome 7 Brands", "Font Awesome 7 Free Solid", "Font Awesome 7 Free Solid"]

    readonly property var iconSizes:  [16,   18,   16,   16]
    readonly property var iconScales: [0.82, 0.90, 0.82, 0.82]

    implicitWidth:  Theme.islandWidth
    implicitHeight: (count - 1) * slotSpacing + Math.max(...iconSizes) + islandPadV * 2

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.islandBg
    }

    // Right-click WiFi → floating Alacritty with nmtui.
    Component {
        id: nmtuiTerm
        Process {
            command: ["hyprctl", "dispatch", "exec", "alacritty --title float_alacritty -e bash -c 'nmtui; exec bash'"]
            running: true
            onRunningChanged: if (!running) destroy()
        }
    }

    // Right-click VPN → floating Alacritty that runs mullvad status, then drops to a shell.
    Component {
        id: mullvadStatusTerm
        Process {
            command: ["hyprctl", "dispatch", "exec", "alacritty --title float_alacritty -e bash -c 'mullvad status; exec bash'"]
            running: true
            onRunningChanged: if (!running) destroy()
        }
    }

    // Right-click Bluetooth → floating Alacritty with bluetoothctl.
    Component {
        id: bluetoothctlTerm
        Process {
            command: ["hyprctl", "dispatch", "exec", "alacritty --title float_alacritty -e bash -c 'bluetoothctl; exec bash'"]
            running: true
            onRunningChanged: if (!running) destroy()
        }
    }

    Repeater {
        model: root.count

        delegate: Item {
            id: slot
            required property int index

            readonly property bool active:
                index === 0 ? Wifi.enabled     :
                index === 1 ? Bluetooth.enabled :
                index === 2 ? Vpn.connected    : root.recordOn

            width:  root.implicitWidth
            height: root.slotSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.islandPadV + index * root.slotSpacing
               + (root.iconSizes[index] - root.slotSpacing) / 2

            Text {
                anchors.centerIn: parent
                width:           root.iconSizes[slot.index]
                height:          root.iconSizes[slot.index]
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment:   Text.AlignVCenter
                text:            root.icons[slot.index]
                font.pixelSize:  root.iconSizes[slot.index]
                font.family:     root.iconFonts[slot.index]
                color: slot.active ? Theme.islandActive : Theme.islandDisabled
                scale:           slot.active ? 1.0 : root.iconScales[slot.index]

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                Behavior on scale {
                    SpringAnimation {
                        spring:  3.5
                        damping: 0.28
                        epsilon: 0.01
                    }
                }
            }

            HoverHandler {
                enabled: slot.index !== 3
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                enabled: slot.index !== 3
                onTapped: {
                    if (slot.index === 0)      Wifi.toggle()
                    else if (slot.index === 1) Bluetooth.toggle()
                    else if (slot.index === 2) Vpn.toggle()
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: slot.index === 0 || slot.index === 1 || slot.index === 2
                onTapped: {
                    if (slot.index === 0)      nmtuiTerm.createObject(root)
                    else if (slot.index === 1) bluetoothctlTerm.createObject(root)
                    else if (slot.index === 2) mullvadStatusTerm.createObject(root)
                }
            }
        }
    }
}
