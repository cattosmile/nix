{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.quickshellLive;
  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  runtimeInputs = [
    quickshell
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.nodejs
  ];

  livePath = relativePath: lib.escapeShellArg "${cfg.root}/${relativePath}";

  start = pkgs.writeShellApplication {
    name = "quickshell-live";
    inherit runtimeInputs;
    text = ''
      exec ${livePath "run.sh"} "$@"
    '';
  };

  reload = pkgs.writeShellApplication {
    name = "quickshell-reload";
    inherit runtimeInputs;
    text = ''
      exec ${livePath "reload-live.sh"} "$@"
    '';
  };

  ipc = pkgs.writeShellApplication {
    name = "quickshell-ipc";
    inherit runtimeInputs;
    text = ''
      exec ${livePath "launcher-ipc.sh"} "$@"
    '';
  };
in

{
  options.programs.quickshellLive = {
    enable = lib.mkEnableOption "the live Quickshell integration" // {
      default = true;
    };

    root = lib.mkOption {
      type = lib.types.str;
      default = "/home/user/Projects/Quickshell";
      description = ''
        Working-tree path for the live Quickshell configuration. The wrappers reference
        this path directly and never copy the QML into the Nix store.
      '';
    };

    start = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
    };

    reload = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
    };

    ipc = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      quickshell
      start
      reload
      ipc
    ];

    programs.quickshellLive.start = start;
    programs.quickshellLive.reload = reload;
    programs.quickshellLive.ipc = ipc;
  };
}
