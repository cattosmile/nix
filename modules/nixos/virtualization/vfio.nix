{ pkgs, config, ... }:

{
  virtualisation.libvirtd = {
    qemu = {
      verbatimConfig = ''
        cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc", "/dev/hpet",
            "/dev/input/by-id/usb-Lenovo_Lenovo_Traditional_USB_Keyboard-event-kbd",
            "/dev/input/by-id/usb-Logitech_USB_Receiver-event-mouse",
            "/dev/kvmfr0"
        ]
      '';
    };
  };

  services.udev.extraRules = ''
    KERNEL=="kvmfr*", GROUP="kvm", MODE="0660", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    looking-glass-client
  ];

  boot = {
    kernelModules = [
      "kvmfr"
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];

    kernelParams = [
      "intel_iommu=on"
      "vfio-pci.ids=1002:73ff,1002:ab28,144d:a808"
    ];

    extraModulePackages = [ config.boot.kernelPackages.kvmfr ];

    extraModprobeConfig = ''
      options kvmfr static_size_mb=32
    '';
  };
}
