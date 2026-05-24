{ ... }:

{
  services.udev.extraRules = ''
    # Sayodevice
    SUBSYSTEM=="usb", ATTRS{idVendor}=="8089", ATTRS{idProduct}=="0009", MODE="0666", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8089", ATTRS{idProduct}=="0009", MODE="0666", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8089", MODE="0666", TAG+="uaccess"
  '';
}
