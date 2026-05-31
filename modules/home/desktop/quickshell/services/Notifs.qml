pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Freedesktop / libnotify notification server. Quickshell becomes the system's
// notification daemon while the shell is running, so any app that sends a
// desktop notification (Discord, Spotify, …) lands here.
//
// We must set `tracked = true` on each notification, otherwise the server
// discards it as soon as onNotification returns — and with it the image data
// (e.g. a profile picture, served via an internal image provider), which would
// then fail to load. We keep tracked objects alive until the popup that
// displays them retracts, at which point BarState calls release().
//
// Shape note: Discord pre-masks the avatar it sends into a CIRCLE (transparent
// corners), so it can only ever look right as a circle. Other apps (Spotify, …)
// send a full square. We flag Discord so the popup renders it circular and
// everything else as a rounded square.
Singleton {
    id: root

    // Emitted once per incoming notification. id is the server-assigned id used
    // later to release()/dismiss the tracked notification. circle = render the
    // avatar as a circle (Discord) rather than a rounded square.
    signal notify(int id, string app, string summary, string body, string image, bool circle)

    // Live tracked notifications, keyed by id, kept alive for their image data.
    property var tracked: ({})

    // Title-case the freedesktop app name (e.g. "discord" -> "Discord").
    function prettifyApp(name) {
        if (!name)
            return "Notification";
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    // Stop tracking a notification and tell the server it's been dismissed.
    function release(id) {
        const n = root.tracked[id];
        if (n) {
            delete root.tracked[id];
            n.dismiss();
        }
    }

    NotificationServer {
        id: server

        keepOnReload:    false
        actionsSupported: false
        bodyMarkupSupported: true
        imageSupported:  true

        onNotification: notif => {
            notif.tracked = true;
            root.tracked[notif.id] = notif;

            // Prefer the notification's own image (profile picture); fall back to
            // the app's themed icon if it provides no image.
            let img = notif.image;
            if (!img && notif.appIcon)
                img = Quickshell.iconPath(notif.appIcon, true);

            const isDiscord = (notif.appName || "").toLowerCase() === "discord";

            root.notify(notif.id,
                        root.prettifyApp(notif.appName),
                        notif.summary,
                        notif.body,
                        img || "",
                        isDiscord);
        }
    }
}
