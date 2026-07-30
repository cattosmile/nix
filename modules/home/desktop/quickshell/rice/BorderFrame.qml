import Quickshell
import QtQuick
import Mono.Sdf.Rust

PanelWindow {
    id: root

    required property int thickness
    required property int rightThickness
    required property real innerCornerSmoothness
    required property color borderColor
    readonly property real menuSurfaceOverlap: 2

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: launcherMenu.keyboardActive
    aboveWindows: true
    color: Theme.transparent
    mask: Region {
        item: workspaceIsland
        radius: workspaceIsland.radius

        Region {
            item: quickActionsIsland
            radius: quickActionsIsland.radius
        }

        Region {
            item: audioIsland
            radius: audioIsland.radius
        }

        Region {
            item: systemTrayIsland
            radius: systemTrayIsland.radius
        }

        Region {
            item: notificationInteractionRegion
        }

        Region {
            item: trayMenuHoverBridge
        }

        Region {
            item: trayMenuBottomHoverBridge
        }

        Region {
            item: launcherMenu.activationRegion
        }

        Region {
            item: launcherMenu.interactionRegion
        }
    }

    GpuSdfCanvas {
        id: canvas

        anchors.fill: parent
        fillColor: root.borderColor
        edgeSoftness: 0.75
        smoothness: root.innerCornerSmoothness

        SdfRoundRect {
            x: canvas.width / 2
            y: root.thickness / 2
            halfWidth: canvas.width / 2
            halfHeight: root.thickness / 2
            cornerRadius: 0
            cornerSmoothing: 0
        }

        SdfRoundRect {
            x: canvas.width / 2
            y: canvas.height - root.thickness / 2
            halfWidth: canvas.width / 2
            halfHeight: root.thickness / 2
            cornerRadius: 0
            cornerSmoothing: 0
        }

        SdfRoundRect {
            x: root.thickness / 2
            y: canvas.height / 2
            halfWidth: root.thickness / 2
            halfHeight: canvas.height / 2
            cornerRadius: 0
            cornerSmoothing: 0
        }

        SdfRoundRect {
            x: canvas.width - root.rightThickness / 2
            y: canvas.height / 2
            halfWidth: root.rightThickness / 2
            halfHeight: canvas.height / 2
            cornerRadius: 0
            cornerSmoothing: 0
        }

        // The launcher grows downward from the top frame. Keeping the surface
        // in this canvas lets Mono.Sdf.Rust form both lower inner fillets from the
        // same geometry instead of layering a separate rounded window.
        SdfRoundRect {
            enabled: launcherMenu.surfaceVisible
            x: launcherMenu.surfaceX + launcherMenu.surfaceWidth / 2
            y: launcherMenu.surfaceY + launcherMenu.surfaceHeight / 2
            halfWidth: launcherMenu.surfaceWidth / 2
            halfHeight: launcherMenu.surfaceHeight / 2
            cornerRadius: launcherMenu.surfaceCornerRadius
            cornerSmoothing: 0.25
        }

        // The tray menu surface lives in this same canvas as the frame. Both
        // its SDF shape and PopupWindow content use the tray's top as their
        // shared origin, so compositor popup adjustment cannot separate them.
        SdfRoundRect {
            enabled: systemTrayIsland.menuSurfaceVisible
            x: canvas.width
                - root.rightThickness
                + root.menuSurfaceOverlap
                - systemTrayIsland.menuContentWidth
                + systemTrayIsland.menuSurfaceWidth / 2
                + systemTrayIsland.menuSurfaceOffset
            y: systemTrayIsland.y
                + systemTrayIsland.menuSurfaceY
                + systemTrayIsland.menuSurfaceHeight / 2
            halfWidth: systemTrayIsland.menuSurfaceWidth / 2
            halfHeight: systemTrayIsland.menuSurfaceHeight / 2
            cornerRadius: systemTrayIsland.menuSurfaceCornerRadius
            cornerSmoothing: 0.25
        }

        // Notifications share the frame canvas as two overlaid surfaces.
        // The back surface stays in place while a newer one slides down over
        // it, and both remain geometrically united with the top/right frame.
        SdfRoundRect {
            enabled: notificationToast.backSurfaceVisible
            x: notificationToast.x
                + notificationToast.backSurfaceX
                + notificationToast.surfaceWidth / 2
            y: notificationToast.y
                + notificationToast.backSurfaceY
                + notificationToast.panelHeight / 2
            halfWidth: notificationToast.surfaceWidth / 2
            halfHeight: notificationToast.panelHeight / 2
            cornerRadius: notificationToast.surfaceCornerRadius
            cornerSmoothing: 0.25
        }

        SdfRoundRect {
            enabled: notificationToast.frontSurfaceVisible
            x: notificationToast.x
                + notificationToast.frontSurfaceX
                + notificationToast.surfaceWidth / 2
            y: notificationToast.y
                + notificationToast.frontSurfaceY
                + notificationToast.panelHeight / 2
            halfWidth: notificationToast.surfaceWidth / 2
            halfHeight: notificationToast.panelHeight / 2
            cornerRadius: notificationToast.surfaceCornerRadius
            cornerSmoothing: 0.25
        }
    }

    LauncherMenu {
        id: launcherMenu

        borderThickness: root.thickness
    }

    // Extend the menu's hover/input corridor through the complete right rail.
    // Its height follows the popup's delayed interaction footprint, while the
    // visible SDF panel remains free to resize independently.
    Item {
        id: trayMenuHoverBridge

        visible: systemTrayIsland.menuSurfaceVisible
        x: parent.width - root.rightThickness
        y: systemTrayIsland.y
            + systemTrayIsland.menuInteractionY
        width: visible ? root.rightThickness : 0
        height: visible ? systemTrayIsland.menuInteractionHeight : 0

        HoverHandler {
            id: trayMenuBridgeHover
        }
    }

    // Keep a short strip below the menu protected as well, and extend it far
    // enough to include the tray when a compact menu ends above the island.
    Item {
        id: trayMenuBottomHoverBridge

        visible: systemTrayIsland.menuSurfaceVisible
        x: parent.width
            - root.rightThickness
            + root.menuSurfaceOverlap
            - systemTrayIsland.menuContentWidth
        y: systemTrayIsland.y
            + systemTrayIsland.menuInteractionY
            + systemTrayIsland.menuInteractionHeight
        width: visible
            ? systemTrayIsland.menuContentWidth
                + root.rightThickness
                - root.menuSurfaceOverlap
            : 0
        height: visible
            ? Math.max(
                12,
                systemTrayIsland.y
                    + systemTrayIsland.height
                    + 12
                    - y
            )
            : 0

        HoverHandler {
            id: trayMenuBottomBridgeHover
        }
    }

    NotificationToast {
        id: notificationToast

        anchors {
            top: parent.top
            topMargin: root.thickness - surfaceOverlap
            right: parent.right
            rightMargin: root.rightThickness - surfaceOverlap
        }

        borderThickness: root.thickness
        rightThickness: root.rightThickness
    }

    Item {
        id: notificationInteractionRegion

        visible: notificationToast.frontInteractive
        x: notificationToast.x
        y: notificationToast.y
        width: visible ? notificationToast.width : 0
        height: visible ? notificationToast.height : 0
    }

    WorkspaceIsland {
        id: workspaceIsland

        anchors {
            right: parent.right
            rightMargin: (root.rightThickness - width) / 2
            verticalCenter: parent.verticalCenter
        }

        screen: root.screen
    }

    QuickActionsIsland {
        id: quickActionsIsland

        anchors {
            top: parent.top
            topMargin: root.thickness
            right: parent.right
            rightMargin: (root.rightThickness - width) / 2
        }
    }

    AudioIsland {
        id: audioIsland

        anchors {
            top: quickActionsIsland.bottom
            topMargin: 12
            right: parent.right
            rightMargin: (root.rightThickness - width) / 2
        }
    }

    SystemTrayIsland {
        id: systemTrayIsland

        anchors {
            top: audioIsland.bottom
            topMargin: 12
            right: parent.right
            rightMargin: (root.rightThickness - width) / 2
        }

        extendedHoverGuard: trayMenuBridgeHover.hovered
            || trayMenuBottomBridgeHover.hovered
    }

    ClockPowerStack {
        anchors {
            bottom: parent.bottom
            bottomMargin: root.thickness
            right: parent.right
            rightMargin: (root.rightThickness - width) / 2
        }
    }
}
