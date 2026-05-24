{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Hyprland Ecosystem
    hyprpicker
    # hypridle
    # hyprlock
    hyprsunset
    # hyprsysteminfo
    hyprpolkitagent
    hyprland-qt-support
  ];
}
