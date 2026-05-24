{ pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ./decoration.nix
    ./inputs.nix
    ./monitors.nix
    ./keybinds.nix
    ./environment.nix
    ./variables.nix
    ./autostart.nix
    ./misc.nix
    ./workspaces.nix
    ./animations.nix
    ./windowrules.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };
}
