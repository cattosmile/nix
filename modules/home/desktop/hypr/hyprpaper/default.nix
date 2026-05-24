{ inputs, pkgs, ... }:

let
  wallpaper1 = ../../../../../assets/walls/tracker.jpg;
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
          monitor = "DP-1";
          path = "${wallpaper1}";
        }
        {
          monitor = "DP-2";
          path = "${wallpaper2}";
        }
      ];
    };
  };
}
