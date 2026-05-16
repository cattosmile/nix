#!/usr/bin/env bash
set -euo pipefail

echo "=== NixOS Install Script ==="

echo ""
echo "Current disk device in disko.nix:"
echo "Target disk from flake.nix:"
grep "device =" flake.nix | head -1

echo ""
read -p "Is this the correct disk? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Edit flake.nix and re-run."
  exit 1
fi

echo ""
echo ">>> Running disko (you will be asked to set the LUKS passphrase)..."
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./hosts/desktop/disko.nix

echo ""
echo ">>> Decrypting age key (enter the encryption passphrase)..."
mkdir -p /mnt/var/lib/sops-nix

nix-shell -p openssl --run \
  "openssl enc -aes-256-cbc -pbkdf2 -d -in hosts/desktop/nixos-age-key.enc -out /mnt/var/lib/sops-nix/key.txt"

echo ""
echo ">>> Running nixos-install..."
nixos-install --flake .#desktop --no-root-passwd

echo ""
echo ">>> Install complete. Unmounting Partitions..."
umount -R /mnt || true