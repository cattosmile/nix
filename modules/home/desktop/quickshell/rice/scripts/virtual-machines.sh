#!/usr/bin/env bash

set -u

connection='qemu:///system'

# Use the same state artwork that virt-manager uses in its VM list.  Resolve
# the installed package at runtime so this keeps following Nix profile
# updates, instead of relying on a stale copy of the PNGs in the shell.
virt_manager_bin="$(command -v virt-manager 2>/dev/null || true)"
virt_manager_icon_dir=""
if [ -n "$virt_manager_bin" ]; then
    virt_manager_bin="$(readlink -f "$virt_manager_bin" 2>/dev/null || true)"
    if [ -n "$virt_manager_bin" ]; then
        virt_manager_root="$(dirname "$(dirname "$virt_manager_bin")")"
        virt_manager_icon_dir="$virt_manager_root/share/virt-manager/icons/hicolor/32x32/status"
    fi
fi

state_icon_name() {
    local normalized_state

    normalized_state="$(printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | tr -d '[:space:]')"

    case "$normalized_state" in
        running|blocked|nostate)
            printf '%s' 'state_running.png'
            ;;
        paused|pmsuspended)
            printf '%s' 'state_paused.png'
            ;;
        *)
            printf '%s' 'state_shutoff.png'
            ;;
    esac
}

state_icon_path() {
    local state="$1"
    local icon_name
    local icon_path

    [ -n "$virt_manager_icon_dir" ] || return 0

    icon_name="$(state_icon_name "$state")"
    icon_path="$virt_manager_icon_dir/$icon_name"
    [ -f "$icon_path" ] || return 0
    printf '%s' "$icon_path"
}

virsh -c "$connection" list --all --name 2>/dev/null |
while IFS= read -r name; do
    [ -n "$name" ] || continue

    state="$(virsh -c "$connection" domstate "$name" 2>/dev/null \
        | head -n 1 | sed 's/[[:space:]]*$//')"
    [ -n "$state" ] || state="unknown"

    printf '%s\t%s\t%s\n' "$name" "$state" "$(state_icon_path "$state")"
done
