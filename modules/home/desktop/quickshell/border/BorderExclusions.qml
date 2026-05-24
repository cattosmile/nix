pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

// Four invisible PanelWindows that declare Wayland exclusion zones along each
// screen edge so maximised apps stay inside the border/bar area.
Scope {
    id: root

    required property ShellScreen screen

    ExclusionZone {
        anchors.top:   true
        exclusiveZone: Theme.frameThickness
        implicitWidth: 1
        implicitHeight: Theme.frameThickness
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone:  Theme.frameThickness
        implicitWidth:  1
        implicitHeight: Theme.frameThickness
    }

    ExclusionZone {
        anchors.left:   true
        exclusiveZone:  Theme.frameThickness
        implicitWidth:  Theme.frameThickness
        implicitHeight: 1
    }

    // Right zone is wider — reserves space for the bar column.
    ExclusionZone {
        anchors.right:  true
        exclusiveZone:  Theme.exclusionBarWidth
        implicitWidth:  Theme.exclusionBarWidth
        implicitHeight: 1
    }

    component ExclusionZone: PanelWindow {
        screen: root.screen
        color:  "transparent"
        mask: Region {}
        WlrLayershell.namespace: "qs-border-exclusion"
    }
}
