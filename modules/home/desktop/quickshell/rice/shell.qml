import Quickshell
import QtQuick

ShellRoot {
    id: root

    readonly property int borderThickness: 12
    readonly property int rightBarWidth: 51
    readonly property real innerCornerSmoothness: 32

    Variants {
        model: Quickshell.screens.filter(screen => screen.name === "DP-1")

        Scope {
            id: borderSet

            property var modelData

            BorderFrame {
                screen: borderSet.modelData
                thickness: root.borderThickness
                rightThickness: root.rightBarWidth
                innerCornerSmoothness: root.innerCornerSmoothness
                borderColor: Theme.frame
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.borderThickness
                edgeTop: true
                edgeBottom: false
                edgeLeft: true
                edgeRight: true
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.borderThickness
                edgeTop: false
                edgeBottom: true
                edgeLeft: true
                edgeRight: true
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.borderThickness
                edgeTop: true
                edgeBottom: true
                edgeLeft: true
                edgeRight: false
            }

            EdgeReserve {
                screen: borderSet.modelData
                thickness: root.rightBarWidth
                edgeTop: true
                edgeBottom: true
                edgeLeft: false
                edgeRight: true
            }
        }
    }
}
