pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    Variants {
        // Macbook internal display (eDP-*) or fallback to first screen
        model: {
            const screens = Quickshell.screens;
            const internal = screens.filter(s => s.name.startsWith("eDP") || s.name.startsWith("LVDS"));
            return internal.length > 0 ? internal : (screens.length > 0 ? [screens[0]] : []);
        }

        Scope {
            id: perScreen
            required property ShellScreen modelData

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            // Hyprland: 0 = off, 1 = maximised, 2+ = true fullscreen (covers the output).
            readonly property bool hasFullscreen:
                monitor?.activeWorkspace?.toplevels.values.some(
                    t => (t.lastIpcObject?.fullscreen ?? 0) > 1) ?? false

            BarState { id: barState }

            Connections {
                target: Hyprland
                function onRawEvent(event): void {
                    if (["fullscreen", "activewindow", "openwindow", "closewindow", "movewindow", "workspace", "moveworkspace", "focusedmon"].includes(event.name))
                        Hyprland.refreshToplevels();
                }
            }

            BorderWindow     { screen: perScreen.modelData; barState: barState; hasFullscreen: perScreen.hasFullscreen }
            BorderExclusions { screen: perScreen.modelData; barState: barState; hasFullscreen: perScreen.hasFullscreen }
            CenterPopup      { screen: perScreen.modelData; barState: barState }
            BarWindow        { screen: perScreen.modelData; barState: barState; hasFullscreen: perScreen.hasFullscreen }
        }
    }
}
