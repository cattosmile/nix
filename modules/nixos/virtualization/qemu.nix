{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
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
}
