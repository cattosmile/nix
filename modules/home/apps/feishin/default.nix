{
  config,
  pkgs,
  inputs,
  ...
}:
{

  home.packages = [
    inputs.kopuz.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.yt-dlp
  ];

  xdg.configFile."kopuz/config.json".text = ''
    {
      "server": {
        "name": "Navidrome",
        "url": "http://192.168.1.5:4533",
        "service": "Subsonic",
        "access_token": "J1*s%HZroq1@SfnRKaf&",
        "user_id": "delu",
        "id": "dab37b37-c1fc-4e14-a6e8-aa599dc4ab40",
        "yt_browser": null,
        "yt_anonymous": false
      },
      "servers": [
        {
          "id": "dab37b37-c1fc-4e14-a6e8-aa599dc4ab40",
          "name": "Navidrome",
          "url": "http://192.168.1.5:4533",
          "service": "Subsonic",
          "yt_browser": null,
          "yt_anonymous": false
        }
      ],
      "active_source": "Server",
      "source_explicitly_set": true,
      "music_directory": [],
      "theme": "catppuccin",
      "device_id": "3e5fef58-bd32-4ee4-91ad-f4d381b68943",
      "discord_presence": true,
      "discord_presence_paused": true,
      "sort_order": "Title",
      "artist_view_order": "Tracks",
      "listen_counts": {},
      "musicbrainz_token": "",
      "lastfm_api_key": "",
      "lastfm_api_secret": "",
      "lastfm_session_key": "",
      "librefm_api_key": "",
      "librefm_api_secret": "",
      "librefm_session_key": "",
      "language": "en",
      "reduce_animations": false,
      "tracing_enabled": false,
      "auto_check_updates": true,
      "show_source_toggle": false,
      "sidebar_order": [
        "home",
        "search",
        "library",
        "albums",
        "artists",
        "playlists",
        "favorites",
        "radio",
        "activity",
        "ytdlp"
      ],
      "volume": 0.19,
      "volume_scroll_step": 0.05,
      "crossfade_seconds": 3,
      "custom_themes": {},
      "back_behavior": "AlwaysPrev",
      "channel_mode": "Stereo",
      "equalizer": {
        "enabled": false,
        "preset": "Custom",
        "bands": [
          8.0,
          4.5,
          2.0,
          -0.5,
          -1.5
        ],
        "preamp_db": -4.0
      },
      "ytdlp_output_dir": "",
      "ytdlp_options": {
        "embed_metadata": true,
        "embed_thumbnail": true,
        "postprocess_thumbnail_square": false,
        "embed_chapters": false,
        "embed_subs": false,
        "embed_info_json": false,
        "write_thumbnail": false,
        "write_description": false,
        "write_info_json": false,
        "write_subs": false,
        "write_auto_subs": false,
        "write_comments": false,
        "sponsorblock": false,
        "sponsorblock_mark": false,
        "split_chapters": false,
        "convert_thumbnail": "",
        "no_playlist": false,
        "xattrs": false,
        "no_mtime": false,
        "rate_limit": "",
        "cookies_from_browser": "",
        "js_runtimes": "",
        "audio_quality": 0
      },
      "ytdlp_history": [],
      "titlebar_mode": "Off",
      "offline_quality": "Original",
      "offline_tracks": {},
      "player_bar_position": "Bottom",
      "ui_style": "Normal",
      "hero_height": 300,
      "home_sections": [
        {
          "key": "hero",
          "enabled": true
        },
        {
          "key": "continue_listening",
          "enabled": true
        },
        {
          "key": "listen_now",
          "enabled": true
        },
        {
          "key": "top_artists",
          "enabled": true
        },
        {
          "key": "new_releases",
          "enabled": true
        },
        {
          "key": "made_for_you",
          "enabled": true
        },
        {
          "key": "recently_added",
          "enabled": true
        },
        {
          "key": "playlists",
          "enabled": true
        }
      ],
      "recently_played": [],
      "recently_played_server": [],
      "listen_now_style": "List",
      "artist_photo_source": "ArtistPhoto",
      "auto_fetch_covers": true,
      "cover_fetch_strategy": "LastFmFirst",
      "radio_registries": [
        {
          "url": "https://raw.githubusercontent.com/Kopuz-org/kopuz/refs/heads/master/radio-registry/index.json",
          "enabled": true,
          "is_default": true
        }
      ],
      "prefer_local_lyrics": false,
      "enable_musixmatch_lyrics": false
    }
  '';
}
