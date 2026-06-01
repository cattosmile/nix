{ ... }:

{
  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };
}

# Gamescope Presets:
# 1080p:
# SDL_VIDEODRIVER=x11 gamemoderun gamescope -W 1920 -H 1080 -r 144 --expose-wayland --backend sdl --immediate-flips --rt --force-grab-cursor -- mangohud %command%
# 1440p:
# SDL_VIDEODRIVER=x11 gamemoderun gamescope -W 2560 -H 1440 -r 144 --expose-wayland --backend sdl --immediate-flips --rt --force-grab-cursor -- mangohud %command%
# 2160p:
# SDL_VIDEODRIVER=x11 gamemoderun gamescope -W 3840 -H 2160 -r 144 --expose-wayland --backend sdl --immediate-flips --rt --force-grab-cursor -- mangohud %command%
#
# Geometry Dash
# SDL_VIDEODRIVER=x11 WINEDLLOVERRIDES="xinput1_4=n,b" gamemoderun gamescope -W 3840 -H 2160 -r 144 --expose-wayland --backend sdl --immediate-flips --rt --force-grab-cursor -- mangohud %command%
#
# Experimenmtal
# --immediate-flips --rt
#
# Online Fix
# WINEDLLOVERRIDES="OnlineFix64=n;SteamOverlay64=n;winmm=n,b;dnet=n;steam_api64=n;winhttp=n,b" SDL_VIDEODRIVER=x11 gamemoderun gamescope -W 3840 -H 2160 -r 144 --expose-wayland --backend sdl --immediate-flips --rt -- mangohud %command%
#
# Mangohud Toggle:
# Right SHIFT + F12
# Mangohud config in home.nix
