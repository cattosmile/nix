#   gaping                  Client starten        gaping help     alle Befehle
#   gaping update --install Client-Bundle holen   gaping logs     Run-Logs
#
# Nach jedem Roblox-Client-Update einmal: `gaping derive-telemetry`, sonst
# verweigert der Client den Start
{ config, ... }:

{
  programs.gaping = {
    enable = true;

    # --- Renderer ---
    videoBackend = "wayland";
    msaa = 0; # 0 | 2 | 4 | 8
    quality = "auto";
    zink = false;
    mangohud = true;
    renderDebug = false;

    # --- Frame Pacing ---
    fps.mode = "target";
    fps.target = 1000; # taktet nur den TaskScheduler, kein hartes Cap — das
                       # ist Roblox' In-Game-Regler "Maximum Frame Rate" (Default 60)

    # --- Client / Start ---
    autoUpdate = true;
    guestPatches = true;
    maxWorkerThreads = null;
    bundleDir = "${config.home.homeDirectory}/.local/share/gaping/client";
    logDir = "${config.xdg.stateHome}/gaping/run-logs";

    # --- Audio
    voiceBitrate = 0;
    gamepads = false;

    # --- Telemetrie
    telemetryOptIn = false;

    # --- Desktop
    desktop.enable = true;
    desktop.schemeHandler = true;
    extraSettings = { };
  };
}
