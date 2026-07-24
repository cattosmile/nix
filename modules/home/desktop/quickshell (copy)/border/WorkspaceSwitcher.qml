pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Vertical workspace indicator for the right bar.
// Pills sit on a dark island; a white pill slides (spring) to the active slot.
Item {
    id: root

    readonly property int count:         5
    readonly property int dotSpacing:    28   // slot center-to-center distance
    readonly property int inactivePillW: 7    // inactive pill width
    readonly property int inactivePillH: 16   // inactive pill height
    readonly property int activePillW:   10   // active bubble width
    readonly property int activePillH:   26   // active bubble height
    readonly property int islandPadH:    8    // island horizontal padding per side
    readonly property int islandPadV:    12   // island vertical padding per side

    implicitWidth:  Theme.islandWidth
    implicitHeight: (count - 1) * dotSpacing + activePillH + islandPadV * 2

    // Track by monitor name so focus on other monitors doesn't move the bubble.
    // Macbook internal display (eDP-*) or fallback to first monitor.
    property string monitorName: {
        const monitors = Hyprland.monitors.values;
        const internal = monitors.find(m => m.name.startsWith("eDP") || m.name.startsWith("LVDS"));
        return internal ? internal.name : (monitors.length > 0 ? monitors[0].name : "");
    }

    readonly property var trackedMonitor:
        Hyprland.monitors.values.find(m => m.name === monitorName) ?? null

    readonly property int activeWs: Math.max(1, Math.min(count,
        trackedMonitor?.activeWorkspace?.id ?? 1))

    // ── Right-click → floating Alacritty ─────────────────────────────────────
    Component {
        id: openAlacritty
        Process {
            command: ["hyprctl", "dispatch", "exec", "[float;center] alacritty"]
            running: true
            onRunningChanged: if (!running) destroy()
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: openAlacritty.createObject(root)
    }

    // ── Island ───────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color:  Theme.islandBg
    }

    // ── Sliding active bubble ────────────────────────────────────────────────
    Rectangle {
        id: bubble
        width:  root.activePillW
        height: root.activePillH
        radius: root.activePillW / 2
        color:  Theme.islandActive
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.islandPadV + (root.activeWs - 1) * root.dotSpacing
        z: 2  // above grey pills so it covers rather than reveals

        Behavior on y {
            SpringAnimation {
                spring:  3.5
                damping: 0.28
                epsilon: 0.5
            }
        }
    }

    // ── Pill grid ─────────────────────────────────────────────────────────────
    Repeater {
        model: root.count
        delegate: Item {
            id: slot
            required property int index
            readonly property int  wsId:   index + 1
            readonly property bool active: wsId === root.activeWs

            // Touch area: full island width, one slot tall, centered on slot
            width:  root.implicitWidth
            height: root.dotSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.islandPadV + index * root.dotSpacing
               + (root.activePillH - root.dotSpacing) / 2
            z: 1

            Rectangle {
                anchors.centerIn: parent
                width:  root.inactivePillW
                height: root.inactivePillH
                radius: root.inactivePillW / 2
                color:  Theme.islandInactive
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }

            TapHandler {
                onTapped: Hyprland.dispatch("workspace " + slot.wsId)
            }
        }
    }
}
