{ ... }:

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

{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";

    bind = [
      # Screenshots
      "$mainMod SHIFT, S, exec, grim -g \"\$(slurp -w 0)\" - | wl-copy"
      "$mainMod SHIFT, E, exec, wl-paste | swappy -f -"

      # Programs
      "$mainMod, RETURN, exec, $terminal"
      "$mainMod, E, exec, [float;center;size 1000 600;monitor DP-1] $fileManager"
      "$mainMod, SPACE, exec, $menu"

      # Window Management
      "$mainMod, Q, killactive,"
      "$mainMod, M, exit"
      "$mainMod, V, togglefloating,"
      "$mainMod, J, layoutmsg, togglesplit"
      "$mainMod, F, fullscreen,"

      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Workspaces
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"

      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"
    ];

    bindm = [
      # Mouse
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];
  };
}
