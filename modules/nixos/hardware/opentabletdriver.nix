{ ... }:

{
  # Use OpenTabletDriver for Wacom tablets instead of the kernel tablet driver.
  hardware.opentabletdriver = {
    enable = true;
    daemon.enable = true;
    blacklistedKernelModules = [
      "wacom"
      "hid-uclogic"
    ];
  };

  hardware.uinput.enable = true;
}
