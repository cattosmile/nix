{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  dbusUpdateActivationEnvironment = lib.getExe' pkgs.dbus "dbus-update-activation-environment";
  hyprctl = lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl";
  rice = import ../../quickshell/package.nix {
    inherit inputs lib pkgs;
  };
  quickshellCommand = lib.escapeShellArgs [
    (lib.getExe rice.start)
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
            hl.exec_cmd([[${dbusUpdateActivationEnvironment} --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP]])
            hl.exec_cmd([[${systemctl} --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP]])
            hl.exec_cmd([[${systemctl} --user start hyprpolkitagent]])
            hl.exec_cmd([[${quickshellCommand}]])
            hl.exec_cmd([[${hyprctl} setcursor ${cursorArgs}]])
            hl.exec_cmd([[${systemctl} --user restart pipewire wireplumber pipewire-pulse]])
          end
        '')
      ];
    }
  ];
}
