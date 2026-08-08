{
  inputs,
  ...
}:

{
  imports = [
    inputs.nixslop.homeManagerModules.default
  ];

  programs.codexDesktopLinux.enable = true;
  programs.codexOmx.enable = true;

  programs.bash = {
    shellAliases = {
      x = "omx --tmux --hotswap --madmax";
    };
  };
}
