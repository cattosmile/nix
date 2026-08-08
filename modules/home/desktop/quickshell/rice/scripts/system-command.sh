#!/usr/bin/env bash

set -eu

command_name="${1:-}"

# This is intentionally a fixed whitelist.  The launcher passes only one of
# these values, so typing arbitrary shell syntax can never reach a shell.
case "$command_name" in
    shutdown)
        # systemctl requests a normal, coordinated shutdown and lets the
        # session and applications close through their regular shutdown hooks.
        exec systemctl poweroff
        ;;
    reboot)
        exec systemctl reboot
        ;;
    logout)
        # Exiting the compositor returns the Wayland session to its display
        # manager without terminating unrelated system services.
        exec hyprctl dispatch exit
        ;;
    *)
        printf 'Unknown system command\n' >&2
        exit 2
        ;;
esac
