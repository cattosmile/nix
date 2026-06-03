{
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.nixslop.homeManagerModules.codexOmx ];

  programs.codexOmx.enable = true;

  home.packages = with pkgs; [
    inputs.kimi-cli.packages.${pkgs.stdenv.hostPlatform.system}.kimi-cli
  ];

  programs.bash = {
    shellAliases = {
      #      omx = "omx --tmux --hotswap --madmax";
    };
  };
}
