{ config, ... }:

{
  wayland.windowManager.hyprland.settings = {
    env = [

      # Cursor
      "XCURSOR_THEME,${config.home.pointerCursor.name}"
      "XCURSOR_SIZE,${toString config.home.pointerCursor.size}"
      "HYPRCURSOR_SIZE,${toString config.home.pointerCursor.size}"

      # Prefer GPU (not needed since isolated via VFIO)
      # "AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1"

      # Toolkit Backend Variables
      "GDK_BACKEND,wayland,x11,*" # GTK prefer Wayland
      "QT_QPA_PLATFORM,wayland;xcb" # QT prefer Wayland
      "SDL_VIDEODRIVER,wayland" # SDL2 on Wayland
      "CLUTTER_BACKEND,wayland" # Clutter prefer Wayland

      # XDG Specifications
      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
      "XDG_SESSION_DESKTOP,Hyprland"

      # QT Variables
      "QT_AUTO_SCREEN_SCALE_FACTOR,1"
      # "QT_QPA_PLATFORMTHEME,qt5ct" # Tell QT Apps to use theme from qt5c/Kvantum

      # GTK
      # "GTK_THEME=Tokyonight"
    ];
  };
}
