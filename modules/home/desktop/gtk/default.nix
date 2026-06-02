{ config, pkgs, ... }:

let
  patchedTokyonight = pkgs.tokyonight-gtk-theme.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      find $out/share/themes -name "*.css" -exec sed -i '/border-spacing:/d' {} +
    '';
  });
in

{
  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = patchedTokyonight;
    };
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
}
