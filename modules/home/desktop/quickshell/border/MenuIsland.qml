pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root
    implicitWidth: 400
    implicitHeight: 180
    radius: 20
    color: Theme.islandBg

    Loader {
        anchors.fill: parent
        sourceComponent: textComponent
    }

    Component {
        id: textComponent
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "Menu Item " + (root.itemIndex + 1)
            color: Theme.text
            font.pixelSize: 18
        }
    }

    required property int itemIndex
}
