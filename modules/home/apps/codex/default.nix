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
    computerUseUi.enable = true;
    remoteMobileControl.enable = true;
  };

  programs.codexComputerUse.enable = true;

  programs.codexOmx = {
    enable = true;
  };

  programs.bash = {
    shellAliases = {
      x = "omx --tmux --hotswap --madmax";
    };
  };
}

programs.nixslop = {
  codex.enable = true;
  codex desktop.enable 
  omx.enable = true; 
}
