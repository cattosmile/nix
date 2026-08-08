{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    ../../home/users/user
    ./disko.nix
  ];

  # USB Filesystem Support
  boot.supportedFilesystems = [
    # "ntfs"
    "exfat"
    "btrfs"
  ];

  # Boot
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        configurationLimit = 10;
      };
      timeout = 3;
    };
    initrd = {
      systemd.enable = true;
    };
  };

  hardware.enableAllFirmware = true;

  # Host specific SSH and RAM settings
  zramSwap.enable = true;
  services.fstrim.enable = true;

  # Sops
  sops.defaultSopsFile = ./secrets.yaml;

  # BTRFS maintenance
  services.btrfs.autoScrub.enable = true;

  # Hostname
  networking.hostName = "NixSlop";

  # Specific Packages only for this host
  environment.systemPackages = with pkgs; [
    tree
  ];

  services.flatpak.enable = true;

  # For Codex Computer Use
  services.gnome.at-spi2-core.enable = true;

  # System Version
  system.stateVersion = "26.05"; # Did you read the comment?

}
