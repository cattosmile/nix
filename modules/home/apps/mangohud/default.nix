{ ... }:

{
  programs.mangohud = {
    enable = true;
    settings = {
      table_columns = 3;
      round_corners = 5;
      background_alpha = "0.4";
      alpha = "1.0";
      font_size = 24;
      text_color = "FFFFFF";
      position = "top-left";

      gpu_text = "GPU";
      gpu_stats = true;
      gpu_temp = true;
      gpu_power = true;

      cpu_text = "CPU";
      cpu_stats = true;
      cpu_temp = true;

      ram = true;
      vram = true;

      fps = true;
      frametime = true;
      frame_timing = true;

      toggle_fps_limit = "Shift_L+F1";
      fps_limit = [
        240
        144
        90
        60
        0
      ];

      gamemode = true;
      resolution = true;

      toggle_hud = "Shift_R+F12";
      no_display = true;
    };
  };
}
