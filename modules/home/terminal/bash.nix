{ ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      switch = "/run/wrappers/bin/sudo nixos-rebuild switch --flake /home/user/nix#desktop";
    };
  };
}
