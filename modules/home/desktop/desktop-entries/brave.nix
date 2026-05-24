{ ... }:

{
  xdg.desktopEntries = {
    mullvad-excluded-brave = {
      name = "Brave";
      genericName = "Web Browser";
      icon = "brave-browser";
      exec = "mullvad-exclude brave %U";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      comment = "Access the Internet with Brave (Split Tunneling Active)";
    };

    brave-browser = {
      name = "Brave";
      noDisplay = true;
      exec = "true";
    };
  };
}
