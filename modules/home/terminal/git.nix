{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
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

# Meowwwwwwwww
