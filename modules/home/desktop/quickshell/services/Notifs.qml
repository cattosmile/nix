pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. Wraps Quickshell's NotificationServer (an implementation
// of the freedesktop Desktop Notifications spec) and exposes:
//   - `popups`: notifications currently shown as transient on-screen toasts.
//   - `list`:   every notification still tracked by the server (history).
// The toast UI lives in border/NotificationPopups.qml; each card holds a
// RetainableLock on its notification so it can play an exit animation even if
// the sending app closes the notification first.
Singleton {
    id: root

    // Active toasts, newest first. Each entry is a Notification object.
    property list<var> popups: []
    // Everything the server is still tracking, newest first (notification center).
    readonly property var list: server.trackedNotifications

    property bool dnd: false

    // Drop a toast from the on-screen stack but leave it tracked by the server
    // (so it survives in the notification history). Used on timeout / hover-out.
    function dismissPopup(notif): void {
        root.popups = root.popups.filter(n => n !== notif);
    }

    // Fully close a notification: remove the toast and hint the sending app that
    // the user explicitly dismissed it. Used on click / "X".
    function close(notif): void {
        root.popups = root.popups.filter(n => n !== notif);
        if (notif)
            notif.dismiss();
    }

    function clearAll(): void {
        root.popups = [];
        for (const notif of [...server.trackedNotifications.values])
            notif.dismiss();
    }

    NotificationServer {
        id: server

        keepOnReload:            false
        actionsSupported:        true
        actionIconsSupported:    true
        bodyHyperlinksSupported: true
        bodyImagesSupported:     true
        bodyMarkupSupported:     true
        imageSupported:          true
        persistenceSupported:    true

        onNotification: notif => {
            // Keep it alive past this signal handler so it can be tracked / shown.
            notif.tracked = true;

            if (!root.dnd)
                root.popups = [notif, ...root.popups];
        }
    }
}
