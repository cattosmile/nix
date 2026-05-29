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

            BorderWindow    { screen: perScreen.modelData }
            BorderExclusions { screen: perScreen.modelData }
            BarWindow       { screen: perScreen.modelData }
            NotifPopup      { screen: perScreen.modelData }
        }
    }
}
