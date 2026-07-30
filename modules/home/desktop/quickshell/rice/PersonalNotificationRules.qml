pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property var displayNames: ({
        "telegram desktop": "Telegram",
        "discord": "Discord"
    })

    function normalized(value) {
        return String(value ?? "")
            .toLowerCase()
            .replace(/\s+/g, " ")
            .trim();
    }

    function displayAppName(appName) {
        return displayNames[normalized(appName)] ?? appName;
    }

    function isDiscord(appName) {
        return normalized(appName) === "discord";
    }

    function discordRoute(body) {
        const text = String(body ?? "");
        const prefix = "\u2063qs-discord-route:";
        const suffix = "\u2063";
        const markerStart = text.lastIndexOf(prefix);

        if (markerStart < 0)
            return "";

        const routeStart = markerStart + prefix.length;
        const routeEnd = text.indexOf(suffix, routeStart);

        if (routeEnd < 0)
            return "";

        const route = text.slice(routeStart, routeEnd);
        return /^(@me|[0-9]+)\/[0-9]+$/.test(route)
            ? route
            : "";
    }

    function notificationBody(body) {
        const text = String(body ?? "");
        const prefix = "\u2063qs-discord-route:";
        const markerStart = text.lastIndexOf(prefix);

        if (markerStart < 0)
            return text;

        const routeStart = markerStart + prefix.length;
        const routeEnd = text.indexOf("\u2063", routeStart);

        if (routeEnd < 0)
            return text;

        return text.slice(0, markerStart)
            + text.slice(routeEnd + 1);
    }
}
