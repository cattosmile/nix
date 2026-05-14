{ ... }:

{
  #  sops.defaultSopsFile = ./secrets.yaml;
  networking.hostName = "macbook";
  system.stateVersion = "25.11";
}
