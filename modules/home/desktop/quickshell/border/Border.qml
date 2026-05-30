pragma ComponentBehavior: Bound
import Quickshell

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

            BarState { id: barState }

            BorderWindow     { screen: perScreen.modelData; barState: barState }
            BorderExclusions { screen: perScreen.modelData; barState: barState }
            CenterPopup      { screen: perScreen.modelData; barState: barState }
            BarWindow        { screen: perScreen.modelData; barState: barState }
        }
    }
}
