{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "de";
      follow_mouse = 1;
      sensitivity = -0.3333; # For 1.5 Scaling
      # sensitivity = 0; # For 1 Scaling
      accel_profile = "flat";

      repeat_rate = 35;
      repeat_delay = 200;
    };

    cursor = {
      inactive_timeout = 30;
      no_hardware_cursors = 1;
      hotspot_padding = 0;
    };
  };
}
