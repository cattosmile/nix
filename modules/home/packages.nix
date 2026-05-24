{ pkgs, unstable, ... }:

{
  home.packages = with pkgs; [
    nano
  ];
}
