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
      {
        appId = "org.chromium.Chromium";
        origin = "flathub";
      }
      {
        appId = "com.google.Chrome";
        origin = "flathub";
      }
    ];
  };
}
