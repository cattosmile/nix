{ config, ... }:

{
  users.mutableUsers = false;

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    hashedPasswordFile = config.sops.secrets.user_password.path;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.root_password.path;
}
