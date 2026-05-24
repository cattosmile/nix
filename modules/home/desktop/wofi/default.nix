{ ... }:

{
  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      show_actions = true;
      width = 700;
      lines = 8;
      columns = 2;
      dynamic_lines = false;
      allow_images = true;
      image_size = 36;
      matching = "multi-contains";
      insensitive = true;
      hide_scroll = true;

      key_up = "Up";
      key_down = "Down";
      key_left = "Left";
      key_right = "Right";
      key_submit = "Return";
      key_forward = "Tab";
      key_backward = "Shift-ISO_Left_Tab";
    };

    style = ''
      * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 16px;
      }

      window {
          margin: 0px;
          border: 2px solid #414868;
          background-color: #24283b;
      }

      #input {
          margin: 5px;
          border: 1px solid #24283b;
          color: #c0caf5;
          background-color: #24283b;
      }

      #inner-box {
          margin: 5px;
          border: none;
          background-color: #24283b;
      }

      #outer-box {
          margin: 5px;
          border: none;
          background-color: #24283b;
      }

      #text {
          margin: 5px;
          border: none;
          color: #c0caf5;
      }

      #entry:selected {
          background-color: #414868;
      }

      #text:selected {
          background-color: #414868;
      }
    '';
  };

}
