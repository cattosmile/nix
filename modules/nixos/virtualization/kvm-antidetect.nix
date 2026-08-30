# kvm-antidetect.nix — Host-Kernel-Patch gegen KVM-Hypercall-Erkennung
# ----------------------------------------------------------------------------
# QemuDetection / VM::KVM_INTERCEPTION (2026-08-30):
# KVM quittiert Hypercalls aus Guest-Userspace (CPL3) stumm mit -KVM_EPERM
# in RAX und keiner Exception — echte Hardware liefert #UD. Detektoren
# (VMAware "hypervisor interception") werten die fehlende Exception als
# Hypervisor-Beweis. Der Patch injiziert #UD wie echte Hardware.
# Kanonische Quelle: QemuDetection/patches/kernel/0001-kvm-cpl3-hypercall-ud.patch
# (Kopie hier, da Flakes keine absoluten Pfade ausserhalb des Baums erlauben.)
# Rebuild: sudo nixos-rebuild switch --flake /home/user/nix#desktop  + Reboot
{ config, lib, ... }:

{
  boot.kernelPatches = [
    {
      name = "kvm-cpl3-hypercall-ud";
      patch = ./kvm-cpl3-hypercall-ud.patch;
    }
  ];
}
