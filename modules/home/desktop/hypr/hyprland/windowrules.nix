{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Hyprland Defaults
      "match:class .*, suppress_event maximize"
      "no_focus on, match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false"

      # Gamescope
      "match:class ^gamescope$, workspace 1 silent, fullscreen on"
      "match:class ^\\.gamescope-wrapped$, workspace 1 silent, fullscreen on"

      # Roblox / Sober
      "match:class ^(org.vinegarhq.Sober)$, workspace 1 silent"
      "match:class ^(org.vinegarhq.Sober)$, match:title ^(Profile)$, workspace 1 silent"
      "match:class ^(org.vinegarhq.Sober)$, match:title ^(Servers)$, workspace 1 silent"
      "match:class ^(org.vinegarhq.Sober)$, match:title ^(Account info)$, workspace 1 silent"

      # Discord
      "match:class ^(discord)$, workspace 10 silent"

      # Terminal
      "match:title alacritty_float, float on, center on, size 1000 600, monitor DP-1"

      # Volume Control
      "match:class ^(org.pulseaudio.pavucontrol)$, float on, center on, size 1000 600, monitor DP-1"

      # Image Viewer?
      "match:class ^(swappy)$, float on, center on, monitor DP-1"

      # Dialogs
      "match:title ^(Open File|Save As|Upload File|Add Folder to Workspace)$, float on, center on, size 1000 600"

      # Steam
      "match:class ^(steam)$, workspace 2 silent"
      "match:class ^(steam)$, match:title ^(Friends List)$, float on, size 300 600, monitor DP-1, move (monitor_w-window_w-200) ((monitor_h-window_h)/2)"
      "match:class ^(steam)$, match:title ^(Special Offers)$, workspace special:void silent, no_focus on"

      # Spotify
      "match:class ^(Spotify)$, workspace 9 silent, tile on"

      # File Roller (Zip, Rar)
      "match:class ^(org.gnome.FileRoller)$, float on, center on, monitor DP-1"

      # Calculator
      "match:class ^(org.gnome.Calculator)$, float on, center on, size 250 700, monitor DP-1"
    ];
  };
}
