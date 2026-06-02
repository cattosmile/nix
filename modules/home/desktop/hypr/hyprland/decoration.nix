{ ... }:

{
  wayland.windowManager.hyprland.settings.config = {
    general = {
      gaps_in = 5;
      gaps_out = 10;
      border_size = 0;

      # "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      # "col.inactive_border" = "rgba(595959aa)";

      resize_on_border = false;
      hover_icon_on_border = false;
      extend_border_grab_area = 0;

      allow_tearing = false;
      layout = "dwindle";
    };

    decoration = {
      rounding = 20;
      # rounding_power = 0;

      active_opacity = 1.0;
      inactive_opacity = 1.0;

      shadow = {
        enabled = false;
        range = 12;
        render_power = 6;
        color = "rgba(1a1a1aee)";
      };

      blur = {
        enabled = true;
        size = 3;
        passes = 1;
        vibrancy = 0.1696;
      };
    };
  };
}
