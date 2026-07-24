pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    readonly property int iconSize:   16
    readonly property int slotSize:   28
    readonly property int islandPadV: 7

    implicitWidth:  Theme.islandWidth
    implicitHeight: SystemTray.items.values.length <= 1
                      ? implicitWidth
                      : trayColumn.implicitHeight + islandPadV * 2

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.34, 1.3, 0.64, 1.0, 1.0, 1.0]
        }
    }

    readonly property bool hasItems: SystemTray.items.values.length > 0

    visible: hasItems || keepVisibleTimer.running

    Timer {
        id: keepVisibleTimer
        interval: 350
    }

    transform: Translate {
        id: slideTransform
        x: 500
    }

    onHasItemsChanged: {
        slideInAnim.stop()
        slideOutAnim.stop()
        if (hasItems) {
            keepVisibleTimer.stop()
            slideInAnim.from = slideTransform.x
            slideInAnim.to = 0
            slideInAnim.start()
        } else {
            slideOutAnim.from = slideTransform.x
            slideOutAnim.to = 500
            slideOutAnim.start()
            keepVisibleTimer.start()
        }
    }

    Component.onCompleted: {
        if (hasItems) {
            slideTransform.x = 0
        }
    }

    NumberAnimation {
        id: slideInAnim
        target: slideTransform
        property: "x"
        duration: 400
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.34, 1.3, 0.64, 1.0, 1.0, 1.0]
    }

    NumberAnimation {
        id: slideOutAnim
        target: slideTransform
        property: "x"
        duration: 300
        easing.type: Easing.InQuad
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.islandBg
    }

    Column {
        id: trayColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: ScriptModel { values: SystemTray.items.values }

            delegate: Item {
                id: slot
                required property SystemTrayItem modelData

                width:  Theme.islandWidth
                height: root.slotSize

                Image {
                    anchors.centerIn: parent
                    width:  root.iconSize
                    height: root.iconSize
                    source: {
                        const icon = String(slot.modelData.icon)
                        if (!icon.includes("?path="))
                            return icon
                        const sep = icon.indexOf("?path=")
                        const name = icon.slice(0, sep)
                        const path = icon.slice(sep + 6)
                        return Qt.resolvedUrl(path + "/" + name.slice(name.lastIndexOf("/") + 1))
                    }
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: slot.modelData.activate()
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: slot.modelData.secondaryActivate()
                }
            }
        }
    }
}
