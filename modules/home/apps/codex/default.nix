{
  inputs,
  ...
}:

{
  imports = [
    inputs.nixslop.homeManagerModules.default
  ];

  programs.codexDesktopLinux = {
    enable = true;
    computerUseUi.enable = true; # default: false
    remoteMobileControl.enable = true; # default: false
  };

  programs.codexOmx = {
    enable = true;
  };

  programs.bash = {
    shellAliases = {
      x = "omx --tmux --hotswap --madmax";
    };
  };
}
