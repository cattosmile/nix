{ ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.85;
        padding = {
          x = 17;
          y = 9;
        };
      };
      font = {
        size = 13.0;
        normal = {
          family = "Iosevka Term";
          style = "Regular";
        };
        bold = {
          family = "Iosevka Term";
          style = "Bold";
        };
        italic = {
          family = "Iosevka Term";
          style = "Italic";
        };
      };
    };
  };
}
