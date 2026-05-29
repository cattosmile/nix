{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Homeserver
    matchBlocks.mini = {
      hostname = "192.168.1.117";
      user = "user";
    };
  };
}
