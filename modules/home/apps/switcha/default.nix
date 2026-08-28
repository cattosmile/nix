{
  inputs,
  pkgs,
  ...
}:

{
  home.packages = [
    inputs.switcha.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.sessionVariables.SWITCHA_BROWSER = "firefox";
}
