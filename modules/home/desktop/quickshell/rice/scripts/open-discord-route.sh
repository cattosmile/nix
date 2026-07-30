#!/usr/bin/env bash

set -euo pipefail

route="${1:-}"

if [[ ! "$route" =~ ^(@me|[0-9]+)/[0-9]+$ ]]; then
    exit 2
fi

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
route_file="$runtime_dir/quickshell-discord-route"
temporary_file="$runtime_dir/.quickshell-discord-route.$$"

printf '%s\n%s\n' "$route" "$(date +%s%N)" > "$temporary_file"
mv -f -- "$temporary_file" "$route_file"
