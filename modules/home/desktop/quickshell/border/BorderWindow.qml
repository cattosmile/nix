pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"

// Full-screen overlay that draws the border frame as one clamped rounded cut-out.
PanelWindow {
    id: root

    required property BarState barState
    required property bool hasFullscreen

    visible: !hasFullscreen
    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "qs-border"

    mask: Region {}

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    FilletFrame {
        anchors.fill: parent
        thickness: Theme.frameThickness
        rightReserved: root.barState.activeBarWidth
        innerRadius: Theme.innerRadius
        color: Theme.frameColor
    }
}
