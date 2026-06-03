{ pkgs, ... }:

let
  commonSettings = {
    # NixOS Integration
    "extensions.autoDisableScopes" = 0;
    "extensions.enabledScopes" = 15;

    # Disable Pocket
    "extensions.pocket.enabled" = false;
    "extensions.pocket.api" = "";
    "extensions.pocket.oAuthConsumerKey" = "";
    "extensions.pocket.site" = "";

    # UI Behavior
    "browser.aboutConfig.showWarning" = false;
    "browser.showQuitWarning" = false;
    "browser.warnOnQuitShortcut" = false;
    "browser.shell.checkDefaultBrowser" = false;
    "browser.messaging-system.whatsNewPanel.enabled" = false;
    "browser.aboutwelcome.enabled" = false;
    "browser.startup.homepage_override.mstone" = "ignore";
    "browser.startup.page" = 1;
    "browser.tabs.firefox-view" = false;
    "browser.tabs.firefox-view-next" = false;
    "browser.toolbars.bookmarks.visibility" = "always";
    "full-screen-api.warning.timeout" = 0;
    "browser.tabs.closeWindowWithLastTab" = true;
    "browser.sessionstore.resume_from_crash" = false;

    # New Tab Page
    "browser.newtabpage.enabled" = false;
    "browser.newtab.preload" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.feeds.snippets" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.default.sites" = "";
    "browser.newtabpage.activity-stream.showSearch" = false;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;

    # Disable AI Slop
    "browser.ml.enable" = false;
    "browser.ml.smartAssist.enabled" = false;
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.sidebar" = false;
    "browser.ml.chat.shortcuts" = false;
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.optin" = false;
    "browser.ml.linkPreview.enabled" = false;

    # Telemetry and Privacy
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.donottrackheader.enabled" = true;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "app.shield.optoutstudies.enabled" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "data:,";
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.coverage.opt-out" = true;
    "toolkit.coverage.opt-out" = true;
    "browser.ping-centre.telemetry" = false;
    "datareporting.healthreport.service.enabled" = false;
    "datareporting.usage.uploadEnabled" = false;
    "network.cookie.cookieBehavior" = 5;
    "media.peerconnection.ice.default_address_only" = true;
    "send_pings" = false;
    "browser.send_pings" = false;
    "beacon.enabled" = false;
    "privacy.fingerprintingProtection" = true;
    "network.dns.disablePrefetch" = true;
    "network.prefetch-next" = false;

    # URL Bar Suggestions
    "browser.urlbar.suggest.history" = true;
    "browser.urlbar.suggest.bookmark" = false;
    "browser.urlbar.suggest.openpage" = false;
    "browser.urlbar.suggest.topsites" = false;
    "browser.urlbar.suggest.searches" = false;
    "browser.urlbar.suggest.trending" = false;
    "browser.urlbar.showSearchSuggestionsFirst" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.showSearchTerms.enabled" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.urlbar.quickactions.enabled" = false;
    "browser.urlbar.shortcuts.quickactions" = false;
    "browser.urlbar.suggest.quickactions" = false;

    # Disable Autofill
    "signon.rememberSignons" = false;
    "signon.autofillForms" = false;
    "signon.generation.enabled" = false;
    "signon.firefoxRelay.feature" = "disabled";
    "signon.management.page.breach-alerts.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "browser.formfill.enable" = false;
    "middlemouse.paste" = false;

    # Enable DRM
    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.visible" = true;
    "media.gmp-widevinecdm.enabled" = true;

    # Localization
    "layout.spellcheckDefault" = 0;
    "browser.translations.enable" = false;

    # Disable Pings
    "network.captive-portal-service.enabled" = false;
    "network.connectivity-service.enabled" = false;
    "browser.region.update.enabled" = false;
    "browser.region.network.url" = "";
    "geo.provider.network.url" = "";

    # Website Permissions
    "permissions.default.desktop-notification" = 2;
    "permissions.default.geo" = 2;

    # Some other settings idk
    "browser.tabs.crashReporting.sendReport" = false;
    "breakpad.reportURL" = "";
    "browser.safebrowsing.downloads.remote.enabled" = false;
    "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
    "identity.fxaccounts.enabled" = false;

    # Hardware Acceleration / Performance
    "media.ffmpeg.vaapi.enabled" = true;
    "gfx.webrender.all" = true;
    "accessibility.force_disabled" = 1;
  };
in

{
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    profiles = {

      # ------------------------------------------------------------------------------------
      # Browsing
      # ------------------------------------------------------------------------------------
      browsing = {
        id = 0;
        name = "Browsing";
        isDefault = true;

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          sponsorblock
          return-youtube-dislikes
          darkreader
          mullvad
          enhancer-for-youtube
        ];
        settings = commonSettings // {
          "browser.startup.homepage" = "https://youtube.com";

          "browser.uiCustomization.state" = builtins.toJSON {
            currentVersion = 20;
            newElementCount = 5;
            placements = {
              widget-overflow-fixed-list = [ ];
              nav-bar = [
                "back-button"
                "forward-button"
                "stop-reload-button"
                "urlbar-container"
                "downloads-button"
                "unified-extensions-button"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "_d19a89b9-76c1-4a61-bcd4-49e8de9f8f43_-browser-action"
                "ublock0_raymondhill_net-browser-action"
              ];
              toolbar-menubar = [ "menubar-items" ];
              TabsToolbar = [
                "tabbrowser-tabs"
                "new-tab-button"
              ];
              PersonalToolbar = [ "personal-bookmarks" ];
            };
          };
        };

        bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Toolbar";
              toolbar = true;
              bookmarks = [
                {
                  name = "YouTube";
                  url = "https://youtube.com";
                }
                {
                  name = "MyNixOS";
                  url = "https://mynixos.com";
                }
                {
                  name = "Reddit";
                  url = "https://reddit.com/r/unixporn";
                }
                {
                  name = "Hyprland Wiki";
                  url = "https://wiki.hypr.land";
                }
                {
                  name = "Profiles";
                  url = "about:profiles";
                }
                {
                  name = "DeepL";
                  url = "https://www.deepl.com/en/translator";
                }
                {
                  name = "Maildrop";
                  url = "http://maildrop.home/";
                }
              ];
            }
          ];
        };
      };

      # ------------------------------------------------------------------------------------
      # Gemini
      # ------------------------------------------------------------------------------------
      gemini = {
        id = 1;
        name = "Gemini";
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
        ];
        settings = commonSettings // {
          "browser.startup.homepage" = "https://gemini.google.com";

          "browser.uiCustomization.state" = builtins.toJSON {
            currentVersion = 20;
            newElementCount = 5;
            placements = {
              widget-overflow-fixed-list = [ ];
              nav-bar = [
                "back-button"
                "forward-button"
                "stop-reload-button"
                "urlbar-container"
                "downloads-button"
                "unified-extensions-button"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "ublock0_raymondhill_net-browser-action"
              ];
              toolbar-menubar = [ "menubar-items" ];
              TabsToolbar = [
                "tabbrowser-tabs"
                "new-tab-button"
              ];
              PersonalToolbar = [ "personal-bookmarks" ];
            };
          };
        };
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Toolbar";
              toolbar = true;
              bookmarks = [
                {
                  name = "Google Gemini";
                  url = "https://gemini.google.com";
                }
                {
                  name = "Google AI Studio Usage";
                  url = "https://aistudio.google.com/rate-limit?timeRange=last-28-days";
                }
              ];
            }
          ];
        };
      };
      # ------------------------------------------------------------------------------------
      # Roblox
      # ------------------------------------------------------------------------------------
      roblox = {
        id = 2;
        name = "Roblox";
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
        ];
        settings = commonSettings // {
          "browser.startup.homepage" = "https://roblox.com";

          "browser.uiCustomization.state" = builtins.toJSON {
            currentVersion = 20;
            newElementCount = 5;
            placements = {
              widget-overflow-fixed-list = [ ];
              nav-bar = [
                "back-button"
                "forward-button"
                "stop-reload-button"
                "urlbar-container"
                "downloads-button"
                "unified-extensions-button"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "ublock0_raymondhill_net-browser-action"
              ];
              toolbar-menubar = [ "menubar-items" ];
              TabsToolbar = [
                "tabbrowser-tabs"
                "new-tab-button"
              ];
              PersonalToolbar = [ "personal-bookmarks" ];
            };
          };
        };
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Toolbar";
              toolbar = true;
              bookmarks = [
                {
                  name = "Roblox Quick Sign-in";
                  url = "https://roblox.com/crossdevicelogin/ConfirmCode";
                }
                {
                  name = "Roblox Visibility";
                  url = "https://roblox.com/my/account#!/privacy/VisibilityAndPrivateServers/Visibility";
                }
              ];
            }
          ];
        };
      };

      # ------------------------------------------------------------------------------------
      # edX
      # ------------------------------------------------------------------------------------
      edx = {
        id = 3;
        name = "edX";
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          return-youtube-dislikes
          enhancer-for-youtube
        ];
        settings = commonSettings // {
          "browser.startup.homepage" = "https://google.com";

          "browser.uiCustomization.state" = builtins.toJSON {
            currentVersion = 20;
            newElementCount = 5;
            placements = {
              widget-overflow-fixed-list = [ ];
              nav-bar = [
                "back-button"
                "forward-button"
                "stop-reload-button"
                "urlbar-container"
                "downloads-button"
                "unified-extensions-button"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "ublock0_raymondhill_net-browser-action"
              ];
              toolbar-menubar = [ "menubar-items" ];
              TabsToolbar = [
                "tabbrowser-tabs"
                "new-tab-button"
              ];
              PersonalToolbar = [ "personal-bookmarks" ];
            };
          };
        };
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Toolbar";
              toolbar = true;
              bookmarks = [
                {
                  name = "Proton";
                  url = "https://mail.proton.me/u/0/inbox";
                }
                {
                  name = "edX Python";
                  url = "https://learning.edx.org/course/course-v1:HarvardX+CS50P+Python/home";
                }
                {
                  name = "Visual Studio Code";
                  url = "https://fluffy-space-trout-v6jvqgjr9x7v2q9v.github.dev";
                }
                {
                  name = "CS50.ai";
                  url = "https://cs50.ai/chat";
                }
                {
                  name = "OpenVSCode";
                  url = "https://code.meowserver.xyz";
                }
                {
                  name = "Live-Server";
                  url = "https://live-server.meowserver.xyz";
                }
                {
                  name = "HTML & CSS Full Course";
                  url = "https://youtu.be/G3e-cpL7ofc?t=8742";
                }
                {
                  name = "html-css-reference.pdf";
                  url = "https://supersimpledev.github.io/references/html-css-reference.pdf";
                }
                {
                  name = "html-css-course/1-exercise-solutions at main · SuperSimpleDev/html-css-course · GitHub";
                  url = "https://github.com/SuperSimpleDev/html-css-course/tree/main/1-exercise-solutions";
                }
              ];
            }
          ];
        };
      };
      # ------------------------------------------------------------------------------------
      # AI
      # ------------------------------------------------------------------------------------

      ai = {
        id = 4;
        name = "AI";
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
        ];
        settings = commonSettings // {
          "browser.startup.homepage" = "about:blank";

          "browser.uiCustomization.state" = builtins.toJSON {
            currentVersion = 20;
            newElementCount = 5;
            placements = {
              widget-overflow-fixed-list = [ ];
              nav-bar = [
                "back-button"
                "forward-button"
                "stop-reload-button"
                "urlbar-container"
                "downloads-button"
                "unified-extensions-button"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "ublock0_raymondhill_net-browser-action"
              ];
              toolbar-menubar = [ "menubar-items" ];
              TabsToolbar = [
                "tabbrowser-tabs"
                "new-tab-button"
              ];
              PersonalToolbar = [ "personal-bookmarks" ];
            };
          };
        };
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Toolbar";
              toolbar = true;
              bookmarks = [
                {
                  name = "Claude";
                  url = "https://claude.ai/new";
                }
                {
                  name = "Claude Usage";
                  url = "https://claude.ai/settings/usage";
                }
                {
                  name = "Kimi";
                  url = "https://www.kimi.com/";
                }
                {
                  name = "Kimi Usage";
                  url = "https://www.kimi.com/code/console";
                }
                {
                  name = "ChatGPT";
                  url = "https://chatgpt.com/";
                }
                {
                  name = "ChatGPT Usage";
                  url = "https://chatgpt.com/codex/settings/usage";
                }
                {
                  name = "Gemini";
                  url = "https://gemini.google.com/";
                }
                {
                  name = "Gemini Usage";
                  url = "https://gemini.google.com/usage";
                }
              ];
            }
          ];
        };
      };
      trackers = {
        id = 5;
        name = "trackers";
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
        ];
        settings = commonSettings // {
          "browser.startup.homepage" = "about:blank";

          "browser.uiCustomization.state" = builtins.toJSON {
            currentVersion = 20;
            newElementCount = 5;
            placements = {
              widget-overflow-fixed-list = [ ];
              nav-bar = [
                "back-button"
                "forward-button"
                "stop-reload-button"
                "urlbar-container"
                "downloads-button"
                "unified-extensions-button"
                "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
                "ublock0_raymondhill_net-browser-action"
              ];
              toolbar-menubar = [ "menubar-items" ];
              TabsToolbar = [
                "tabbrowser-tabs"
                "new-tab-button"
              ];
              PersonalToolbar = [ "personal-bookmarks" ];
            };
          };
        };
        bookmarks = {
          force = true;
          settings = [
            {
              name = "Bookmarks Toolbar";
              toolbar = true;
              bookmarks = [
                {
                  name = "Seedpool";
                  url = "https://seedpool.org/";
                }
                {
                  name = "RocketHD";
                  url = "https://rocket-hd.cc/";
                }
                {
                  name = "AnimeWorld";
                  url = "https://animeworld.cx/";
                }
              ];
            }
          ];
        };
      };
    };
  };
}

# rm ~/.mozilla/firefox/*/extensions.json
# rm ~/.mozilla/firefox/*/addonStartup.json.lz4
