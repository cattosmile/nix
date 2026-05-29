#!/usr/bin/env bash
set -euo pipefail

echo "=== NixOS Install Script ==="

# Check Disk
echo ""
echo "Target disk from flake.nix:"
grep "device =" flake.nix | head -1
echo ""
read -p "Is this the correct disk? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Edit flake.nix and re-run."
  exit 1
fi

# Run Disko
echo ""
echo ">>> Running disko (you will be asked to set the LUKS passphrase)..."
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake .#desktop

# Unlock Age Key
echo ""
echo ">>> Decrypting age key (enter the encryption passphrase)..."
mkdir -p /mnt/var/lib/sops-nix
nix-shell -p openssl --run \
  "openssl enc -aes-256-cbc -pbkdf2 -d -in hosts/desktop/nixos-age-key.enc -out /mnt/var/lib/sops-nix/keys.txt"

# Install NixOS
echo ""
echo ">>> Running nixos-install..."
nixos-install --flake .#desktop --no-root-passwd

# Copy Config to home directory
# username hardcoded intended cuz idk how to do this simply
echo ""
echo ">>> Copying config to /home/user/nix..."
mkdir -p /mnt/home/user/nix
cp -r . /mnt/home/user/nix/
mkdir -p /mnt/home/user/.config/sops/age
cp /mnt/var/lib/sops-nix/keys.txt /mnt/home/user/.config/sops/age/keys.txt
chown -R 1000:users /mnt/home/user/nix
chown -R 1000:users /mnt/home/user/.config/sops

# Unmount drives
echo ""
echo ">>> Install complete. Unmounting Partitions..."
umount -R /mnt || true