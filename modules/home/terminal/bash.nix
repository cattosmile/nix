{ ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      switch = "sudo nixos-rebuild switch --flake /home/user/nix-testing-2#desktop";
    };
  };
}
