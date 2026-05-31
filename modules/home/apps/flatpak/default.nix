{ ... }:

{
  services.flatpak = {
    enable = true;
    packages = [
      # { appId = ""; origin = "flathub"; }
      {
        appId = "org.vinegarhq.Sober";
        origin = "flathub";
      }
    ];
  };
}
