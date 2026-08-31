{ inputs, ... }:

{
  imports = [ inputs.localai.homeManagerModules.default ];
  localai = {
    enable = true;
    port = 8080;
    reasoning = "low";
  };

}
