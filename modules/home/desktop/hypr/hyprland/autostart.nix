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
  quickshellStart = lib.escapeShellArgs [
    (lib.getExe config.programs.quickshellRice.start)
    "--daemonize"
  ];
  clickAssistant = inputs.click-assistant.packages.${pkgs.stdenv.hostPlatform.system}.default;
  clickAssistantCommand = lib.escapeShellArgs [
    (lib.getExe clickAssistant)
    "--daemon"
  ];
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  cursorArgs = lib.escapeShellArgs [
    config.home.pointerCursor.name
    (toString config.home.pointerCursor.size)
  ];
in

{
  systemd.user.services.click-assistant = {
    Unit = {
      Description = "Click Assistant Wayland overlay daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = clickAssistantCommand;
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

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
            hl.exec_cmd([[${systemctl} --user start click-assistant.service]])
            hl.exec_cmd([[${hyprctl} setcursor ${cursorArgs}]])
            hl.exec_cmd([[${systemctl} --user restart pipewire wireplumber pipewire-pulse]])
          end
        '')
      ];
    }
  ];
}
