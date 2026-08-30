{ config, lib, ... }:

{
  boot.kernelPatches = [
    {
      name = "kvm-cpl3-hypercall-ud";
      patch = /home/user/Projects/QemuDetection/patches/kernel/0001-kvm-cpl3-hypercall-ud.patch;
    }
  ];
}
