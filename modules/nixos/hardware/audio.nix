{ pkgs, ... }:

let
  hyperxMixerSetup = pkgs.writeShellScript "hyperx-quadcast-mixer-setup" ''
    attempt=0

    while [ "$attempt" -lt 40 ]; do
      if ${pkgs.alsa-utils}/bin/amixer \
        -c Quadcast cget numid=6 >/dev/null 2>&1
      then
        ${pkgs.alsa-utils}/bin/amixer \
          -q -c Quadcast cset numid=5 off
        ${pkgs.alsa-utils}/bin/amixer \
          -q -c Quadcast cset numid=6 25,25
        ${pkgs.alsa-utils}/bin/amixer \
          -q -c Quadcast cset numid=5 on
        exit 0
      fi

      attempt=$((attempt + 1))
      ${pkgs.coreutils}/bin/sleep 0.25
    done

    echo "HyperX QuadCast ALSA mixer was not available" >&2
    exit 1
  '';
in

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.extraConfig."51-hyperx-soft-mixer" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "device.name" = "alsa_card.usb-Kingston_HyperX_Quadcast_4110-00";
            }
          ];
          actions.update-props."api.alsa.soft-mixer" = true;
        }
      ];
    };
  };

  systemd.services.hyperx-quadcast-output-level = {
    description = "Set the HyperX QuadCast headphone output level";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = hyperxMixerSetup;
    };
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="sound", KERNEL=="controlC*", ATTRS{idVendor}=="0951", ATTRS{idProduct}=="16df", TAG+="systemd", ENV{SYSTEMD_WANTS}+="hyperx-quadcast-output-level.service"
  '';

  environment.systemPackages = with pkgs; [
    pavucontrol
    easyeffects
  ];

  security.rtkit.enable = true;
}
