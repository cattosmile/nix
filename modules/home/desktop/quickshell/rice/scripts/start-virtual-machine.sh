#!/usr/bin/env bash

set -u

connection='qemu:///system'
vm_name="${1:-}"

case "$vm_name" in
    ''|*[!a-zA-Z0-9._-]*)
        printf 'Invalid virtual machine name\n' >&2
        exit 2
        ;;
esac

state="$(virsh -c "$connection" domstate "$vm_name" 2>/dev/null \
    | head -n 1 | sed 's/[[:space:]]*$//')"

case "$state" in
    running|paused)
        ;;
    *)
        virsh -c "$connection" start "$vm_name" >/dev/null
        ;;
esac

# Looking Glass belongs on the first workspace. Its -F option makes the
# client itself fullscreen; launching it after the workspace dispatch lets
# Hyprland focus the new client there without moving the pointer.
# Hyprland 0.56's hyprctl dispatch accepts the Lua dispatcher form.
hyprctl dispatch 'hl.dsp.focus({ workspace = "1" })' >/dev/null 2>&1 || true
exec looking-glass-client -F
