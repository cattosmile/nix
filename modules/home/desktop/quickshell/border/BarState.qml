pragma ComponentBehavior: Bound
import QtQuick
import "../services"

// Per-screen shared state: one instance lives in each Border Variants delegate
// and is injected into that screen's BarWindow / BorderWindow / BorderExclusions.
// Kept off the Theme singleton so multiple monitors don't share one bar width.
QtObject {
    id: barState

    // Visible bar width, tracked every frame by the border hole.
    property real activeBarWidth: Theme.barWidth
    // Committed once per toggle so Hyprland reflows the layout a single time.
    property real exclusionBarWidth: Theme.barWidth

    // Active notification stack. CenterPopup renders one block per entry at the
    // same position (newest drawn on top) and removes it once its auto-retract
    // finishes. notifId is a stable key so a block can remove itself by id
    // regardless of its index.
    property int notifSeq: 0
    property ListModel notifications: ListModel {}

    // Forward every incoming libnotify notification onto the stack.
    property Connections notifConn: Connections {
        target: Notifs
        function onNotify(id, app, summary, body, image, circle) {
            barState.pushNotification(id, app, summary, body, image, circle);
        }
    }

    // srvId is the server-side notification id so a block can release the tracked
    // notification when it retracts; notifId is our own stable per-block key for
    // the model/animations. circle renders the avatar as a circle (Discord)
    // instead of a rounded square.
    function pushNotification(srvId, app, username, preview, image, circle) {
        notifications.append({
            notifId:  barState.notifSeq++,
            srvId:    srvId === undefined ? -1 : srvId,
            app:      app      || "Notification",
            username: username || "",
            preview:  preview  || "",
            image:    image    || "",
            circle:   circle   === true
        })
    }

    function removeNotification(id) {
        for (let i = 0; i < notifications.count; i++) {
            if (notifications.get(i).notifId === id) {
                const srv = notifications.get(i).srvId;
                if (srv >= 0)
                    Notifs.release(srv);
                notifications.remove(i)
                return
            }
        }
    }
}
