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
  ];
}

# Meow
