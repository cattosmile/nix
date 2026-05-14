{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unzip
    unrar
    btop
    curl
    wget
  ];
}
