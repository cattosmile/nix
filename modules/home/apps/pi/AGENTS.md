# NixOS System Conventions

This repository manages the entire NixOS system declaratively via a Flake.

## Golden Rules

- **Never run `sudo nixos-rebuild switch` directly.** Always build the flake from this repo.
- **Never edit `/etc/nixos/configuration.nix`.** All configuration lives in this repository.
- **Prefer `nix fmt` before committing.** The formatter is configured in `flake.nix`.
- **Run `nix flake check` after any structural change.**

## Common Commands

```bash
# Rebuild the system (from repo root)
sudo nixos-rebuild switch --flake .#desktop

# Update flake inputs
nix flake update

# Format all nix files
nix fmt

# Check flake evaluation
nix flake check

# Build without switching (dry-run equivalent)
sudo nixos-rebuild build --flake .#desktop
```

## Repository Layout

- `flake.nix` — Entry point. Defines inputs and the `desktop` system configuration.
- `hosts/desktop/` — Host-specific hardware, disk, and secrets config.
- `modules/nixos/` — Reusable NixOS system modules (core, hardware, firewall).
- `modules/home/` — Home-manager user modules (terminal, apps, packages).
- `home/users/user/` — User entry point that imports `modules/home`.

## Secrets

- Managed via `sops-nix`.
- Host secrets: `hosts/desktop/secrets.yaml` (encrypted with age).
- SOPS age key: `hosts/desktop/nixos-age-key.enc`.

## State Version

- `system.stateVersion = "25.11"`
- `home.stateVersion = "25.11"`

Do not change these unless you fully understand the implications.
