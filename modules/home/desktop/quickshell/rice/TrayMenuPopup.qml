import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

PopupWindow {
    id: root

    required property Item anchorItem

    property var currentMenu: null
    property var currentTrayItem: null
    property var menuStack: []
    property string currentTitle: ""
    property bool openRequested: false
    property bool closeRequested: false
    property bool heightUpdateRequested: false
    property bool heightAnimationEnabled: false
    property bool trayHovered: false
    property bool hoverCloseEnabled: false
    property real preparedHeight: 64
    property real panelTop: 0
    property real interactionHeight: 64
    property real interactionTop: 0
    property int prepareElapsed: 0
    property int prepareLastCount: -1
    property int prepareStableTicks: 0
    property int interactionSerial: 0
    property var pendingMenu: null
    property var pendingTrayItem: null
    property var pendingMenuStack: []
    property string pendingTitle: ""
    property real anchorOffsetY: 0
    property real requestedAnchorOffsetY: 0
    property var pendingPlacement: ({ mode: "top" })
    property var placementOnUpdate: ({ mode: "top" })
    property bool contentTransitionActive: false
    property string suppressedToggleHoverLabel: ""
    // Set this back to true to restore the blur/fade text morph between menus.
    property bool menuTextBlurTransitionEnabled: false
    readonly property bool pointerInsideHoverGuard: trayHovered
        || menuHover.hovered
        || graceHover.hovered

    readonly property real panelWidth: 220
    // Ends inside the right rail so the popup visually grows out of the border.
    readonly property real bridgeWidth: 10
    readonly property real slideDistance: panelWidth + bridgeWidth
    readonly property real contentPadding: 8
    readonly property real rowHeight: 26
    readonly property real separatorHeight: 7
    readonly property real separatorLineHeight:
        1 / Math.max(1, root.devicePixelRatio)
    readonly property real headerHeight: 32
    readonly property real maximumPanelHeight: 520
    readonly property int hoverCloseDelay: 160
    readonly property int springDuration: 280
    readonly property real springOvershoot: 1.15
    readonly property real surfaceOffset: menuVisual.x
    readonly property real surfaceHeight: preparedHeight
    readonly property real surfaceCornerRadius: 20
    // This extra SDF-only tail stays hidden below the right rail. It keeps the
    // surface united with the rail throughout the spring overshoot without
    // moving or resizing any visible menu content.
    readonly property real hiddenSurfaceTail: 20
    readonly property real surfaceWidth: panelWidth + hiddenSurfaceTail
    readonly property var renderedEntries:
        PersonalTrayMenuRules.filterRootEntries(
            currentTrayItem,
            menuStack.length,
            menuOpener.children.values
        )

    function toggleHoverSuppressed(entry) {
        return suppressedToggleHoverLabel !== ""
            && String(entry.text) === suppressedToggleHoverLabel;
    }

    function slotOffsetY(sourceItem) {
        if (!sourceItem)
            return 0;

        return sourceItem.mapToItem(anchorItem, 0, 0).y;
    }

    function showFor(trayItem, sourceItem) {
        if (!trayItem || !trayItem.hasMenu)
            return;

        suppressedToggleHoverLabel = "";
        interactionSerial += 1;
        closeRequested = false;
        slideAnimation.stop();
        requestedAnchorOffsetY = slotOffsetY(sourceItem);

        if (visible) {
            // A tray-to-tray switch keeps the popup in place. Its content
            // blurs out, swaps, then morphs back in while height catches up.
            menuVisual.x = 0;
            openRequested = false;
            focusGrab.active = true;
            queueContentSwitch(
                trayItem.menu,
                trayItem,
                PersonalTrayMenuRules.displayTitle(
                    trayItem,
                    trayItem.tooltipTitle || trayItem.title || trayItem.id
                ),
                [],
                { mode: "top" }
            );
            return;
        }

        openRequested = true;
        heightUpdateRequested = false;
        heightAnimationEnabled = false;
        hoverCloseEnabled = false;
        hoverCloseTimer.stop();
        currentTrayItem = trayItem;
        currentMenu = trayItem.menu;
        currentTitle = PersonalTrayMenuRules.displayTitle(
            trayItem,
            trayItem.tooltipTitle || trayItem.title || trayItem.id
        );
        menuStack = [];
        anchorOffsetY = requestedAnchorOffsetY;
        menuVisual.x = slideDistance;
        startPreparation();
    }

    function queueContentSwitch(menu, trayItem, title, stack, placement) {
        suppressedToggleHoverLabel = "";
        pendingMenu = menu;
        pendingTrayItem = trayItem;
        pendingTitle = title;
        pendingMenuStack = stack;
        pendingPlacement = placement;

        if (!menuTextBlurTransitionEnabled) {
            contentTransitionActive = false;
            switchOutAnimation.stop();
            switchInAnimation.stop();
            contentLayer.opacity = 1;
            contentLayer.scale = 1;
            contentLayer.blurAmount = 0;
            commitContentSwitch();
            return;
        }

        contentTransitionActive = true;
        prepareTimer.stop();
        switchInAnimation.stop();

        if (contentLayer.opacity < 0.05) {
            switchOutAnimation.stop();
            commitContentSwitch();
        } else if (!switchOutAnimation.running) {
            switchOutAnimation.restart();
        }
    }

    function commitContentSwitch() {
        currentMenu = pendingMenu;
        currentTrayItem = pendingTrayItem;
        currentTitle = pendingTitle;
        menuStack = pendingMenuStack;
        placementOnUpdate = pendingPlacement;
        pendingMenu = null;
        pendingTrayItem = null;
        pendingTitle = "";
        pendingMenuStack = [];
        pendingPlacement = ({ mode: "top" });
        heightUpdateRequested = true;
        heightAnimationEnabled = true;
        startPreparation();
    }

    function startPreparation() {
        prepareElapsed = 0;
        prepareLastCount = -1;
        prepareStableTicks = 0;
        prepareTimer.restart();
    }

    function measuredPanelHeight() {
        const entries = renderedEntries;
        let contentHeight = 0;

        for (let index = 0; index < entries.length; ++index) {
            const entry = entries[index];
            contentHeight += entry.isSeparator ? separatorHeight : rowHeight;
        }

        if (entries.length > 1)
            contentHeight += entries.length - 1;

        return Math.max(
            64,
            Math.min(
                maximumPanelHeight,
                headerHeight + contentHeight + contentPadding * 2
            )
        );
    }

    function finishOpen() {
        if (!openRequested)
            return;

        prepareTimer.stop();
        preparedHeight = measuredPanelHeight();
        panelTop = 0;
        interactionHeight = preparedHeight;
        interactionTop = panelTop;
        interactionShrinkTimer.stop();
        openRequested = false;
        heightUpdateRequested = false;
        heightAnimationEnabled = false;
        menuVisual.x = slideDistance;
        visible = true;
        Qt.callLater(() => {
            if (!root.visible || root.closeRequested)
                return;

            focusGrab.active = true;
            slideAnimation.stop();
            slideAnimation.from = root.slideDistance;
            slideAnimation.to = 0;
            slideAnimation.start();
        });
    }

    function targetTopForHeight(naturalHeight) {
        const maximumTop = Math.max(
            0,
            root.maximumPanelHeight - naturalHeight
        );
        const placement = placementOnUpdate ?? ({ mode: "top" });

        if (placement.mode === "restore") {
            return Math.max(
                0,
                Math.min(placement.top, maximumTop)
            );
        }

        if (placement.mode === "submenu"
                && naturalHeight < preparedHeight
                && placement.pointerY > naturalHeight + 4) {
            // A compact child normally shrinks from the bottom. If that would
            // leave the click below the child, move its top only as far as the
            // source row so the pointer remains inside.
            return Math.max(
                0,
                Math.min(placement.sourceTop, maximumTop)
            );
        }

        return 0;
    }

    function updateOpenHeight() {
        if (visible) {
            heightAnimationEnabled = true;
            const naturalHeight = measuredPanelHeight();
            const targetTop = targetTopForHeight(naturalHeight);
            const targetBottom = targetTop + naturalHeight;
            const previousBottom = panelTop + preparedHeight;
            const interactionBottom = interactionTop + interactionHeight;

            if (naturalHeight < preparedHeight) {
                // Resize the visible panel now, but preserve its previous
                // hover/input footprint for the two-second grace period.
                const expandedTop = Math.min(
                    interactionTop,
                    panelTop,
                    targetTop
                );
                const expandedBottom = Math.max(
                    interactionBottom,
                    previousBottom,
                    targetBottom
                );
                interactionTop = expandedTop;
                interactionHeight = expandedBottom - expandedTop;
                interactionShrinkTimer.restart();
            } else {
                interactionShrinkTimer.stop();
                interactionTop = targetTop;
                interactionHeight = naturalHeight;
            }

            // Start all geometry changes in the same event-loop turn. The
            // backing PopupWindow stays fixed at the tray's top; only the
            // masked visual origin and height spring to the new icon/menu.
            anchorOffsetY = requestedAnchorOffsetY;
            panelTop = targetTop;
            preparedHeight = naturalHeight;
            placementOnUpdate = ({ mode: "top" });

            if (contentTransitionActive)
                switchInAnimation.restart();
        }
    }

    function updateHoverCloseState() {
        if (!visible || !hoverCloseEnabled || pointerInsideHoverGuard) {
            hoverCloseTimer.stop();
            return;
        }

        hoverCloseTimer.restart();
    }

    function requestClose() {
        if (!visible || closeRequested)
            return;

        interactionSerial += 1;
        closeRequested = true;
        openRequested = false;
        heightUpdateRequested = false;
        heightAnimationEnabled = false;
        hoverCloseEnabled = false;
        prepareTimer.stop();
        hoverCloseTimer.stop();
        interactionShrinkTimer.stop();
        focusGrab.active = false;

        slideAnimation.stop();
        slideAnimation.from = menuVisual.x;
        slideAnimation.to = slideDistance;
        slideAnimation.start();
    }

    function finishClose() {
        if (!closeRequested)
            return;

        closeRequested = false;
        visible = false;
    }

    function enterSubmenu(entry, sourceTop, pointerY) {
        queueContentSwitch(
            entry,
            currentTrayItem,
            entry.text,
            menuStack.concat([{
                menu: currentMenu,
                title: currentTitle,
                top: panelTop
            }]),
            {
                mode: "submenu",
                sourceTop: sourceTop,
                pointerY: pointerY
            }
        );
    }

    function leaveSubmenu() {
        if (menuStack.length === 0)
            return;

        const previous = menuStack[menuStack.length - 1];
        queueContentSwitch(
            previous.menu,
            currentTrayItem,
            previous.title,
            menuStack.slice(0, -1),
            {
                mode: "restore",
                top: previous.top
            }
        );
    }

    function triggerEntry(entry, sourceTop, pointerY) {
        if (!entry.enabled || entry.isSeparator)
            return;

        if (entry.hasChildren) {
            enterSubmenu(entry, sourceTop, pointerY);
        } else {
            entry.triggered();

            // Toggle entries represent persistent state. Let the application
            // update checkState without dismissing the menu.
            if (entry.buttonType === QsMenuButtonType.None
                    && entry.closeOnTrigger !== false) {
                requestClose();
            }
        }
    }

    implicitWidth: panelWidth + bridgeWidth
    // Keep the Wayland surface stable so menu switches never trigger a series
    // of compositor resizes. Only the masked SDF surface below changes height.
    implicitHeight: maximumPanelHeight + anchorItem.height
    color: Theme.transparent
    // PopupWindow's native grab consumes the first outside click. Hyprland's
    // focus-grab protocol lets that click reach the window below while still
    // notifying us so the popup can animate closed.
    grabFocus: false
    mask: Region {
        item: menuHoverGuard
    }

    Behavior on preparedHeight {
        enabled: root.visible
            && root.heightAnimationEnabled
            && !root.closeRequested

        NumberAnimation {
            duration: root.springDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.springOvershoot
        }
    }

    Behavior on panelTop {
        enabled: root.visible
            && root.heightAnimationEnabled
            && !root.closeRequested

        NumberAnimation {
            duration: root.springDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.springOvershoot
        }
    }

    Behavior on anchorOffsetY {
        enabled: root.visible
            && root.heightAnimationEnabled
            && !root.closeRequested

        NumberAnimation {
            duration: root.springDuration
            easing.type: Easing.OutBack
            easing.overshoot: root.springOvershoot
        }
    }

    anchor {
        item: root.anchorItem
        rect.x: 0
        rect.y: 0
        rect.width: 1
        rect.height: 1
        edges: Edges.Left | Edges.Top
        // Grow left from the rail and down from the tray's top edge.
        gravity: Edges.Left | Edges.Bottom
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Resize
    }

    onVisibleChanged: {
        if (!visible && !openRequested) {
            prepareTimer.stop();
            hoverCloseTimer.stop();
            interactionShrinkTimer.stop();
            focusGrab.active = false;
            closeRequested = false;
            heightUpdateRequested = false;
            heightAnimationEnabled = false;
            hoverCloseEnabled = false;
            menuVisual.x = slideDistance;
            contentLayer.opacity = 1;
            contentLayer.scale = 1;
            contentLayer.blurAmount = 0;
            contentTransitionActive = false;
            switchOutAnimation.stop();
            switchInAnimation.stop();
            currentMenu = null;
            currentTrayItem = null;
            menuStack = [];
            pendingMenu = null;
            pendingTrayItem = null;
            pendingTitle = "";
            pendingMenuStack = [];
            pendingPlacement = ({ mode: "top" });
            placementOnUpdate = ({ mode: "top" });
            preparedHeight = 64;
            anchorOffsetY = 0;
            requestedAnchorOffsetY = 0;
            panelTop = 0;
            interactionHeight = 64;
            interactionTop = panelTop;
        }
    }

    onPointerInsideHoverGuardChanged: updateHoverCloseState()

    HyprlandFocusGrab {
        id: focusGrab

        // Keep both the popup and the masked BorderFrame surface interactive.
        // The frame's input mask contains only the workspace/tray islands, so
        // normal desktop clicks remain outside the whitelist while a different
        // tray icon can receive the very first click.
        windows: [ root, root.anchor.window ]

        onCleared: {
            const serialAtClear = root.interactionSerial;

            // The compositor emits this before/around delivery of the same
            // pointer event. Waiting one event-loop turn gives a tray icon the
            // chance to switch menus and reactivate the grab without closing.
            Qt.callLater(() => {
                if (serialAtClear === root.interactionSerial
                        && root.visible
                        && !root.closeRequested
                        && !focusGrab.active) {
                    root.requestClose();
                }
            });
        }
    }

    Timer {
        id: hoverCloseTimer

        interval: root.hoverCloseDelay
        onTriggered: {
            if (root.visible
                    && root.hoverCloseEnabled
                    && !root.pointerInsideHoverGuard) {
                root.requestClose();
            }
        }
    }

    Timer {
        id: interactionShrinkTimer

        interval: 2000
        onTriggered: {
            root.interactionTop = root.panelTop;
            root.interactionHeight = root.preparedHeight;
            Qt.callLater(() => root.updateHoverCloseState());
        }
    }

    Timer {
        id: prepareTimer

        interval: 16
        repeat: true
        onTriggered: {
            const count = menuOpener.children.values.length;
            root.prepareElapsed += interval;

            if (count === root.prepareLastCount) {
                root.prepareStableTicks += 1;
            } else {
                root.prepareLastCount = count;
                root.prepareStableTicks = 0;
            }

            const modelSettled = count > 0
                && root.prepareStableTicks >= 2
                && root.prepareElapsed >= 48;
            const preparationTimedOut = root.prepareElapsed >= 500;

            if (!modelSettled && !preparationTimedOut)
                return;

            stop();

            if (root.openRequested) {
                root.finishOpen();
            } else if (root.heightUpdateRequested) {
                root.heightUpdateRequested = false;
                root.updateOpenHeight();
            }
        }
    }

    QsMenuOpener {
        id: menuOpener

        menu: root.currentMenu
    }

    // Keep the application's root menu open while a child page is visible.
    // Releasing the only root reference emits "closed" and can invalidate
    // lazily populated submenu entries.
    QsMenuOpener {
        id: rootMenuRetainer

        menu: root.currentTrayItem ? root.currentTrayItem.menu : null
    }

    // Resolve lazy child entries during the blur-out phase, while the current
    // page and the application root are both still retained.
    QsMenuOpener {
        id: pendingMenuOpener

        menu: root.pendingMenu
    }

    Item {
        id: menuHoverGuard

        x: 0
        y: root.anchorOffsetY + root.interactionTop
        width: root.width
        height: root.interactionHeight

        HoverHandler {
            id: graceHover
        }
    }

    Item {
        id: menuClip

        x: 0
        y: root.anchorOffsetY + root.panelTop
        width: root.panelWidth
        height: root.preparedHeight
        clip: true
        focus: true

        Keys.onEscapePressed: root.requestClose()

        HoverHandler {
            id: menuHover
        }

        Item {
            id: menuVisual

            x: root.slideDistance
            width: root.width
            height: parent.height

            NumberAnimation {
                id: slideAnimation

                target: menuVisual
                property: "x"
                duration: root.springDuration
                easing.type: Easing.OutBack
                easing.overshoot: root.springOvershoot
                onFinished: {
                    if (root.closeRequested) {
                        root.finishClose();
                    } else {
                        root.hoverCloseEnabled = true;
                        root.updateHoverCloseState();
                    }
                }
            }

            Item {
                id: contentLayer

                property real blurAmount: 0

                anchors.fill: parent
                enabled: !root.contentTransitionActive
                transformOrigin: Item.Center
                layer.enabled: root.contentTransitionActive
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: contentLayer.blurAmount
                    blurMax: 24
                    autoPaddingEnabled: false
                }

                Item {
                    id: header

                    x: root.contentPadding
                    y: root.contentPadding
                    width: root.panelWidth - root.contentPadding * 2
                    height: root.headerHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: headerMouse.containsMouse && root.menuStack.length > 0
                            ? Theme.trayMenuHover
                            : Theme.transparent
                    }

                    Text {
                        id: backIndicator

                        visible: root.menuStack.length > 0
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        width: 16
                        text: "‹"
                        color: Theme.trayMenuText
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }
                        width: parent.width - 48
                        text: root.currentTitle
                        color: Theme.trayMenuText
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        id: headerMouse

                        anchors.fill: parent
                        enabled: root.menuStack.length > 0
                        hoverEnabled: enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.leaveSubmenu()
                    }
                }

                Flickable {
                    id: menuFlick

                    x: root.contentPadding
                    y: root.contentPadding + root.headerHeight
                    width: root.panelWidth - root.contentPadding * 2
                    height: menuVisual.height - y - root.contentPadding
                    contentWidth: width
                    contentHeight: menuColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    interactive: contentHeight > height

                    Column {
                        id: menuColumn

                        width: menuFlick.width
                        spacing: 1

                        Repeater {
                            id: menuRepeater

                            model: root.renderedEntries

                            Item {
                                id: menuRow

                                required property var modelData
                                readonly property bool isToggle:
                                    modelData.buttonType !== QsMenuButtonType.None
                                readonly property bool toggleActive:
                                    isToggle && modelData.checkState === Qt.Checked

                                width: menuColumn.width
                                height: modelData.isSeparator
                                    ? root.separatorHeight
                                    : root.rowHeight
                                opacity: modelData.enabled || modelData.isSeparator ? 1 : 0.45

                                Rectangle {
                                    readonly property real sceneBaseY:
                                        menuClip.y
                                        + menuFlick.y
                                        - menuFlick.contentY
                                        + menuRow.y
                                    readonly property real centeredY:
                                        (menuRow.height - height) / 2

                                    visible: menuRow.modelData.isSeparator
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    y: Math.round(
                                        (sceneBaseY + centeredY)
                                            / root.separatorLineHeight
                                    ) * root.separatorLineHeight - sceneBaseY
                                    height: root.separatorLineHeight
                                    opacity: 1
                                    antialiasing: false
                                    color: Theme.trayMenuSeparator
                                }

                                Rectangle {
                                    visible: !menuRow.modelData.isSeparator
                                        && (menuRow.toggleActive
                                            || (rowMouse.containsMouse
                                                && !root.toggleHoverSuppressed(
                                                    menuRow.modelData
                                                )))
                                    anchors.fill: parent
                                    radius: 8
                                    color: menuRow.toggleActive
                                        ? Theme.trayIsland
                                        : Theme.trayMenuHover
                                }

                                Text {
                                    visible: !menuRow.modelData.isSeparator
                                    anchors {
                                        left: parent.left
                                        leftMargin: 7
                                        right: submenuIndicator.left
                                        rightMargin: 6
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: menuRow.modelData.text
                                    color: menuRow.modelData.enabled
                                        ? Theme.trayMenuText
                                        : Theme.trayMenuMuted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                Text {
                                    id: submenuIndicator

                                    visible: !menuRow.modelData.isSeparator
                                        && menuRow.modelData.hasChildren
                                    anchors {
                                        right: parent.right
                                        rightMargin: 7
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: 12
                                    text: "›"
                                    color: Theme.trayMenuMuted
                                    font.pixelSize: 17
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: rowMouse

                                    visible: !menuRow.modelData.isSeparator
                                    anchors.fill: parent
                                    enabled: menuRow.modelData.enabled
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onContainsMouseChanged: {
                                        if (!containsMouse
                                                && root.toggleHoverSuppressed(
                                                    menuRow.modelData
                                                )) {
                                            root.suppressedToggleHoverLabel = "";
                                        }
                                    }
                                    onClicked: mouse => {
                                        if (menuRow.isToggle
                                                && menuRow.toggleActive) {
                                            root.suppressedToggleHoverLabel =
                                                String(menuRow.modelData.text);
                                        }

                                        // Compact-submenu placement is local
                                        // to the current panel. menuClip.y
                                        // already contains the clicked tray
                                        // icon's outer popup offset and must
                                        // not be applied a second time.
                                        const sourceTop = menuFlick.y
                                            - menuFlick.contentY
                                            + menuRow.y;
                                        root.triggerEntry(
                                            menuRow.modelData,
                                            sourceTop,
                                            sourceTop + mouse.y
                                        );
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: switchOutAnimation

        NumberAnimation {
            target: contentLayer
            property: "opacity"
            to: 0.42
            duration: 90
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: contentLayer
            property: "blurAmount"
            to: 0.90
            duration: 90
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: contentLayer
            property: "scale"
            to: 0.99
            duration: 90
            easing.type: Easing.OutCubic
        }

        onFinished: root.commitContentSwitch()
    }

    ParallelAnimation {
        id: switchInAnimation

        NumberAnimation {
            target: contentLayer
            property: "opacity"
            to: 1
            duration: 170
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: contentLayer
            property: "blurAmount"
            to: 0
            duration: 170
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: contentLayer
            property: "scale"
            to: 1
            duration: 170
            easing.type: Easing.OutCubic
        }

        onFinished: root.contentTransitionActive = false
    }
}
