{
  hyprMonitors,
  inputs,
  pkgs,
  ...
}:

let
  wallpaper1 = ../../../../../assets/walls/arschlinux.png;
  wallpaper2 = ../../../../../assets/walls/black.png;
in

{
  services.hyprpaper = {
    enable = true;
    package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      ipc = "on";
      splash = false;

      preload = [
        "${wallpaper1}"
        "${wallpaper2}"
      ];

      wallpaper = [
        {
          monitor = hyprMonitors.primary;
          path = "${wallpaper1}";
        }
        {
          monitor = hyprMonitors.secondary;
          path = "${wallpaper2}";
        }
      ];
    };
  };
}
