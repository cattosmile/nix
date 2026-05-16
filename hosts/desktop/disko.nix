{ device }:
{ ... }:
let
  btrfsOptions = [
    "compress=zstd"
    "noatime"
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
in
{
  disko.devices = {
    disk = {
      main = {
        inherit device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "4G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f"
                    "-L"
                    "nixos"
                  ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = btrfsOptions;
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = btrfsOptions;
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = btrfsOptions;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
