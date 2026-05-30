{ pkgs, unstable, ... }:

{
  home.packages = with pkgs; [
    nano
    nemo-with-extensions
    unstable.code-cursor-fhs
  ];
}

# Meow
