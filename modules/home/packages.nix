{
  pkgs,
  unstable,
  ...
}:

{

  home.packages = with pkgs; [
    kitty
    nano
    nemo-with-extensions
    unstable.code-cursor-fhs
  ];
}

# Meow
