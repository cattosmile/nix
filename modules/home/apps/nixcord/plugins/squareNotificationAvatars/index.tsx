/*
 * Vencord, a Discord client mod
 * Copyright (c) 2026 Equicord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Equicord user plugin

import definePlugin, { PluginNative } from "@utils/types";
import { NavigationRouter } from "@webpack/common";

const Native = VencordNative.pluginHelpers
    .SquareNotificationAvatars as PluginNative<typeof import("./native")>;

let routeListenerActive = false;

async function listenForRoutes() {
    let routeState = await Native.readRouteState();

    while (routeListenerActive) {
        const nextState = await Native.waitForRoute(routeState);

        if (!routeListenerActive)
            return;

        if (nextState === routeState)
            continue;

        routeState = nextState;
        const route = nextState.split("\n", 1)[0];

        if (/^(@me|[0-9]+)\/[0-9]+$/.test(route))
            NavigationRouter.transitionTo(`/channels/${route}`);
    }
}

export default definePlugin({
    name: "SquareNotificationAvatars",
    description: "Uses square notification avatars and adds an internal channel route for the desktop shell",
    authors: [],

    patches: [
        {
            find: "\"SystemMessageUtils.stringify(...) could not convert\"",
            replacement: {
                match: /{icon:.{0,50}emoji:\i}/,
                replace: "$self.withSquareAvatar($&,...arguments)",
            },
        },
        {
            find: "Notification title contains null character",
            replacement: {
                match: /\.isUserAvatar&&null!=/,
                replace: ".isUserAvatar&&!1&&null!=",
            },
        },
    ],

    start() {
        routeListenerActive = true;
        void listenForRoutes();
    },

    stop() {
        routeListenerActive = false;
    },

    withSquareAvatar(result, channel, _message, user) {
        const avatarUrl = user?.getAvatarURL?.(
            channel?.guild_id,
            256,
            false,
            "webp"
        );

        if (avatarUrl)
            result.icon = avatarUrl;

        const channelId = channel?.id;

        if (channelId) {
            const guildId = channel?.guild_id ?? "@me";
            result.body = `${String(result.body ?? "")}\u2063qs-discord-route:${guildId}/${channelId}\u2063`;
        }

        return result;
    },
});
