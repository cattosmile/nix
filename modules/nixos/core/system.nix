{ inputs, ... }:

{

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    persistent = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  programs.nix-ld.enable = true;
  services.fwupd.enable = true;
}
