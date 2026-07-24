pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property BarState barState
    required property bool hasFullscreen

    visible: !hasFullscreen
    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "qs-bar"

    anchors.right:  true
    anchors.top:    true
    anchors.bottom: true

    mask: Region {
        x: root.width - root.visualWidth
        y: 0
        width:  root.visualWidth
        height: root.height
    }

    property bool expanded:    false
    property real visualWidth: Theme.barWidth
    property bool isToggling:  false

    implicitWidth: Theme.expandedWidth

    onHasFullscreenChanged: {
        if (hasFullscreen) {
            if (expanded)
                expanded = false;
            expandAnim.stop();
            collapseAnim.stop();
            visualWidth = Theme.barWidth;
            barState.exclusionBarWidth = 0;
            barState.activeBarWidth = Theme.barWidth;
        } else {
            barState.exclusionBarWidth = expanded ? Theme.expandedWidth : Theme.barWidth;
        }
    }

    onVisualWidthChanged: {
        // Frame hole tracks the visible bar; exclusion is committed once per toggle.
        barState.activeBarWidth = Math.max(Theme.barWidth, visualWidth)
    }

    onExpandedChanged: {
        if (expanded) {
            collapseAnim.stop()
            // One layout transition — Hyprland windowsMove runs in parallel with the bar.
            barState.exclusionBarWidth = Theme.expandedWidth
            expandAnim.start()
        } else {
            expandAnim.stop()
            barState.exclusionBarWidth = Theme.barWidth
            collapseAnim.start()
        }
    }

    Timer {
        id: toggleCooldownTimer
        interval: 300
        onTriggered: root.isToggling = false
    }

    NumberAnimation {
        id: expandAnim
        target:   root
        property: "visualWidth"
        to:       Theme.expandedWidth
        duration: 700
        easing.type:        Easing.BezierSpline
        easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
    }

    NumberAnimation {
        id: collapseAnim
        target:   root
        property: "visualWidth"
        to:       Theme.barWidth
        duration: 700
        easing.type:        Easing.BezierSpline
        easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
    }

    Rectangle {
        id: barBackground
        width:          root.visualWidth
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        color: Theme.bar

        Item {
            id: leftEdgeContainer
            x:     0
            width: Theme.barWidth
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            StatusIsland {
                id: statusIsland
                anchors.top:              parent.top
                anchors.topMargin:        Theme.frameThickness
                anchors.horizontalCenter: parent.horizontalCenter
            }

            AudioIsland {
                id: audioIsland
                anchors.top:              statusIsland.bottom
                anchors.topMargin:        12
                anchors.horizontalCenter: parent.horizontalCenter
            }

            WorkspaceSwitcher {
                id: workspaceSwitcher
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter:   parent.verticalCenter
            }

            TrayIsland {
                id: trayIsland
                anchors.bottom:           parent.bottom
                anchors.bottomMargin:     Theme.frameThickness
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Deadzones: suppress bar expand when hovering near islands (+30 px margin).
            Item { id: dzStatus;    x: 0; width: parent.width; y: Math.max(0, statusIsland.y - 30);           height: statusIsland.height + 60 }
            Item { id: dzAudio;     x: 0; width: parent.width; y: audioIsland.y - 30;                          height: audioIsland.height + 60 }
            Item { id: dzWorkspace; x: 0; width: parent.width; y: workspaceSwitcher.y - 30;                     height: workspaceSwitcher.height + 60 }
            Item { id: dzTray;      x: 0; width: parent.width; y: trayIsland.y - 30;                            height: trayIsland.height + 60 }
        }
    }

    // 1 px trigger at the absolute monitor edge.
    Item {
        x: root.width - 1
        width: 1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        HoverHandler {
            onHoveredChanged: {
                if (hovered && !root.isToggling) {
                    const y = point.position.y
                    if (!root.expanded) {
                        if (y >= dzStatus.y && y <= dzStatus.y + dzStatus.height) return
                        if (y >= dzAudio.y && y <= dzAudio.y + dzAudio.height) return
                        if (y >= dzWorkspace.y && y <= dzWorkspace.y + dzWorkspace.height) return
                        if (y >= dzTray.y && y <= dzTray.y + dzTray.height) return
                    }

                    root.isToggling = true
                    root.expanded   = !root.expanded
                    toggleCooldownTimer.start()
                }
            }
        }
    }

    Item {
        id: clipContainer
        z: 1
        width: Theme.expandedWidth - Theme.barWidth - 10
        x:     root.expanded ? Theme.barWidth : Theme.expandedWidth
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        clip: true

        Behavior on x {
            NumberAnimation {
                duration:           700
                easing.type:        Easing.BezierSpline
                easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
            }
        }

        ListView {
            id: menuList
            anchors.fill: parent
            anchors.topMargin:    Theme.frameThickness
            anchors.bottomMargin: Theme.frameThickness
            clip:        false
            spacing:     12
            interactive: root.expanded
            snapMode:    ListView.SnapToItem

            // Fake "infinite" wrap-around scroll: the real menu has `itemCount`
            // entries, repeated `repeats` times so you can scroll past either end.
            readonly property int itemCount:  9
            readonly property int repeats:    1200
            readonly property int scrollStep: 6
            model: itemCount * repeats

            delegate: MenuIsland {
                required property int index
                itemIndex: index % menuList.itemCount
                width:     menuList.width
            }

            // Start in the middle of the model (showing item 1) so there's room
            // to wrap in both directions.
            Component.onCompleted: Qt.callLater(() =>
                positionViewAtIndex(menuList.itemCount * menuList.repeats / 2, ListView.Beginning))
        }

        // Sits above ListView to intercept wheel before Flickable's C++ handler.
        // Plain Item — no pointer handlers — so drag/flick falls through to ListView.
        Item {
            anchors.fill: parent

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                onWheel: (event) => {
                    const slotH = menuList.contentHeight / menuList.count
                    const curIdx = Math.round(menuList.contentY / slotH)
                    const steps = event.angleDelta.y < 0 ? menuList.scrollStep : -menuList.scrollStep
                    menuList.positionViewAtIndex(
                        Math.max(0, Math.min(menuList.count - 1, curIdx + steps)),
                        ListView.Beginning
                    )
                }
            }
        }
    }
}
