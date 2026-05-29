{ ... }:

{
  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        name = "cattosmile";
        email = "238504882+cattosmile@users.noreply.github.com";
      };
      credential = {
        helper = "store";
      };
    };
  };
}
