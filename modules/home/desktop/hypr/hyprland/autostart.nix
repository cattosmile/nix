{
  config,
  lib,
  pkgs,
  ...
}:

let
  dbusUpdateActivationEnvironment = lib.getExe' pkgs.dbus "dbus-update-activation-environment";
  hyprctl = lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl";
  quickshellStart = lib.escapeShellArgs [
    (lib.getExe config.programs.quickshellLive.start)
    "--daemonize"
  ];
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  cursorArgs = lib.escapeShellArgs [
    config.home.pointerCursor.name
    (toString config.home.pointerCursor.size)
  ];
in

{
  wayland.windowManager.hyprland.settings.on = [
    {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline ''
          function()
            hl.exec_cmd([[${dbusUpdateActivationEnvironment} --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP]])
            hl.exec_cmd([[${systemctl} --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP]])
            hl.exec_cmd([[${systemctl} --user start hyprpolkitagent]])
            hl.exec_cmd([[${quickshellStart}]])
            hl.exec_cmd([[${hyprctl} setcursor ${cursorArgs}]])
            hl.exec_cmd([[${systemctl} --user restart pipewire wireplumber pipewire-pulse]])
          end
        '')
      ];
    }
  ];
}
