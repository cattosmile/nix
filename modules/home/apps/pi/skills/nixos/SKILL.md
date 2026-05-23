---
name: nixos
description: NixOS system administration and declarative configuration management. Use when the user asks about NixOS, nix commands, rebuilding the system, managing packages, or troubleshooting the NixOS configuration.
---

# NixOS Skill

## Setup

No external dependencies required. This skill assumes a standard NixOS flake setup.

## Rebuilding the System

Always rebuild from the flake root:

```bash
cd /path/to/nix-config
sudo nixos-rebuild switch --flake .#desktop
```

For the current host without specifying the name:

```bash
sudo nixos-rebuild switch --flake .
```

## Managing Packages

### System-wide packages

Edit `modules/nixos/core/packages.nix` or the relevant module, then rebuild.

### User packages

Edit `modules/home/packages.nix` or the relevant app module (e.g., `modules/home/apps/pi/default.nix`), then rebuild.

## Updating the System

```bash
nix flake update
sudo nixos-rebuild switch --flake .#desktop
```

## Rollbacks

```bash
# List previous generations
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

# Boot into previous generation (select at bootloader)
# Or switch immediately:
sudo nixos-rebuild switch --flake .#desktop --switch-generation 42
```

## Garbage Collection

```bash
# Delete old generations
sudo nix-collect-garbage -d

# Delete generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d
```

## Secrets (sops-nix)

```bash
# Edit host secrets
sops hosts/desktop/secrets.yaml

# Rebuild after editing secrets (sops-nix decrypts at activation)
sudo nixos-rebuild switch --flake .#desktop
```

## Home Manager

This system uses Home Manager as a NixOS module (`home-manager.nixosModules.home-manager`).

- User config is applied automatically during `nixos-rebuild switch`.
- No need to run `home-manager switch` separately.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `error: cannot find flake` | Ensure you are in the repo root and `flake.nix` exists. |
| `error: attribute 'X' missing` | Check that the module is imported in the correct `default.nix`. |
| Secrets fail to decrypt | Verify `sops.age.keyFile` points to a valid age private key. |
| Home-manager config conflict | Delete `~/.config/home-manager` if it exists from a previous standalone install. |
