{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  zcode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.zcode;
  zcode-isolated = pkgs.symlinkJoin {
    name = "zcode-isolated-${lib.getVersion zcode}";

    paths = [ zcode ];
    buildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      wrapProgram "$out/bin/zcode" \
        --run 'export XDG_CONFIG_HOME="$HOME/.zcode/config"' \
        --run 'export XDG_DATA_HOME="$HOME/.zcode/data"' \
        --run 'export XDG_STATE_HOME="$HOME/.zcode/state"' \
        --run 'export XDG_CACHE_HOME="$HOME/.zcode/cache"' \
        --run 'mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"' \
        --run 'for d in gtk-3.0 gtk-4.0 fontconfig; do if [ -e "$HOME/.config/$d" ]; then ln -sfn "$HOME/.config/$d" "$XDG_CONFIG_HOME/$d"; fi; done' \
        --run 'mime_seed="$XDG_CONFIG_HOME/mimeapps.list"; { printf "[Default Applications]\n"; if [ -r "$HOME/.config/mimeapps.list" ]; then in_defs=0; while IFS= read -r line; do case "$line" in "[Default Applications]") in_defs=1 ;; \[*\)) in_defs=0 ;; *=*) if [ "$in_defs" = 1 ]; then printf "%s\n" "$line"; fi ;; esac; done < "$HOME/.config/mimeapps.list"; fi; grep -q "^x-scheme-handler/zcode=" "$HOME/.config/mimeapps.list" 2>/dev/null || printf "x-scheme-handler/zcode=zcode.desktop\n"; } > "$mime_seed"'

      # Desktop launcher must start the isolated wrapper, not the raw binary.
      for desktop in "$out/share/applications"/*.desktop; do
        [ -L "$desktop" ] || continue
        original="$(readlink -f "$desktop")"
        rm "$desktop"
        sed -E "s|^Exec=[^ ]*|Exec=$out/bin/zcode|" "$original" > "$desktop"
      done
    '';
  };
in
{
  home.packages = [ zcode-isolated ];
  xdg.mimeApps.defaultApplications."x-scheme-handler/zcode" = "zcode.desktop";

  home.file.".zcode/skills/handoff/SKILL.md".source = ./skills/handoff/SKILL.md;

  home.file.".zcode/cli/config.json".text = builtins.toJSON {
    mcp.servers.ida = {
      type = "stdio";
      command = "${pkgs.ida-mcp-server}/bin/ida-mcp-server";
      enabled = true;
      timeoutMs = 60000;
    };
    mcp.servers.slopping = {
      type = "stdio";
      command = "/run/current-system/sw/bin/nix";
      args = [
        "develop"
        "/home/user/Projects/slopping"
        "-c"
        "python3"
        "/home/user/Projects/slopping/mcp/server.py"
      ];
      enabled = true;
      timeoutMs = 60000;
    };
  };
}
