{
  config,
  lib,
  pkgs,
  ...
}:

{
  systemd.services.disable-wifi-on-boot = lib.mkIf config.networking.networkmanager.enable {
    description = "Disable Wi-Fi radio on boot";

    wants = [ "NetworkManager.service" ];
    after = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.networkmanager}/bin/nmcli radio wifi off";
    };
  };
}
