{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Add Shortcut for Homeserver
    matchBlocks.mini = {
      hostname = "192.168.1.117";
      user = "user";
    };
  };
}
