{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Homeserver
    settings.mini = {
      HostName = "192.168.1.117";
      User = "user";
    };
  };
}
