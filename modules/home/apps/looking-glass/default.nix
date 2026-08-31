{ ... }:

{
  xdg.configFile."looking-glass/client.ini".text = ''
    [audio]
    micDefault=allow

    [spice]
    enable=no
  '';
}
