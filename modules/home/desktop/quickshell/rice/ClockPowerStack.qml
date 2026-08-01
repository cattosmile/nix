import Quickshell
import QtQuick

Item {
    id: root

    width: 32
    height: 115.6667

    readonly property var timeLines: [
        Qt.formatDateTime(clock.date, "HH"),
        Qt.formatDateTime(clock.date, "mm")
    ]
    readonly property var dateLines: [
        Qt.formatDateTime(clock.date, "dd"),
        Qt.formatDateTime(clock.date, "MM")
    ]

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Rectangle {
        id: clockIsland

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: 32
        height: 115.6667
        radius: width / 2
        color: Theme.clockIsland
        antialiasing: true

        Item {
            anchors {
                bottom: clockDivider.top
                bottomMargin: 5.5
            }
            width: parent.width
            height: 40

            Column {
                anchors.fill: parent
                spacing: 8

                Repeater {
                    model: root.timeLines
                    delegate: clockLineDelegate
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 2

                    Rectangle {
                        required property int index

                        width: 2
                        height: 2
                        radius: 1
                        color: Theme.clockTime
                        antialiasing: true
                    }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 1
                        to: 0.35
                        duration: 200
                        easing.type: Easing.InOutSine
                    }

                    PauseAnimation {
                        duration: 300
                    }

                    NumberAnimation {
                        from: 0.35
                        to: 1
                        duration: 200
                        easing.type: Easing.InOutSine
                    }

                    PauseAnimation {
                        duration: 300
                    }
                }
            }
        }

        Rectangle {
            id: clockDivider

            anchors {
                bottom: parent.bottom
                bottomMargin: 54
                horizontalCenter: parent.horizontalCenter
            }
            width: 12
            height: 1
            color: Theme.clockDivider
            antialiasing: false
        }

        Column {
            anchors {
                top: clockDivider.bottom
                topMargin: 6.3333
            }
            width: parent.width
            spacing: 1

            Repeater {
                model: root.dateLines
                delegate: dateLineDelegate
            }
        }
    }

    Component {
        id: clockLineDelegate

        Text {
            required property int index
            required property string modelData

            width: clockIsland.width
            height: 16
            text: modelData
            color: Theme.clockTime
            font {
                family: "Iosevka Fixed"
                pixelSize: 14
                weight: Font.DemiBold
                letterSpacing: 0
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            transform: Translate {
                y: 0.5
            }
        }
    }

    Component {
        id: dateLineDelegate

        Item {
            required property string modelData

            width: clockIsland.width
            height: 16

            Text {
                id: dateNumber

                anchors {
                    centerIn: parent
                    horizontalCenterOffset: -0.5
                }
                text: modelData
                color: Theme.clockTime
                font {
                    family: "Iosevka Fixed"
                    pixelSize: 14
                    weight: Font.DemiBold
                    letterSpacing: 0
                }
            }

            Text {
                anchors {
                    baseline: dateNumber.baseline
                    left: dateNumber.right
                    leftMargin: -2
                }
                text: "."
                color: Theme.clockTime
                font {
                    family: "Iosevka Fixed"
                    pixelSize: 10
                    weight: Font.DemiBold
                    letterSpacing: 0
                }
            }
        }
    }

}
