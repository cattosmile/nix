{ pkgs, ... }:

{
  programs.gamemode = {
    enable = true;
    settings = {
      general.renice = 10;
    };
  };

  users.users.user.extraGroups = [ "gamemode" ];

  environment.systemPackages = with pkgs; [
    gamescope-wsi
  ];
}
