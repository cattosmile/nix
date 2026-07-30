import QtQuick

Item {
    id: root

    width: 32
    height: 32

    Text {
        anchors {
            centerIn: parent
            horizontalCenterOffset: 1
        }
        text: "\uf011"
        color: Theme.powerIcon
        font {
            family: "Font Awesome 7 Free"
            styleName: "Solid"
            pixelSize: 20
        }
    }
}
