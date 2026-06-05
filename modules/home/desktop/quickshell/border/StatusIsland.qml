pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
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
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.islandBg
    }

    function openWifiTerminal() {
        Quickshell.execDetached(["hyprctl", "dispatch", "exec",
            "[float;center;size 1000 600] alacritty --title float_alacritty -e bash -lc 'nmtui; exec bash'"])
    }

    function openMullvadTerminal() {
        Quickshell.execDetached(["hyprctl", "dispatch", "exec",
            "[float;center;size 1000 600] alacritty --title float_alacritty -e bash -lc 'mullvad status; exec bash'"])
    }

    function openBluetoothTerminal() {
        Quickshell.execDetached(["hyprctl", "dispatch", "exec",
            "[float;center;size 1000 600] alacritty --title float_alacritty -e bash -lc 'bluetoothctl; exec bash'"])
    }

    function slotIndexAt(y) {
        for (let i = 0; i < 3; i++) {
            const slotY = root.islandPadV + i * root.slotSpacing
                + (root.iconSizes[i] - root.slotSpacing) / 2

            if (y >= slotY && y <= slotY + root.slotSpacing)
                return i
        }

        return -1
    }

    function toggleSlot(index) {
        if (index === 0)      Wifi.toggle()
        else if (index === 1) Bluetooth.toggle()
        else if (index === 2) Vpn.toggle()
    }

    function openSlotTerminal(index) {
        if (index === 0)      root.openWifiTerminal()
        else if (index === 1) root.openBluetoothTerminal()
        else if (index === 2) root.openMullvadTerminal()
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
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: root.slotIndexAt(mouseY) >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        z: 100

        onPressed: (mouse) => {
            const index = root.slotIndexAt(mouse.y)
            if (index < 0) {
                mouse.accepted = false
                return
            }

            mouse.accepted = true

            if (mouse.button === Qt.RightButton)
                root.openSlotTerminal(index)
        }

        onClicked: (mouse) => {
            const index = root.slotIndexAt(mouse.y)
            if (index < 0) {
                mouse.accepted = false
                return
            }

            mouse.accepted = true

            if (mouse.button === Qt.LeftButton)
                root.toggleSlot(index)
        }
    }
}
