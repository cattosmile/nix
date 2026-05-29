pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: root

    color: "transparent"

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "qs-notifs"

    anchors.left: true
    anchors.top:  true

    margins.left: Theme.frameThickness
    margins.top:  Theme.frameThickness

    implicitWidth:  Theme.barWidth * 6
    implicitHeight: background.height

    Rectangle {
        id: background

        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        height:         notifList.contentHeight

        radius: Theme.innerRadius
        color:  Theme.bar
        clip:   true

        Behavior on height {
            NumberAnimation {
                duration:           700
                easing.type:        Easing.BezierSpline
                easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
            }
        }

        ListView {
            id: notifList

            anchors.fill:      parent
            anchors.topMargin: Theme.frameThickness

            spacing:     0
            interactive: false
            model:       Notifs.popups

            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutQuad }
            }

            delegate: NotifCard {}
        }
    }
}
