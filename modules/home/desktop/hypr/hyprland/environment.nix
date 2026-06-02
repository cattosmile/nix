{ config, ... }:

{
  wayland.windowManager.hyprland.settings = {
    env = [

      # Cursor
      { _args = [ "XCURSOR_THEME" config.home.pointerCursor.name ]; }
      { _args = [ "XCURSOR_SIZE" (toString config.home.pointerCursor.size) ]; }
      { _args = [ "HYPRCURSOR_SIZE" (toString config.home.pointerCursor.size) ]; }

      # Prefer GPU (not needed since isolated via VFIO)
      # "AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1"

      # Toolkit Backend Variables
      { _args = [ "GDK_BACKEND" "wayland,x11,*" ]; } # GTK prefer Wayland
      { _args = [ "QT_QPA_PLATFORM" "wayland;xcb" ]; } # QT prefer Wayland
      { _args = [ "SDL_VIDEODRIVER" "wayland" ]; } # SDL2 on Wayland
      { _args = [ "CLUTTER_BACKEND" "wayland" ]; } # Clutter prefer Wayland

      # XDG Specifications
      { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
      { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
      { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }

      # QT Variables
      { _args = [ "QT_AUTO_SCREEN_SCALE_FACTOR" "1" ]; }
      # "QT_QPA_PLATFORMTHEME,qt5ct" # Tell QT Apps to use theme from qt5c/Kvantum

      # GTK
      # "GTK_THEME=Tokyonight"
    ];
  };
}
