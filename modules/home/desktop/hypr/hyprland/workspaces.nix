{ lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    workspace = [
      "10, monitor:DP-2, persistent:true, gapsin:0, gapsout:0, border:false, rounding:false, decorate:false"
    ]
    ++ (map (i: "${toString i}, monitor:DP-1${if i == 1 then ", default:true" else ""}") (
      lib.range 1 9
    ));
  };
}
