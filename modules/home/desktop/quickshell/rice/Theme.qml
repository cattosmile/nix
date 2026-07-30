pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Change only this value to switch the complete shell palette.
    property string activeTheme: "midnight"

    readonly property var palettes: ({
        "midnight": {
            frame: "#000000",
            workspaceIsland: "#202022",
            workspaceInactive: "#4b4b4e",
            workspaceOccupied: "#7a7a80",
            workspaceActive: "#ffffff",
            quickActionsIsland: "#202022",
            quickActionInactive: "#4b4b4e",
            quickActionActive: "#ffffff",
            audioIsland: "#202022",
            audioTrackInactive: "#4b4b4e",
            audioTrackActive: "#ffffff",
            audioTrackMuted: "#66666a",
            trayIsland: "#202022",
            powerIcon: "#ffffff",
            clockIsland: "#202022",
            clockTime: "#ffffff",
            clockDivider: "#4b4b4e",
            trayMenuText: "#f2f2f4",
            trayMenuMuted: "#929299",
            trayMenuHover: "#303034",
            trayMenuSeparator: "#3a3a3f",
            trayMenuCheck: "#ffffff",
            launcherField: "#202022",
            launcherPlaceholder: "#929299",
            launcherText: "#f2f2f4",
            launcherResultHover: "#303034",
            launcherSelection: "#4b4b4e",
            launcherSelectedText: "#ffffff",
            notificationIconBackground: "#202022",
            notificationText: "#ffffff",
            notificationBody: "#d7d7dc",
            notificationPrivacyAvatar: "#5865f2",
            notificationPrivacyLogo: "#ffffff",
            transparent: "transparent"
        },
        "light": {
            frame: "#eeeef1",
            workspaceIsland: "#ffffff",
            workspaceInactive: "#b2b2b8",
            workspaceOccupied: "#85858d",
            workspaceActive: "#202024",
            quickActionsIsland: "#ffffff",
            quickActionInactive: "#b2b2b8",
            quickActionActive: "#202024",
            audioIsland: "#ffffff",
            audioTrackInactive: "#b2b2b8",
            audioTrackActive: "#202024",
            audioTrackMuted: "#8f8f97",
            trayIsland: "#ffffff",
            powerIcon: "#202024",
            clockIsland: "#ffffff",
            clockTime: "#202024",
            clockDivider: "#b2b2b8",
            trayMenuText: "#202024",
            trayMenuMuted: "#777780",
            trayMenuHover: "#ededf1",
            trayMenuSeparator: "#d8d8de",
            trayMenuCheck: "#202024",
            launcherField: "#ffffff",
            launcherPlaceholder: "#777780",
            launcherText: "#202024",
            launcherResultHover: "#ededf1",
            launcherSelection: "#b2b2b8",
            launcherSelectedText: "#202024",
            notificationIconBackground: "#ededf1",
            notificationText: "#202024",
            notificationBody: "#4d4d55",
            notificationPrivacyAvatar: "#5865f2",
            notificationPrivacyLogo: "#ffffff",
            transparent: "transparent"
        }
    })

    readonly property var palette: palettes[activeTheme] ?? palettes.midnight

    readonly property color frame: palette.frame
    readonly property color workspaceIsland: palette.workspaceIsland
    readonly property color workspaceInactive: palette.workspaceInactive
    readonly property color workspaceOccupied: palette.workspaceOccupied
    readonly property color workspaceActive: palette.workspaceActive
    readonly property color quickActionsIsland: palette.quickActionsIsland
    readonly property color quickActionInactive: palette.quickActionInactive
    readonly property color quickActionActive: palette.quickActionActive
    readonly property color audioIsland: palette.audioIsland
    readonly property color audioTrackInactive: palette.audioTrackInactive
    readonly property color audioTrackActive: palette.audioTrackActive
    readonly property color audioTrackMuted: palette.audioTrackMuted
    readonly property color trayIsland: palette.trayIsland
    readonly property color powerIcon: palette.powerIcon
    readonly property color clockIsland: palette.clockIsland
    readonly property color clockTime: palette.clockTime
    readonly property color clockDivider: palette.clockDivider
    readonly property color trayMenuSurface: frame
    readonly property color trayMenuText: palette.trayMenuText
    readonly property color trayMenuMuted: palette.trayMenuMuted
    readonly property color trayMenuHover: palette.trayMenuHover
    readonly property color trayMenuSeparator: palette.trayMenuSeparator
    readonly property color trayMenuCheck: palette.trayMenuCheck
    readonly property color launcherSurface: frame
    readonly property color launcherField: palette.launcherField
    readonly property color launcherPlaceholder: palette.launcherPlaceholder
    readonly property color launcherText: palette.launcherText
    readonly property color launcherResultHover: palette.launcherResultHover
    readonly property color launcherSelection: palette.launcherSelection
    readonly property color launcherSelectedText: palette.launcherSelectedText
    readonly property color notificationSurface: frame
    readonly property color notificationIconBackground:
        palette.notificationIconBackground
    readonly property color notificationText: palette.notificationText
    readonly property color notificationBody: palette.notificationBody
    readonly property color notificationPrivacyAvatar:
        palette.notificationPrivacyAvatar
    readonly property color notificationPrivacyLogo:
        palette.notificationPrivacyLogo
    readonly property color transparent: palette.transparent
}
