pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../services"

Rectangle {
    id: root
    width:  Theme.islandWidth
    height: 90
    radius: width / 2
    color:  Theme.islandBg
    anchors.horizontalCenter: parent.horizontalCenter

    readonly property int audioVolume: Math.round(Audio.volume * 100)
    readonly property bool audioMuted: Audio.muted

    Rectangle {
        id: staticBarBg
        width: 7
        height: 60
        radius: width / 2
        color: Theme.islandInactive
        anchors.centerIn: parent
    }

    Rectangle {
        width: 10
        height: staticBarBg.height * root.audioVolume / 100
        radius: width / 2
        color: root.audioMuted ? Theme.islandMuted : Theme.islandActive
        anchors.bottom: staticBarBg.bottom
        anchors.horizontalCenter: staticBarBg.horizontalCenter

        Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        Behavior on color {
            ColorAnimation { duration: 180 }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: false
        onWheel: (wheel) => {
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            Audio.incrementVolume(delta)
        }
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: Audio.toggleMute()
    }
}
