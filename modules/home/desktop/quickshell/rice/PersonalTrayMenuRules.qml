pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Personal root-menu policy. Application submenus are intentionally left
    // untouched so their app-provided navigation and actions keep working.
    readonly property var rules: ({
        discord: {
            remove: [ "discord" ],
            removeSeparatorAfter: [ "discord" ]
        },
        chatgpt: {
            remove: [ "build information", "recent", "more" ],
            removeSeparatorAfter: [ "build information" ]
        },
        easyeffects: {
            remove: [ "manual" ],
            removeSeparatorAfter: [ "input presets" ]
        },
        obs: {
            remove: [ "start virtual camera" ],
            removeSeparatorAfter: []
        },
        steam: {
            remove: [ "steamvr", "big picture" ],
            removeSeparatorAfter: []
        },
        vlc: {
            remove: [
                "hide vlc media player in taskbar",
                "open media",
                "record"
            ],
            removeSeparatorAfter: [
                "hide vlc media player in taskbar",
                "speed"
            ]
        }
    })

    readonly property var displayNames: ({
        spotify: "Spotify",
        telegram: "Telegram",
        vlc: "VLC"
    })

    function normalized(value) {
        return String(value ?? "")
            .toLowerCase()
            // D-Bus menu labels use these characters for keyboard mnemonics.
            .replace(/[_&]/g, "")
            .replace(/\s+/g, " ")
            .trim();
    }

    function applicationKey(trayItem) {
        if (!trayItem)
            return "";

        const identity = normalized([
            trayItem.id,
            trayItem.title,
            trayItem.tooltipTitle
        ].join(" "));

        if (identity.includes("discord"))
            return "discord";
        if (identity.includes("chatgpt"))
            return "chatgpt";
        if (identity.includes("easy effects")
                || identity.includes("easyeffects"))
            return "easyeffects";
        if (identity.includes("obs"))
            return "obs";
        if (identity.includes("steam"))
            return "steam";
        if (identity.includes("vlc"))
            return "vlc";
        if (identity.includes("spotify"))
            return "spotify";
        if (identity.includes("telegram"))
            return "telegram";

        return "";
    }

    function displayTitle(trayItem, fallbackTitle) {
        const renamed = displayNames[applicationKey(trayItem)];
        return renamed ?? fallbackTitle;
    }

    function containsLabel(labels, label) {
        return labels.indexOf(label) !== -1;
    }

    function obsSaveReplayEntry() {
        return {
            text: "Save Replay",
            enabled: true,
            isSeparator: false,
            hasChildren: false,
            buttonType: QsMenuButtonType.None,
            checkState: Qt.Unchecked,
            closeOnTrigger: false,
            triggered: function() {
                ObsReplayController.saveReplay();
            }
        };
    }

    function separatorEntry() {
        return {
            text: "",
            enabled: true,
            isSeparator: true,
            hasChildren: false,
            buttonType: QsMenuButtonType.None,
            checkState: Qt.Unchecked
        };
    }

    function orderedObsEntries(source) {
        let recording = null;
        let replayBuffer = null;
        let previewProjector = null;
        let programProjector = null;
        let visibility = null;
        let exit = null;

        for (let index = 0; index < source.length; ++index) {
            const entry = source[index];
            if (entry.isSeparator)
                continue;

            const label = normalized(entry.text);

            if (label === "start recording" || label === "stop recording")
                recording = entry;
            else if (label === "start replay buffer"
                    || label === "stop replay buffer")
                replayBuffer = entry;
            else if (label === "open preview projector")
                previewProjector = entry;
            else if (label === "open program projector")
                programProjector = entry;
            else if (label === "show" || label === "hide")
                visibility = entry;
            else if (label === "exit")
                exit = entry;
        }

        const groups = [
            [ recording ],
            [ replayBuffer, replayBuffer ? obsSaveReplayEntry() : null ],
            [ previewProjector, programProjector ],
            [ visibility, exit ]
        ];
        const ordered = [];

        for (let groupIndex = 0; groupIndex < groups.length; ++groupIndex) {
            const group = groups[groupIndex].filter(entry => entry !== null);
            if (group.length === 0)
                continue;

            if (ordered.length > 0)
                ordered.push(separatorEntry());

            ordered.push(...group);
        }

        return ordered;
    }

    function withoutSteamGames(source) {
        const storeIndex = source.findIndex(
            entry => !entry.isSeparator
                && normalized(entry.text) === "store"
        );

        // Steam publishes all recent games before its stable Store entry.
        // Keeping Store and everything after it removes the complete dynamic
        // games section without depending on any current or future game name.
        return storeIndex > 0 ? source.slice(storeIndex) : source;
    }

    function withEasyEffectsActiveFirst(source) {
        const activeIndex = source.findIndex(
            entry => !entry.isSeparator
                && normalized(entry.text) === "active"
        );
        if (activeIndex <= 0)
            return source;

        const activeEntry = source[activeIndex];
        const remaining = source.filter((entry, index) => {
            if (index === activeIndex)
                return false;

            // Remove the old category dividers immediately around Active.
            if (entry.isSeparator
                    && (index === activeIndex - 1
                        || index === activeIndex + 1)) {
                return false;
            }

            return true;
        });

        while (remaining.length > 0 && remaining[0].isSeparator)
            remaining.shift();

        return [ activeEntry, separatorEntry(), ...remaining ];
    }

    function filterRootEntries(trayItem, stackDepth, entries) {
        let source = entries ?? [];

        if (stackDepth !== 0)
            return source;

        const appKey = applicationKey(trayItem);
        if (appKey === "obs")
            return orderedObsEntries(source);
        if (appKey === "steam")
            source = withoutSteamGames(source);

        const rule = rules[appKey];
        if (!rule)
            return source;

        const filtered = [];
        let removeFollowingSeparators = false;

        for (let index = 0; index < source.length; ++index) {
            const entry = source[index];

            if (entry.isSeparator) {
                if (removeFollowingSeparators)
                    continue;

                filtered.push(entry);
                continue;
            }

            // "After" covers only the directly adjacent separator run. A
            // later category separator must never disappear because an app
            // reordered unrelated items. VLC currently publishes two
            // consecutive separators after Speed.
            removeFollowingSeparators = false;

            const label = normalized(entry.text);
            const removeEntry = containsLabel(rule.remove, label);
            const removeFollowingSeparator = containsLabel(
                rule.removeSeparatorAfter,
                label
            );

            if (!removeEntry) {
                filtered.push(entry);
            }

            if (removeFollowingSeparator)
                removeFollowingSeparators = true;
        }

        return appKey === "easyeffects"
            ? withEasyEffectsActiveFirst(filtered)
            : filtered;
    }
}
