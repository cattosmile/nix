{ pkgs, ... }:

{
  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      #      package = qemu_kvm;
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
