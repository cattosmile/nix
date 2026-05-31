# SLSsteam — https://github.com/AceSLS/SLSsteam
# Flake outputs: packages.<system>.sls-steam (.so libs), .wrapped (SLSsteam launcher), homeModules.sls-steam (HM config only)
{ pkgs, inputs, ... }:

# let
#   system = pkgs.stdenv.hostPlatform.system;
#   slsSteam = inputs.sls-steam.packages.${system};
# in
{
  environment.systemPackages = [ inputs.sls-steam.packages.${pkgs.system}.wrapped ];
}
