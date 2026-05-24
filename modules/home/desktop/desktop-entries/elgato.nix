{ pkgs, ... }:

{
  xdg.desktopEntries = {
    elgato-capture-card = {
      name = "Elgato Capture Card";
      genericName = "Game Console Capture";
      icon = "mpv";
      exec = "${pkgs.writeShellScript "play-elgato" ''
        pw-loopback -C alsa_input.usb-Elgato_Game_Capture_HD60_S__0005C52126000-03.analog-stereo &
        PID=$!
        mpv /dev/video0 --profile=low-latency --fs
        kill $PID
      ''}";
      terminal = false;
      categories = [
        "Game"
        "AudioVideo"
      ];
      comment = "Play HDMI inputs via Elgato Capture Card";
    };
  };
}
