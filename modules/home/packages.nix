{
  pkgs,
  unstable,
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
  ];
}

# Meow
