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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      legacyPackages.${system} = pkgs // {
        unstable = nixpkgs-unstable.legacyPackages.${system};
      };

      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs sops-nix; };
        modules = [
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager

          {
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
          }
          sops-nix.nixosModules.sops
          {
            nixpkgs.overlays = [
              (final: prev: {
                unstable = nixpkgs-unstable.legacyPackages.${system};
              })
            ];
          }
        ];
      };
    };
}
