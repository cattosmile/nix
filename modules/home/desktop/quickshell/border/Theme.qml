pragma Singleton
import QtQuick

// Single source of truth for colors and layout dimensions.
// All properties are mutable so a future theme switcher can swap them at runtime.
QtObject {
    id: root

    // ── Layout ────────────────────────────────────────────────────────────
    readonly property real frameThickness: 10
    readonly property real barWidth: 54
    readonly property real innerRadius: 24
    readonly property real islandWidth: 34
    readonly property real expandedWidth: 520

    // ── Palette ───────────────────────────────────────────────────────────
    property color surface:   "#000000"  // frame fill
    property color bar:       "#000000"  // bar background
    property color accent:    "#ffffff"
    property color text:      "#f2d0d0"  // primary text
    property color subtext:   "#7a4444"  // secondary text
    property color highlight: "#c03030"  // hover / active states

    // ── Islands ───────────────────────────────────────────────────────────
    // Shared by AudioIsland, StatusIsland, TrayIsland, WorkspaceSwitcher, MenuIsland
    property color islandBg:       "#1e1e1e"
    property color islandInactive: "#424242"
    property color islandActive:   "#ffffff"
    property color islandMuted:    "#888888"
    property color islandDisabled: "#555555"

    // ── Notifications ─────────────────────────────────────────────────────
    readonly property real  notifWidth:       400
    readonly property real  notifSpacing:     12
    readonly property real  notifPadding:     14
    readonly property real  notifAvatarSize:  46
    readonly property real  notifRadius:      18
    readonly property int   notifMaxVisible:  5
    readonly property int   notifDefaultTimeout: 5000
    property color notifBg:       "#141414"
    property color notifBorder:   "#2a2a2a"
    property color notifCritical: "#c03030"

    // ── Derived ───────────────────────────────────────────────────────────
    readonly property color frameColor: surface

}
