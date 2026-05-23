{ config, pkgs, ... }:

{
  home.packages = [ pkgs.unstable.pi-coding-agent ];

  home.sessionVariables = {
    PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent";
    PI_CODING_AGENT_SESSION_DIR = "${config.xdg.dataHome}/pi/sessions";
    PI_SKIP_VERSION_CHECK = "1";
    PI_TELEMETRY = "0";
  };

  xdg.configFile."pi/agent/settings.json".source = ./settings.json;
  xdg.configFile."pi/agent/AGENTS.md".source = ./AGENTS.md;
  xdg.configFile."pi/agent/skills/nixos/SKILL.md".source = ./skills/nixos/SKILL.md;
}
