{ config, ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd([[dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP]])
      hl.exec_cmd([[systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP]])
      hl.exec_cmd([[systemctl --user start hyprpolkitagent]])
      hl.exec_cmd([[quickshell]])
      hl.exec_cmd([[dunst]])
      hl.exec_cmd([[hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}]])
      hl.exec_cmd([[systemctl --user restart pipewire wireplumber pipewire-pulse]])
    end)
  '';
}
