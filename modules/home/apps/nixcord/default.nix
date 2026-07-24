{ inputs, pkgs, ... }:

let
  # Workaround for NixCord bug: local path literals in userPlugins lose
  # sandbox dependency tracking because NixCord uses lib.escapeShellArg.
  # Wrapping in a derivation (also documented as valid) fixes this.
  followUserPlugin = pkgs.writeTextDir "index.tsx" (builtins.readFile ./plugins/followUser/index.tsx);
in
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  programs.nixcord = {
    enable = true;

    # Standard Discord patched with Equicord only
    discord.vencord.enable = false;
    discord.equicord.enable = true;

    userPlugins.followUser = followUserPlugin;

    config.plugins = {
      # Vencord Plugins
      clearUrls.enable = true;
      disableCallIdle.enable = true;
      forceOwnerCrown.enable = true;
      #  friendsSince.enable = true;
      keepCurrentChannel.enable = true;
      mutualGroupDms.enable = true;
      noMiddleClickPaste.enable = true;
      noF1.enable = true;
      noDevtoolsWarning.enable = true;
      reverseImageSearch.enable = true;
      youtubeAdblock.enable = true;
      notificationVolume = {
        enable = true;
        notificationVolume = 30.0;
      };
      messageLogger.enable = true;
      callTimer.enable = true;
      anonymiseFileNames.enable = true;
      betterSessions.enable = true;
      fakeNitro.enable = true;
      fixImagesQuality.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds.enable = true;
      gameActivityToggle.enable = true;
      imageZoom.enable = true;
      noPendingCount.enable = true;
      pinDms.enable = true;
      platformIndicators.enable = true;
      relationshipNotifier.enable = true;
      reviewDb.enable = true;
      serverInfo.enable = true;
      showHiddenChannels.enable = true;
      sortFriends.enable = true;
      spotifyCrack.enable = true;
      viewIcons.enable = true;
      volumeBooster.enable = true;

      # Equicord Plugins
      cancelFriendRequest.enable = true;
      favouriteAnything.enable = true;
      ignoreCalls.enable = true;
      unlimitedAccounts.enable = true;
      voiceRejoin.enable = true;
      whosWatching.enable = true;
      platformSpoofer = {
        enable = true;
        platform = "ios";
      };

      questify = {
        enable = true;
        allowChangingDangerousSettings = true;
        completeVideoQuestsQuicker = true;
        makeMobileVideoQuestsDesktopCompatible = true;
        autoCompleteQuestTypes = {
          PLAY_ON_DESKTOP = true;
          PLAY_ON_XBOX = true;
          PLAY_ON_PLAYSTATION = true;
          PLAY_ACTIVITY = true;
          WATCH_VIDEO = true;
          WATCH_VIDEO_ON_MOBILE = true;
          ACHIEVEMENT_IN_ACTIVITY = true;
        };
      };

      waitForSlot = {
        enable = true;
        autoJoin = true;
      };
    };

    extraConfig.plugins.followUser.enable = true;
  };
}
