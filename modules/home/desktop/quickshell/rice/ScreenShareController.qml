pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property bool obsActive: false
    readonly property bool portalActive:
        Pipewire.linkGroups.values.some(group =>
            root.isActivePortalShare(group))
    readonly property bool active: obsActive || portalActive

    function nodeProperty(node, name) {
        return String(node?.properties?.[name] ?? "").toLowerCase();
    }

    function nodeIdentity(node) {
        return [
            node?.name ?? "",
            node?.description ?? "",
            nodeProperty(node, "application.name"),
            nodeProperty(node, "application.process.binary"),
            nodeProperty(node, "media.name"),
            nodeProperty(node, "node.name")
        ].join(" ").toLowerCase();
    }

    function isPortalSource(node) {
        const identity = nodeIdentity(node);

        return identity.includes("xdph-streaming")
            || identity.includes("xdg-desktop-portal");
    }

    function isObsNode(node) {
        const identities = [
            String(node?.name ?? "").toLowerCase(),
            String(node?.description ?? "").toLowerCase(),
            nodeProperty(node, "application.name"),
            nodeProperty(node, "application.process.binary"),
            nodeProperty(node, "media.name"),
            nodeProperty(node, "node.name")
        ];

        return identities.some(identity =>
            identity === "obs"
            || identity === "obs studio"
            || identity.includes(".obs-wrapped"));
    }

    function isActivePortalShare(group) {
        if (group === null || group === undefined)
            return false;

        return isPortalSource(group.source)
            && !isObsNode(group.target);
    }

    function updateObsStatus(rawLine) {
        try {
            const status = JSON.parse(rawLine);
            obsActive = status.active === true;
        } catch (error) {
            obsActive = false;
        }
    }

    Component.onCompleted: obsStatusProcess.running = true

    Process {
        id: obsStatusProcess

        command: [
            "node",
            Quickshell.shellPath("scripts/obs-output-status.mjs")
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.updateObsStatus(data)
        }

        stderr: StdioCollector {}

        onExited: {
            root.obsActive = false;
            obsProcessRestartTimer.restart();
        }
    }

    Timer {
        id: obsProcessRestartTimer

        interval: 3000
        onTriggered: obsStatusProcess.running = true
    }

}
