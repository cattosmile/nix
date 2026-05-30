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

    // ── Derived ───────────────────────────────────────────────────────────
    readonly property color frameColor: surface

}
