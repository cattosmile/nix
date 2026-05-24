{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    package = pkgs.steam.override {
      extraPkgs =
        pkgs': with pkgs'; [
          libkrb5
          keyutils
        ];
    };
  };

  hardware.steam-hardware.enable = true;
}
