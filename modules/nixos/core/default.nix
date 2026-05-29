{ ... }:

{
  imports = [
    ./users.nix
    ./locale.nix
    ./networking.nix
    ./tty.nix
    ./system.nix
    ./ssh.nix
    ./packages.nix
    ./sops.nix
  ];
}
