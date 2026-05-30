{ ... }:

{
  services.flatpak = {
    enable = true;
    packages = [
      # { appId = ""; origin = "flathub"; }
    ];
  };
}
