pragma ComponentBehavior: Bound
import QtQuick

// Per-screen shared state: one instance lives in each Border Variants delegate
// and is injected into that screen's BarWindow / BorderWindow / BorderExclusions.
// Kept off the Theme singleton so multiple monitors don't share one bar width.
QtObject {
    // Visible bar width, tracked every frame by the border hole.
    property real activeBarWidth: Theme.barWidth
    // Committed once per toggle so Hyprland reflows the layout a single time.
    property real exclusionBarWidth: Theme.barWidth

    // Centered popup rectangle toggled by the dummy bar button.
    property bool centerPopupVisible: false
}
