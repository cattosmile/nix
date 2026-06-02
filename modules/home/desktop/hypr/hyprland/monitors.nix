{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "DP-1";
        mode = "3840x2160@144";
        position = "0x0";
        scale = 1.5;
      }
      {
        output = "DP-2";
        mode = "1920x1080@240";
        position = "-1080x0";
        scale = 1;
        transform = 1;
      }
      {
        output = "HDMI-A-2";
        disabled = true;
      }
    ];

    config.xwayland = {
      force_zero_scaling = true;
    };
  };
}
