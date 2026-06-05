{ ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.user = {
    imports = [ ../../../modules/home ];
    home.stateVersion = "26.05";
  };
}
