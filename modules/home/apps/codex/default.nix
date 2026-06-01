{ unstable, pkgs, ... }:

{
  programs.codexDesktopLinux = {
    enable = true;

    # Optional features mentioned in the README:
    computerUseUi.enable = true;
    remoteMobileControl.enable = false; # Set to true if you want the systemd app-server
    remoteControl.enable = false;
  };

  home.packages = with pkgs; [
    unstable.codex
  ];
}
