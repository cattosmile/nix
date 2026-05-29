{ pkgs, unstable, ... }:

{
  home.packages = with pkgs; [
    nano
    nemo-with-extensions
  ];
}
