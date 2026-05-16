{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
      disko,
    }@inputs:
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs sops-nix;
          device = "/dev/disk/by-id/nvme-Force_MP600_204682290001285549B0";
        };
        modules = [
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          disko.nixosModules.disko

          {
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
          }
          sops-nix.nixosModules.sops
          {
            nixpkgs.overlays = [
              (final: prev: {
                unstable = nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system};
              })
            ];
          }
        ];
      };
    };
}
