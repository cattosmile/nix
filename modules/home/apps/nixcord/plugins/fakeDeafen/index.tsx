/*
 * Vencord, a Discord client mod
 * Copyright (c) 2026 Equicord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Equicord user plugin

import type { NavContextMenuPatchCallback } from "@api/ContextMenu";
import { definePluginSettings } from "@api/Settings";
import definePlugin, { OptionType } from "@utils/types";
import { findByPropsLazy } from "@webpack";
import { Menu } from "@webpack/common";

const { toggleSelfMute } = findByPropsLazy("toggleSelfMute");
const { toggleSelfDeaf } = findByPropsLazy("toggleSelfDeaf");
const settings = definePluginSettings({
    enableFakeDeafen: {
        description: "Enable or disable fake deafen.",
        type: OptionType.BOOLEAN,
        default: true,
        onChange: () => { try { applyFakeDeaf(); } catch { } },
    },
    enableFakeMute: {
        description: "Enable or disable fake mute.",
        type: OptionType.BOOLEAN,
        default: true,
        onChange: () => { try { applyFakeMute(); } catch { } },
    },
});

function applyFakeDeaf() {
    toggleSelfDeaf();
    toggleSelfDeaf();
}

function applyFakeMute() {
    toggleSelfMute();
    toggleSelfMute();
}

function containsMenuItem(node: any, id: string): boolean {
    if (!node) return false;
    if (Array.isArray(node)) return node.some(child => containsMenuItem(child, id));
    if (node.props?.id === id) return true;
    return containsMenuItem(node.props?.children, id);
}

const AudioDeviceContextMenuPatch: NavContextMenuPatchCallback = children => {
    const {
        enableFakeDeafen,
        enableFakeMute
    } = settings.use([
        "enableFakeDeafen",
        "enableFakeMute"
    ]);
    const statesGroup = (
        <Menu.MenuGroup>
            <Menu.MenuItem id="fake-deafen-states" label="States">
                <Menu.MenuCheckboxItem
                    id="fake-deafen"
                    label="Fake Deafen"
                    checked={!enableFakeDeafen}
                    action={() => settings.store.enableFakeDeafen = !enableFakeDeafen}
                />
                <Menu.MenuCheckboxItem
                    id="fake-mute"
                    label="Fake Mute"
                    checked={!enableFakeMute}
                    action={() => settings.store.enableFakeMute = !enableFakeMute}
                />
            </Menu.MenuItem>
        </Menu.MenuGroup>
    );
    const voiceSettingsIndex = children.findIndex(child => containsMenuItem(child, "voice-settings"));

    children.splice(
        voiceSettingsIndex >= 0 ? voiceSettingsIndex : Math.max(0, children.length - 1),
        0,
        statesGroup
    );
};

export default definePlugin({
    name: "FakeDeafen",
    description: "Equicord user plugin for fake deafen and mute.",
    authors: [],
    tags: ["Voice", "Utility"],
    settings,

    contextMenus: {
        "audio-device-context": AudioDeviceContextMenuPatch,
    },

    state: (type: string, real: boolean) => {
        if (type === "mute" && !settings.store.enableFakeMute) return true;
        if (type === "deafen" && !settings.store.enableFakeDeafen) return true;
        return real;
    },

    patches: [
        {
            find: "}voiceStateUpdate(",
            replacement: {
                match: /self_mute:(\i),self_deaf:(\i)/,
                replace: "self_mute:$self.state('mute',$1),self_deaf:$self.state('deafen',$2)",
            }
        },
    ],
});
