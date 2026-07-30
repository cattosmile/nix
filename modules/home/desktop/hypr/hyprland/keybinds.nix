{
  hyprMonitors,
  inputs,
  lib,
  pkgs,
  ...
}:

# let
#   gameModeKill = pkgs.writeShellScriptBin "gamemode-kill" ''
#     #!/usr/bin/env bash
#
#     HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
#     JQ="${pkgs.jq}/bin/jq"
#
#     ACTIVE=$($HYPRCTL activewindow -j)
#     CLASS=$(echo "$ACTIVE" | $JQ -r ".class")
#     PID=$(echo "$ACTIVE" | $JQ -r ".pid")
#
#     if [ "$CLASS" == "gamescope" ]; then
#         kill -9 "$PID"
#         pkill -f wineserver
#     else
#         $HYPRCTL dispatch killactive ""
#     fi
#   '';
# in

let
  alacritty = lib.getExe pkgs.alacritty;
  grim = lib.getExe pkgs.grim;
  nemo = lib.getExe pkgs.nemo-with-extensions;
  rice = import ../../quickshell/package.nix {
    inherit inputs lib pkgs;
  };
  quickshellLauncherToggle = lib.escapeShellArgs [
    (lib.getExe rice.ipc)
    "call"
    "launcher"
    "toggle"
  ];
  quickshellReload = lib.getExe rice.reload;
  slurp = lib.getExe pkgs.slurp;
  swappy = lib.getExe pkgs.swappy;
  wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
  wlPaste = lib.getExe' pkgs.wl-clipboard "wl-paste";
in

{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Screenshots
      {
        _args = [
          "SUPER + SHIFT + S"
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd([[${grim} -g "$(${slurp} -w 0)" - | ${wlCopy}]])'')
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + E"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd([[${wlPaste} | ${swappy} -f -]])")
        ];
      }

      # Programs
      {
        _args = [
          "SUPER + RETURN"
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${alacritty} --title alacritty_float")'')
        ];
      }
      {
        _args = [
          "SUPER + E"
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("${nemo}", { float = true, center = true, size = "1000 600", monitor = "${hyprMonitors.primary}" })'')
        ];
      }
      {
        _args = [
          "SUPER + SPACE"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd([[${quickshellLauncherToggle}]])")
        ];
      }
      {
        _args = [
          "SUPER + SHIFT + R"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd([[${quickshellReload}]])")
        ];
      }

      # Window Management
      {
        _args = [
          "SUPER + Q"
          (lib.generators.mkLuaInline "hl.dsp.window.close()")
        ];
      }
      {
        _args = [
          "SUPER + M"
          (lib.generators.mkLuaInline "hl.dsp.exit()")
        ];
      }
      {
        _args = [
          "SUPER + V"
          (lib.generators.mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'')
        ];
      }
      {
        _args = [
          "SUPER + J"
          (lib.generators.mkLuaInline ''hl.dsp.layout("togglesplit")'')
        ];
      }
      {
        _args = [
          "SUPER + F"
          (lib.generators.mkLuaInline "hl.dsp.window.fullscreen()")
        ];
      }

      {
        _args = [
          "SUPER + left"
          (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "left" })'')
        ];
      }
      {
        _args = [
          "SUPER + right"
          (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "right" })'')
        ];
      }
      {
        _args = [
          "SUPER + up"
          (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "up" })'')
        ];
      }
      {
        _args = [
          "SUPER + down"
          (lib.generators.mkLuaInline ''hl.dsp.focus({ direction = "down" })'')
        ];
      }

      # Workspaces
    ]
    ++ (lib.concatMap
      (
        i:
        let
          workspace = if i == 0 then 10 else i;
        in
        [
          {
            _args = [
              "SUPER + ${toString i}"
              (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = ${toString workspace} })")
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + ${toString i}"
              (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = ${toString workspace} })")
            ];
          }
        ]
      )
      [
        1
        2
        3
        4
        5
        6
        7
        8
        9
        0
      ]
    )
    ++ [
      # Mouse
      {
        _args = [
          "SUPER + mouse:272"
          (lib.generators.mkLuaInline "hl.dsp.window.drag()")
          { mouse = true; }
        ];
      }
      {
        _args = [
          "SUPER + mouse:273"
          (lib.generators.mkLuaInline "hl.dsp.window.resize()")
          { mouse = true; }
        ];
      }
    ];
  };
}
