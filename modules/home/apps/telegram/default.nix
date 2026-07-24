{ pkgs, ... }:

{
  home.packages = [
    pkgs.telegram-desktop
  ];

  xdg.desktopEntries."org.telegram.desktop" = {
    name = "Telegram";
    genericName = "Chat client";
    comment = "Official Telegram Desktop client";
    icon = "org.telegram.desktop";
    exec = "${pkgs.telegram-desktop}/bin/Telegram -- %U";
    terminal = false;
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
    ];
    mimeType = [
      "x-scheme-handler/tg"
      "x-scheme-handler/tonsite"
    ];
  };
}
