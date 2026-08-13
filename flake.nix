{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pin Hyprland to the 0.56.0 release. Update this tag deliberately.
    hyprland.url = "github:hyprwm/Hyprland/v0.56.0";
    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    sls-steam = {
      url = "github:AceSLS/SLSsteam";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixslop.url = "github:cattosmile/NixSlop";
    click-assistant = {
      url = "path:/home/user/Projects/Assistant%20Thing";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ida-pro = {
      url = "git+http://192.168.1.117:3000/cattosmile/ida-pro-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
      disko,
      nix-flatpak,
      ...
    }@inputs:
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          device = "/dev/disk/by-id/nvme-Force_MP600_204682290001285549B0";
        };
        modules = [
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          disko.nixosModules.disko
          {
            home-manager.sharedModules = [
              (
                { pkgs, ... }:
                {
                  _module.args.unstable = pkgs.unstable;
                }
              )
              inputs.sops-nix.homeManagerModules.sops
              nix-flatpak.homeManagerModules.nix-flatpak
              inputs.ida-pro.homeManagerModules.default
            ];
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
          sops-nix.nixosModules.sops
          {
            nixpkgs.overlays = [
              inputs.nur.overlays.default
              inputs.ida-pro.overlays.default
              (final: prev: {
                unstable = import nixpkgs-unstable {
                  system = final.stdenv.hostPlatform.system;
                  config = prev.config;
                };
              })
            ];
          }
        ];
      };
    };
}
