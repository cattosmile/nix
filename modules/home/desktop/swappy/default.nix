{ pkgs, ... }:

{
  programs.swappy = {
    enable = true;
    settings = {
      Default = {
        auto_save = false;
        custom_color = "rgba(193,125,17,1)";
        early_exit = true;
        fill_shape = false;
        line_size = 5;
        paint_mode = "brush";
        save_dir = "$HOME/Clips/Screenshots";
        save_filename_format = "Screenshot-%d.%m.%Y-%H:%M:%S.png";
        show_panel = false;
        text_font = "sans-serif";
        text_size = 20;
        transparency = 50;
        transparent = false;
      };
    };
  };

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
  ];

}
