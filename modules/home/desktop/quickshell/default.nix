{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  rice = import ./package.nix {
    inherit inputs lib pkgs;
  };
in

{
  home.packages = [
    rice.ipc
    rice.quickshell
    rice.reload
    rice.start
  ];

  xdg.configFile."quickshell/rice".source = rice.config;
}
