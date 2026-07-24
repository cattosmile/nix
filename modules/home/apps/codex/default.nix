{
  inputs,
  ...
}:

{
  imports = [
    inputs.nixslop.homeManagerModules.codexDesktop
    inputs.nixslop.homeManagerModules.codexOmx
    inputs.nixslop.homeManagerModules.kimiCode
    inputs.nixslop.homeManagerModules.openCode
  ];

  programs.codexDesktopLinux.enable = true;
  programs.codexOmx.enable = true;
  programs.kimiCode.enable = true;
  programs.openCode.enable = true;

  programs.bash = {
    shellAliases = {
      x = "omx --tmux --hotswap --madmax";
    };
  };
}
