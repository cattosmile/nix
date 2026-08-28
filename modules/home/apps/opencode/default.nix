{
  inputs,
  pkgs,
  ...
}:

let
  # CHANGE MODEL OF SUBAGENTS
  omoAgents = [
    "atlas"
    "build"
    "explore"
    "general"
    "hephaestus"
    "librarian"
    "metis"
    "momus"
    "multimodal-looker"
    "OpenCode-Builder"
    "oracle"
    "plan"
    "prometheus"
    "sisyphus"
    "sisyphus-junior"
  ];
  omoModel = "opencode/x-preview-f-free";
in

{
  home.packages = [
    inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode-desktop
    pkgs.file
    pkgs.python3
    pkgs.jq
  ];

  programs.bash.shellAliases.opencode = "command opencode --auto";

  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    settings = {
      plugin = [ "oh-my-openagent" ];
      mcp.ida = {
        type = "local";
        command = [ "${pkgs.ida-mcp-server}/bin/ida-mcp-server" ];
        enabled = true;
      };
      mcp.slopping = {
        type = "local";
        command = [
          "/run/current-system/sw/bin/nix"
          "develop"
          "/home/user/Projects/slopping"
          "-c"
          "python3"
          "/home/user/Projects/slopping/mcp/server.py"
        ];
        enabled = true;
      };

      # CHANGE MODEL OF SUBAGENTS
      small_model = omoModel;
      agent = {
        compaction.model = omoModel;
        title.model = omoModel;
        summary.model = omoModel;
      };
    };
  };

  # CHANGE MODEL OF SUBAGENTS
  home.file.".omo/omo.jsonc".text = builtins.toJSON {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json";
    "[opencode]" = {
      agents = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = {
            model = omoModel;
          }
          // (if name == "hephaestus" then { allow_non_gpt_model = true; } else { });
        }) omoAgents
      );
      categories = builtins.mapAttrs (_: _: { model = omoModel; }) {
        visual-engineering = { };
        ultrabrain = { };
        deep = { };
        artistry = { };
        quick = { };
        unspecified-low = { };
        unspecified-high = { };
        writing = { };
      };
    };
    _migrations = [ "2026-07-opencode-config-unification" ];
  };

  # OpenCode System Prompt!
  home.file.".config/opencode/AGENTS.md".text = ''
    # Persistent user rules: NixOS-first and project-scoped work

    These rules apply to every task, including tasks that do not mention Nix, NixOS, or Home Manager. Full filesystem access and automatic approvals are intentional for normal project-local work. Full access does not expand the task scope.

    ## OpenCode and OmO

    - Use OpenCode's native tools and the oh-my-openagent (OmO) orchestration that is installed in this configuration.
    - For autonomous multi-step implementation, use the Sisyphus agent with the `ulw`/`ultrawork` workflow.
    - Use Prometheus when a task needs an explicit requirements interview and written plan; use Hephaestus for focused deep work when the selected model is GPT-native.
    - Continue autonomously through ordinary inspection, edits, builds, tests, and local verification. Ask only for genuine blockers, missing authority, destructive actions, credentials, or materially ambiguous decisions.
    - Do not confuse OmO's orchestration rules with permission to leave the assigned project scope.

    ## Scope and personal configuration

    - Treat the assigned workspace or project root as the default write boundary. Before edits, check `pwd` and, when available, `git rev-parse --show-toplevel`; do not drift into parent, home, or configuration directories merely because a dependency is located there.
    - Treat `/home/user/nix/**`, `~/.config/**`, `/etc/nixos/**`, `/etc/**`, and `/run/current-system/**` as read-only and protected by default. Reading, evaluating, and referencing them is allowed; writing, copying, or imperatively updating them is not.
    - A direct, unambiguous request for a specific protected change is the exception; make only the minimal required diff. If the detected root is `/home/user` or `/home/user/nix`, do not automatically rework the personal configuration—use a project-local copy or isolated test setup instead.

    ## Declarative Nix project workflow

    - Never require the user to scaffold a project. Inspect existing conventions and create only the missing structure needed inside the assigned project. For Nix tasks, prefer a minimal `flake.nix`/`flake.lock` with suitable `devShells`, packages, modules, overlays, checks, tests, or examples; do not add empty boilerplate.
    - Use `nix develop`, `nix flake check`, `nix flake show`, targeted `nix eval`, `nix build`, and `nix develop -c ...` for reproducible work. Avoid `nix-env`, `nix profile install`, and host installations when a project-local Flake solution is possible.
    - A project `flake.nix` may reference `path:/home/user/nix` read-only for integration checks. Keep that source tree unchanged, and export project modules, overlays, packages, or checks for later import instead of importing them into the personal Flake.
    - Do not run `nixos-rebuild switch|boot|test`, `home-manager switch`, `nh os switch`, or comparable activation/live-reload steps during ordinary development. Use dry-build/dry-activate, build, or project-local test targets; real activation requires an explicit request.
    - Create or update a project-local `AGENTS.md` only when durable project-specific guidance is useful; never make the user prepare one.

    ## Hyprland and desktop integration

    - Put project keybinds, window rules, and autostart in a project-local module, overlay, example, or test fixture. Use isolated configurations, a temporary `XDG_CONFIG_HOME`, or project-local generated artifacts for tests.
    - Never automatically modify or make the real Hyprland configuration fit the project. Integrating into personal `~/nix` is a separate, explicitly requested step; otherwise provide only the project-local interface and integration instructions.

    ## Change and verification protocol

    - Verify every edit against the project root. After changes, run at least `git diff --check`, `git status --short`, and the appropriate project-local Nix check when applicable.
    - Report changed paths and validation, explicitly confirming whether `/home/user/nix` and the personal Hyprland/Home Manager configuration remained untouched.
  '';
}
