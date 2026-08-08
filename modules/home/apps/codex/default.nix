{
  inputs,
  ...
}:

{
  imports = [
    inputs.nixslop.homeManagerModules.default
  ];

  programs.nixslop = {
    codex.enable = true;
    desktop = {
      enable = true;
      computerUseUi.enable = true;
      remoteMobileControl.enable = true;
    };
    computerUse.enable = true;
  };

  programs.bash = {
    shellAliases = {
      x = "omx --tmux --hotswap --madmax";
    };
  };
}
