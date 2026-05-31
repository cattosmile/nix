# QEMU 10.2.2 with https://github.com/zhaodice/qemu-anti-detection applied.
# Built from nixpkgs-unstable (10.2.2); stable 25.11 ships 10.1.5.
# Patch is vendored under ./patches/ so upstream edits do not break the hash.
pkgs:

let
  antiDetectionPatch = ./patches/qemu-10.2.2-anti-detection.patch;
  # anti-detection spoofs PCI_VENDOR_ID_REDHAT_QUMRANET (0x1af4) -> 0x8086 globally;
  # restore ivshmem IDs so the Windows IVSHMEM / Looking Glass driver can bind.
  lookingGlassIvshmemPatch = ./patches/qemu-10.2.2-looking-glass-ivshmem.patch;
in
pkgs.unstable.qemu_kvm.overrideAttrs (oldAttrs: {
  patches =
    (oldAttrs.patches or [ ])
    ++ [
      antiDetectionPatch
      lookingGlassIvshmemPatch
    ];
})
