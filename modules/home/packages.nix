{
  pkgs,
  unstable,
  inputs,
  ...
}:

{

  home.packages = with pkgs; [
    kitty
    nano
    brave
    nemo-with-extensions
    mousepad
    unstable.code-cursor-fhs
    unstable.helvum
    prismlauncher
    vlc
    unstable.rustdesk
    inputs.switcha.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

# Meow
