{ pkgs, inputs, ... }:

{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  programs.spicetify =

    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {

      enable = true;

      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle
      ];
    };
}
