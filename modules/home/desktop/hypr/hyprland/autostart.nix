{
  pkgs,
  inputs,
  config,
  ...
}:

{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "systemctl --user start hyprpolkitagent"
      "quickshell"
      "${inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/hyprpaper"
      "dunst"
      "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"
      "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      "systemctl --user restart pipewire wireplumber pipewire-pulse"
    ];
  };
}
