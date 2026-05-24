{ pkgs, ... }:

{
  environment.variables = {
    SDL_JOYSTICK_HIDAPI = "1";
    SDL_JOYSTICK_HIDAPI_SWITCH = "1";
    SDL_JOYSTICK_HIDAPI_SWITCH_PLAYER_LED = "1";
  };

  services.udev.extraRules = ''
    # Nintendo Switch Pro Controller over Bluetooth
    KERNEL=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666"
  '';

  services.udev.packages = with pkgs; [
    game-devices-udev-rules
  ];
}
