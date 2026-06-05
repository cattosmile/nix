{ hyprMonitors, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = hyprMonitors.primary;
        mode = "3840x2160@144";
        position = "0x0";
        scale = 1.5;
      }
      {
        output = hyprMonitors.secondary;
        mode = "1920x1080@240";
        position = "-1080x0";
        scale = 1;
        transform = 1;
      }
      {
        output = hyprMonitors.disabled;
        disabled = true;
      }
    ];

    config.xwayland = {
      force_zero_scaling = true;
    };
  };
}
