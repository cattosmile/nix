{ ... }:

{
  imports = [
    ./vfio.nix
    ./kvm-antidetect.nix
    ./docker.nix
    ./qemu.nix
    ./xmls.nix
  ];
}
