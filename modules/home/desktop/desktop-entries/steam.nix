{ ... }:

{
  xdg.desktopEntries = {
    mullvad-excluded-steam = {
      name = "Steam";
      genericName = "Content Delivery Platform";
      icon = "steam";
      exec = "mullvad-exclude steam %U";
      terminal = false;
      categories = [
        "Network"
        "FileTransfer"
        "Game"
      ];
      comment = "Application for managing and playing games on Steam (Split Tunneling Active)";
    };

    steam = {
      name = "Steam";
      noDisplay = true;
      exec = "true";
    };
  };
}
