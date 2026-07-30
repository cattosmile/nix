pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    readonly property bool connected:
        Networking.devices.values.some(device =>
            device.type === DeviceType.Wired
            && device.hasLink === true
            && device.connected === true)
}
