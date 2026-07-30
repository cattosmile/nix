import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Rectangle {
    id: root

    property int hoveredSlotCount: 0
    property bool extendedHoverGuard: false

    readonly property int itemCount: SystemTray.items.values.length
    readonly property bool menuSurfaceVisible: trayMenu.visible
    readonly property real menuSurfaceOffset: trayMenu.surfaceOffset
    readonly property real menuSurfaceHeight: trayMenu.surfaceHeight
    readonly property real menuSurfaceY:
        trayMenu.anchorOffsetY + trayMenu.panelTop
    readonly property real menuInteractionHeight: trayMenu.interactionHeight
    readonly property real menuInteractionY:
        trayMenu.anchorOffsetY + trayMenu.interactionTop
    readonly property real menuSurfaceWidth: trayMenu.surfaceWidth
    readonly property real menuContentWidth: trayMenu.panelWidth
    readonly property real menuSurfaceCornerRadius: trayMenu.surfaceCornerRadius
    readonly property real contentPadding: 4
    readonly property real slotHeight: 28
    readonly property real effectivePadding: itemCount === 1
        ? (width - slotHeight) / 2
        : contentPadding

    visible: itemCount > 0
    width: 32
    height: visible ? effectivePadding * 2 + itemCount * slotHeight : 0
    radius: width / 2
    color: Theme.trayIsland
    antialiasing: true

    HoverHandler {
        id: trayHover
    }

    TrayMenuPopup {
        id: trayMenu

        anchorItem: root
        trayHovered: trayHover.hovered
            || root.hoveredSlotCount > 0
            || root.extendedHoverGuard
    }

    Column {
        anchors {
            top: parent.top
            topMargin: root.effectivePadding
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: SystemTray.items

            Item {
                id: traySlot

                required property var modelData

                width: root.width
                height: root.slotHeight

                function openMenu() {
                    if (modelData.hasMenu)
                        trayMenu.showFor(modelData, traySlot);
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 16
                    source: traySlot.modelData.icon
                    mipmap: true
                }

                MouseArea {
                    id: trayMouse

                    property bool reportedHovered: false

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onContainsMouseChanged: {
                        if (reportedHovered === containsMouse)
                            return;

                        root.hoveredSlotCount = Math.max(0,
                            root.hoveredSlotCount + (containsMouse ? 1 : -1));
                        reportedHovered = containsMouse;
                    }

                    Component.onDestruction: {
                        if (reportedHovered)
                            root.hoveredSlotCount = Math.max(0, root.hoveredSlotCount - 1);
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            traySlot.modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton) {
                            traySlot.openMenu();
                        } else if (traySlot.modelData.onlyMenu && traySlot.modelData.hasMenu) {
                            traySlot.openMenu();
                        } else {
                            traySlot.modelData.activate();
                        }
                    }

                    onWheel: wheel => traySlot.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
