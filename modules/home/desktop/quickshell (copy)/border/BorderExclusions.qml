pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

// Four invisible PanelWindows that declare Wayland exclusion zones along each
// screen edge so maximised apps stay inside the border/bar area.
Scope {
    id: root

    required property ShellScreen screen
    required property BarState barState
    required property bool hasFullscreen

    ExclusionZone {
        anchors.top:   true
        exclusiveZone: root.hasFullscreen ? 0 : Theme.frameThickness
        implicitWidth: 1
        implicitHeight: Theme.frameThickness
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone:  root.hasFullscreen ? 0 : Theme.frameThickness
        implicitWidth:  1
        implicitHeight: Theme.frameThickness
    }

    ExclusionZone {
        anchors.left:   true
        exclusiveZone:  root.hasFullscreen ? 0 : Theme.frameThickness
        implicitWidth:  Theme.frameThickness
        implicitHeight: 1
    }

    // Right zone — exclusiveZone reserves space; keep implicitWidth minimal
    // so Hyprland layout updates don't also resize this PanelWindow every frame.
    ExclusionZone {
        anchors.right:  true
        exclusiveZone:  root.hasFullscreen ? 0 : root.barState.exclusionBarWidth
        implicitWidth:  1
        implicitHeight: 1
    }

    component ExclusionZone: PanelWindow {
        screen: root.screen
        color:  "transparent"
        mask: Region {}
        WlrLayershell.namespace: "qs-border-exclusion"
    }
}
