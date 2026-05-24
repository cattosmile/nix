{ pkgs, ... }:

{
  xdg.desktopEntries = {
    firefox-gemini = {
      name = "Gemini";
      genericName = "Gemini";
      icon = "firefox";
      exec = "firefox -P Gemini";
      terminal = false;
      comment = "Firefox Gemini Profile";
    };

    firefox-claude = {
      name = "Claude";
      genericName = "Claude";
      icon = "firefox";
      exec = "firefox -P Claude";
      terminal = false;
      comment = "Firefox Claude Profile";
    };

    firefox-roblox = {
      name = "Roblox Firefox";
      genericName = "Roblox Firefox";
      icon = "firefox";
      exec = "firefox -P Roblox";
      terminal = false;
      comment = "Firefox Roblox Profile";
    };

    firefox-edx = {
      name = "edx Firefox";
      genericName = "edx Firefox";
      icon = "firefox";
      exec = "firefox -P edX";
      terminal = false;
      comment = "Firefox edX Profile";
    };

    firefox-trackers = {
      name = "trackers";
      genericName = "trackers";
      icon = "firefox";
      exec = "firefox -P trackers";
      terminal = false;
      comment = "Firefox trackers Profile";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}
