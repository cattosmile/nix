{ ... }:

{
  boot.kernelParams = [ "split_lock_detect=off" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
