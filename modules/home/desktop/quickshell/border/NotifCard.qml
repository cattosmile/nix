pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../services"

Item {
    id: root

    required property int    index
    required property string summary
    required property string body
    required property int    expireTimeout

    width:  ListView.view?.width ?? 324
    height: open ? content.implicitHeight + Theme.frameThickness * 2 : 0

    property bool open: false

    Component.onCompleted: open = true

    Behavior on height {
        NumberAnimation {
            duration:           700
            easing.type:        Easing.BezierSpline
            easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
        }
    }

    Column {
        id: content

        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.margins: Theme.frameThickness

        spacing: 4

        Text {
            text: root.summary || "Notification"
            color: Theme.text
            font.pixelSize: 14
            font.bold: true
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            visible: root.body.length > 0
            text: root.body
            color: Theme.subtext
            font.pixelSize: 12
            width: parent.width
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 3
        }
    }

    Timer {
        interval: root.expireTimeout
        running: true
        onTriggered: {
            open = false
            closeTimer.start()
        }
    }

    Timer {
        id: closeTimer
        interval: 700
        onTriggered: Notifs.dismiss(root.index)
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            open = false
            closeTimer.start()
        }
    }
}
