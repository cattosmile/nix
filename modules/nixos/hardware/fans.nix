{ pkgs, ... }:

{
  boot.kernelModules = [ "nct6775" ];

  programs.coolercontrol.enable = true;

  environment.systemPackages = with pkgs; [
    lm_sensors
  ];
}
