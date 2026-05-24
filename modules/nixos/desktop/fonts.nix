{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
    iosevka-bin
    nerd-fonts.iosevka-term
  ];
}
