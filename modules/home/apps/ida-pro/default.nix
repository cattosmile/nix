{
  inputs,
  pkgs,
  ...
}:

{
  programs.idaPro = {
    enable = true;
    package = pkgs.ida-pro;
    mcp = {
      enable = true;
      package = pkgs.ida-mcp-server;
    };
  };
}
