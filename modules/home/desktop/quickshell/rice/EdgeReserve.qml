import Quickshell
import QtQuick

PanelWindow {
    id: root

    required property bool edgeTop
    required property bool edgeBottom
    required property bool edgeLeft
    required property bool edgeRight
    required property int thickness

    readonly property bool vertical: edgeTop && edgeBottom

    anchors {
        top: root.edgeTop
        bottom: root.edgeBottom
        left: root.edgeLeft
        right: root.edgeRight
    }

    implicitWidth: root.vertical ? root.thickness : 1
    implicitHeight: root.vertical ? 1 : root.thickness

    exclusiveZone: root.thickness
    focusable: false
    aboveWindows: true
    color: Theme.transparent
    mask: Region {}
}
