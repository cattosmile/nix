import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Rectangle {
    id: root

    required property var screen

    function focusWorkspace(workspaceId) {
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspaceId}" })`);
        else
            Hyprland.dispatch(`workspace ${workspaceId}`);
    }

    function focusWrappedWorkspace(workspaceId, scrollsDown) {
        if (!Hyprland.usingLua) {
            focusWorkspace(workspaceId);
            return;
        }

        const forcedDirection = scrollsDown
            ? "bottom"
            : "top";
        const lua = `
            local function set_workspace_style(style)
                hl.animation({
                    leaf = "workspacesIn",
                    enabled = true,
                    speed = 2.5,
                    bezier = "easeOutQuint",
                    style = style
                })
                hl.animation({
                    leaf = "workspacesOut",
                    enabled = true,
                    speed = 3.5,
                    bezier = "easeOutQuint",
                    style = style
                })
            end

            set_workspace_style("slidevert ${forcedDirection}")

            local ok, err = pcall(function()
                hl.dispatch(hl.dsp.focus({
                    workspace = "${workspaceId}"
                }))
            end)

            set_workspace_style("slidevert")

            if not ok then
                error(err)
            end
        `;

        workspaceWrapProcess.command = [
            "hyprctl",
            "eval",
            lua
        ];
        workspaceWrapProcess.running = true;
    }

    readonly property var monitor: Hyprland.monitorFor(root.screen)
    readonly property int activeWorkspaceId: root.monitor?.activeWorkspace?.id ?? -1
    readonly property int workspaceCount: 5
    readonly property int maximumScrollableWorkspaceId: 9
    readonly property int activeWorkspaceIndex: activeWorkspaceId >= 1 && activeWorkspaceId <= workspaceCount
        ? activeWorkspaceId - 1
        : -1
    readonly property real contentPadding: 10
    readonly property real slotHeight: 30
    readonly property real inactivePillHeight: 18
    readonly property real activePillHeight: Math.min(25, slotHeight * 1.35)
    property int displayedActiveWorkspaceIndex: 0
    property bool activeIndicatorWasInRange: false
    property bool animateActiveIndicatorMovement: false
    property bool activeIndicatorStateInitialized: false
    property int activeIndicatorStateGeneration: 0
    property real wheelAngleRemainder: 0

    function scrollWorkspaces(angleDeltaY) {
        if (activeWorkspaceId < 1 || angleDeltaY === 0)
            return;

        wheelAngleRemainder += angleDeltaY;

        const stepCount = Math.trunc(
            Math.abs(wheelAngleRemainder) / 120
        );

        if (stepCount < 1)
            return;

        const workspaceDelta = wheelAngleRemainder < 0
            ? stepCount
            : -stepCount;
        const consumedAngle = Math.sign(wheelAngleRemainder)
            * stepCount
            * 120;

        wheelAngleRemainder -= consumedAngle;

        const unwrappedWorkspaceId =
            activeWorkspaceId + workspaceDelta;
        const wrapRange = maximumScrollableWorkspaceId;
        const targetWorkspaceId = (
            (
                (unwrappedWorkspaceId - 1) % wrapRange
            ) + wrapRange
        ) % wrapRange + 1;
        const wrapped = unwrappedWorkspaceId < 1
            || unwrappedWorkspaceId > wrapRange;

        if (targetWorkspaceId === activeWorkspaceId)
            return;

        if (wrapped)
            focusWrappedWorkspace(
                targetWorkspaceId,
                workspaceDelta > 0
            );
        else
            focusWorkspace(targetWorkspaceId);
    }

    function syncActiveIndicator() {
        const indicatorInRange = activeWorkspaceIndex >= 0;
        const generation = ++activeIndicatorStateGeneration;

        if (!activeIndicatorStateInitialized) {
            activeIndicatorStateInitialized = true;
            activeIndicatorWasInRange = indicatorInRange;
            animateActiveIndicatorMovement = false;

            if (indicatorInRange)
                displayedActiveWorkspaceIndex = activeWorkspaceIndex;

            Qt.callLater(function() {
                if (root.activeIndicatorStateGeneration === generation)
                    root.animateActiveIndicatorMovement = true;
            });
            return;
        }

        if (!indicatorInRange) {
            activeIndicatorWasInRange = false;
            animateActiveIndicatorMovement = false;
            return;
        }

        animateActiveIndicatorMovement = activeIndicatorWasInRange;
        displayedActiveWorkspaceIndex = activeWorkspaceIndex;
        activeIndicatorWasInRange = true;

        if (!animateActiveIndicatorMovement) {
            Qt.callLater(function() {
                if (root.activeIndicatorStateGeneration === generation
                        && root.activeWorkspaceIndex >= 0)
                    root.animateActiveIndicatorMovement = true;
            });
        }
    }

    onActiveWorkspaceIndexChanged: syncActiveIndicator()
    Component.onCompleted: syncActiveIndicator()

    width: 32
    height: contentPadding * 2 + workspaceCount * slotHeight
    radius: width / 2
    color: Theme.workspaceIsland

    Process {
        id: workspaceWrapProcess

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            root.scrollWorkspaces(event.angleDelta.y);
            event.accepted = true;
        }
    }

    Column {
        anchors {
            top: parent.top
            topMargin: root.contentPadding
            horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: root.workspaceCount

            Item {
                id: workspaceSlot

                required property int index
                readonly property int workspaceId: index + 1
                readonly property var workspace: Hyprland.workspaces.values.find(candidate => candidate.id === workspaceId)
                readonly property bool occupied: workspace?.toplevels?.values.length > 0

                width: root.width
                height: root.slotHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: 7
                    height: root.inactivePillHeight
                    radius: width / 2
                    color: workspaceSlot.occupied
                        ? Theme.workspaceOccupied
                        : Theme.workspaceInactive
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.focusWorkspace(workspaceSlot.workspaceId)
                }
            }
        }
    }

    Rectangle {
        visible: root.activeWorkspaceIndex >= 0 || opacity > 0
        enabled: false
        opacity: root.activeWorkspaceIndex >= 0 ? 1 : 0
        z: 1
        x: (root.width - width) / 2
        y: root.contentPadding
            + root.displayedActiveWorkspaceIndex * root.slotHeight
            + (root.slotHeight - height) / 2
        width: 9
        height: root.activePillHeight
        radius: width / 2
        color: Theme.workspaceActive

        Behavior on y {
            enabled: root.animateActiveIndicatorMovement

            NumberAnimation {
                duration: 420
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }
    }
}
