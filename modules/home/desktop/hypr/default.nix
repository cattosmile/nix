{ ... }:

{
  _module.args.hyprMonitors = {
    primary = "DP-1";
    secondary = "DP-2";
    disabled = "HDMI-A-2";
  };

  imports = [
    ./hyprpaper
    ./hyprland
  ];
}
