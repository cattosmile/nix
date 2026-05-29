pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    ListModel { id: _popups }
    property alias popups: _popups

    function dismiss(index: int): void {
        if (index < 0 || index >= _popups.count) return;
        const item = _popups.get(index);
        _popups.remove(index);
        item.notification?.dismiss();
    }

    function clear(): void {
        while (_popups.count > 0) {
            const item = _popups.get(0);
            _popups.remove(0);
            item.notification?.dismiss();
        }
    }

    NotificationServer {
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: (notif) => {
            console.log("[Notifs] received:", notif.summary, notif.body);
            notif.tracked = true;
            const timeout = notif.expireTimeout > 0 ? notif.expireTimeout : 6000;
            _popups.insert(0, {
                summary: notif.summary,
                body: notif.body,
                appIcon: notif.appIcon,
                appName: notif.appName,
                image: notif.image,
                urgency: notif.urgency,
                expireTimeout: timeout,
                notification: notif
            });
        }
    }
}
