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
    extra-substituters = [
      "https://nixslop.cachix.org?priority=30"
    ];
    extra-trusted-public-keys = [
      "nixslop.cachix.org-1:Y41flUqIXb+Qx7D6hiugUE17RG4EkLaBn3UlVXc1oE8="
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

  # Codex Computer Use input backend.
  programs.ydotool.enable = true;

  security.pki.certificateFiles = [
    ./root_ca.crt
  ];
}
