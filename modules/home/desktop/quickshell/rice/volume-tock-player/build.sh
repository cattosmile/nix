#!/usr/bin/env sh
set -eu

player_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

exec nix build \
    --impure \
    --file "$player_root/default.nix" \
    --out-link "$player_root/../.volume-tock-player"
