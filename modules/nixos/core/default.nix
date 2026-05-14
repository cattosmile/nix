{ ... }:

{
  imports = [
    ./users.nix
    ./locale.nix
    ./networkmanager.nix
    ./tty.nix
    ./system.nix
    ./ssh.nix
    ./packages.nix
    ./sops.nix
  ];
}
