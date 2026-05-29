{ ... }:

{
  networking.networkmanager.enable = true;

  users.users.user = {
    extraGroups = [ "networkmanager" ];
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  services.resolved = {
    enable = true;
    fallbackDns = [ ];
  };

  services.mullvad-vpn = {
    enable = true;
  };
}
