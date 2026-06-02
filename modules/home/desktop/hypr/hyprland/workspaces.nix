{ lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    workspace_rule = [
      {
        workspace = "10";
        monitor = "DP-2";
        persistent = true;
        gaps_in = 0;
        gaps_out = 0;
        no_border = true;
        no_rounding = true;
        decorate = false;
      }
    ]
    ++ (map (i: {
      workspace = toString i;
      monitor = "DP-1";
      default = i == 1;
    }) (
      lib.range 1 9
    ));
  };
}
