{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1, 3840x2160@144, 0x0, 1.5"
      "DP-2, 1920x1080@240, -1080x0, 1, transform, 1"
    ];

    xwayland = {
      force_zero_scaling = true;
    };
  };
}
