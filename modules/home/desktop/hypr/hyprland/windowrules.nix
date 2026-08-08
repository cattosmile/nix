{ hyprMonitors, ... }:

{
  wayland.windowManager.hyprland.settings = {
    window_rule = [
      # Hyprland Defaults
      {
        match.class = ".*";
        suppress_event = "maximize";
      }
      {
        match.title = "^(Click Assistant Overlay)$";
        float = true;
        no_anim = true;
        no_focus = true;
        no_initial_focus = true;
        no_follow_mouse = true;
        focus_on_activate = false;
        no_blur = true;
      }
      {
        no_focus = true;
        match = {
          class = "^$";
          title = "^$";
          xwayland = true;
          float = true;
          fullscreen = false;
          pin = false;
        };
      }

      # Gamescope
      {
        match.class = "^(chromium-browser)$";
        workspace = "3 silent";
        fullscreen = false;
      }
      {
        match.class = "^gamescope$";
        workspace = "1 silent";
        fullscreen = true;
        immediate = true;
      }
      {
        match.class = "^\\.gamescope-wrapped$";
        workspace = "1 silent";
        fullscreen = true;
        immediate = true;
      }

      # Roblox / Sober
      {
        match.class = "^(org.vinegarhq.Sober)$";
        workspace = "1 silent";
      }
      {
        match = {
          class = "^(org.vinegarhq.Sober)$";
          initial_title = "negative:^Sober$";
        };
        float = true;
        center = true;
        size = "1000 600";
      }

      # Discord
      {
        match.class = "^(discord)$";
        workspace = "10 silent";
      }

      # Terminal
      {
        match.title = "alacritty_float";
        float = true;
        center = true;
        size = "1000 600";
        monitor = hyprMonitors.primary;
      }

      # Volume Control
      {
        match.class = "^(org.pulseaudio.pavucontrol)$";
        float = true;
        center = true;
        size = "1000 600";
      }

      # Image Viewer?
      {
        match.class = "^(swappy)$";
        float = true;
        center = true;
        monitor = hyprMonitors.primary;
      }

      # Dialogs
      {
        match.title = "^(Open File|Save As|Upload File|Add Folder to Workspace)$";
        float = true;
        center = true;
        size = "1000 600";
      }

      # Steam
      {
        match.class = "^(steam)$";
        workspace = "2 silent";
      }
      {
        match = {
          class = "^(steam)$";
          title = "negative:^(Steam||Friends List|Special Offers)$";
        };
        float = true;
        center = true;
        monitor = hyprMonitors.primary;
      }
      {
        match = {
          class = "^(steam)$";
          title = "^(Friends List)$";
        };
        float = true;
        size = "300 600";
        monitor = hyprMonitors.primary;
        move = "(monitor_w-window_w-200) ((monitor_h-window_h)/2)";
      }
      {
        match = {
          class = "^(steam)$";
          title = "^(Special Offers)$";
        };
        workspace = "special:void silent";
        no_focus = true;
      }

      # Spotify
      {
        match.class = "^(Spotify)$";
        workspace = "9 silent";
        tile = true;
      }

      # File Roller (Zip, Rar)
      {
        match.class = "^(org.gnome.FileRoller)$";
        float = true;
        center = true;
        monitor = hyprMonitors.primary;
      }

      # Calculator
      {
        match.class = "^(org.gnome.Calculator)$";
        float = true;
        center = true;
        size = "250 700";
        monitor = hyprMonitors.primary;
      }
    ];
  };
}
