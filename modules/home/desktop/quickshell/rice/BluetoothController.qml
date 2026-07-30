pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    readonly property bool enabled:
        Bluetooth.defaultAdapter?.enabled ?? false

    function toggle() {
        const adapter = Bluetooth.defaultAdapter;

        if (adapter !== null)
            adapter.enabled = !adapter.enabled;
    }
}
