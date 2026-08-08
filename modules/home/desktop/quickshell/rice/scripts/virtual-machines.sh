#!/usr/bin/env bash

set -u

connection='qemu:///system'

# virt-manager does not render its VM status icons from the package PNGs
# directly.  Its Gtk.CellRendererPixbuf resolves the names state_running,
# state_paused, and state_shutoff through the active GTK icon theme.  Resolve
# that same theme here so the launcher uses the exact Papirus-Dark artwork
# shown by Virtual Machine Manager instead of a visually different fallback.
icon_theme_name="${GTK_ICON_THEME:-}"
for gtk_settings_file in \
    "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"; do
    [ -n "$icon_theme_name" ] && break
    [ -f "$gtk_settings_file" ] || continue
    icon_theme_name="$(sed -n \
        's/^[[:space:]]*gtk-icon-theme-name[[:space:]]*=[[:space:]]*//p' \
        "$gtk_settings_file" | head -n 1)"
done
icon_theme_name="${icon_theme_name%\"}"
icon_theme_name="${icon_theme_name#\"}"
[ -n "$icon_theme_name" ] || icon_theme_name='Papirus-Dark'

icon_theme_dir=""
icon_data_dirs=("${XDG_DATA_HOME:-$HOME/.local/share}")
if [ -n "${XDG_DATA_DIRS:-}" ]; then
    IFS=: read -r -a xdg_data_dirs <<< "$XDG_DATA_DIRS"
    icon_data_dirs+=("${xdg_data_dirs[@]}")
fi

# Gtk.IconSize.DND is 32 logical pixels.  Prefer that directory, while
# accepting the neighbouring theme sizes used by some icon installations.
for icon_data_dir in "${icon_data_dirs[@]}"; do
    [ -n "$icon_data_dir" ] || continue
    for icon_size_dir in 32x32 32x32@2x 24x24 24x24@2x 48x48 48x48@2x; do
        candidate_icon_dir="$icon_data_dir/icons/$icon_theme_name/$icon_size_dir/status"
        if [ -f "$candidate_icon_dir/state_shutoff.svg" ]; then
            icon_theme_dir="$candidate_icon_dir"
            break 2
        fi
    done
done

state_icon_name() {
    local normalized_state

    normalized_state="$(printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | tr -d '[:space:]')"

    case "$normalized_state" in
        running|blocked|nostate)
            printf '%s' 'state_running.svg'
            ;;
        paused|pmsuspended)
            printf '%s' 'state_paused.svg'
            ;;
        *)
            printf '%s' 'state_shutoff.svg'
            ;;
    esac
}

state_icon_path() {
    local state="$1"
    local icon_name
    local icon_path

    [ -n "$icon_theme_dir" ] || return 0

    icon_name="$(state_icon_name "$state")"
    icon_path="$icon_theme_dir/$icon_name"
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
