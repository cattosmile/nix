{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unzip
    unrar
    btop
    curl
    wget

    # Grafischer sudo-Passwortdialog für localqwen switch aus dem
    # Quickshell-Launcher (scripts/sudo-askpass.sh im Quickshell-Repo).
    zenity
  ];
}
