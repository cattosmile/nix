{ pkgs, ... }:

# Shortcuts:
# Command Palette: Ctrl + Shift + P
# Find File: Ctrl + P
# Find Global Text: Ctrl + Shift + F
# Go to Line: Ctrl + G
# Toggle Terminal: Ctrl + J
# Toggle Sidebar: Ctrl + B
# Close Current File: Ctrl + W

{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil
    prettier
    nodejs_22
  ];

  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        esbenp.prettier-vscode
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
      ];

      userSettings = {
        # Settings
        "editor.minimap.enabled" = false;
        "workbench.startupEditor" = "none";

        # Theme
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";

        # UI Layout
        "window.menuBarVisibility" = "compact";
        "workbench.activityBar.location" = "top";
        "workbench.sideBar.location" = "right";
        "workbench.secondarySideBar.defaultVisibility" = "hidden";
        "window.commandCenter" = false;
        "window.zoomLevel" = 3;

        # Hide Scrollbar
        "editor.scrollbar.vertical" = "hidden";
        "editor.scrollbar.horizontal" = "hidden";
        "editor.overviewRulerBorder" = false;
        "editor.hideCursorInOverviewRuler" = true;
        "workbench.colorCustomizations" = {
          "scrollbarSlider.background" = "#00000000";
          "scrollbarSlider.hoverBackground" = "#00000000";
          "scrollbarSlider.activeBackground" = "#00000000";
          "scrollbar.shadow" = "#00000000";
          "sideBar.border" = "#00000000";
          "editorOverviewRuler.background" = "#00000000";
        };

        # Scrolling
        "editor.mouseWheelScrollSensitivity" = 4;
        "editor.fastScrollSensitivity" = 0.3;

        # AI
        # "claudeCode.useTerminal" = true;
        # "claudeCode.allowDangerouslySkipPermissions" = true;
        # "claudeCode.enableNewConversationShortcut" = true;
        # "claudeCode.initialPermissionMode" = "plan";
        # "claudeCode.preferredLocation" = "sidebar";

        # Indentation
        "editor.tabSize" = 2;
        "editor.insertSpaces" = true;
        "editor.detectIndentation" = false;

        # Nix Formatter
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixfmt";
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ "nixfmt" ];
            };
          };
        };
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.formatOnSave" = true;
        };

        # Prettier
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "prettier.tabWidth" = 2;
        "editor.formatOnSave" = true;
      };
    };
  };
}
