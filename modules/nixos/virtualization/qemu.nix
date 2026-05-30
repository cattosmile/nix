{ pkgs, ... }:

{
  virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm.overrideAttrs (oldAttrs: {
    version = "10.2.2";
    src = pkgs.fetchurl {
      url = "https://download.qemu.org/qemu-10.2.2.tar.xz";
      sha256 = "0xp1457v1hw5szf7gx942xvvk6pasarbqfijfam1f54wy9pjjjvq";
    };
    patches = [
      (pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/zhaodice/qemu-anti-detection/main/qemu-10.2.2.patch";
        sha256 = "03hiv84lh5ayvi25a21h9xln8pcm3kcbf0rjwczyy76rrshg218d";
      })
    ];
  });

  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  systemd.services.libvirtd.after = [ "systemd-modules-load.service" ];

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };

  # Start Default Virtual Network for VMs
  systemd.services.libvirt-default-network = {
    description = "Start libvirt default network";
    after = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.libvirt}/bin/virsh net-start default";
      ExecStop = "${pkgs.libvirt}/bin/virsh net-destroy default";
      User = "root";
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;
}
