pragma Singleton

import QtQml
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property MprisPlayer active: {
        if (list.length === 0) return null;
        
        const sorted = [...list].sort((a, b) => {
            function getScore(p: MprisPlayer): int {
                const id = p.identity.toLowerCase();
                if (id.includes("spotify")) return 100;
                if (id.includes("vlc") || id.includes("mpv") || id.includes("mpd") || id.includes("rhythmbox") || id.includes("cmus") || id.includes("audacious") || id.includes("clementine")) return 90;
                if (id.includes("firefox") || id.includes("chrome") || id.includes("chromium") || id.includes("brave") || id.includes("vivaldi") || id.includes("edge")) return 10;
                return 50; // default for unknown players
            }
            
            // If one is playing and the other is not, the playing one always wins regardless of identity
            if (a.isPlaying && !b.isPlaying) return -1;
            if (!a.isPlaying && b.isPlaying) return 1;
            
            // Otherwise sort by identity score
            return getScore(b) - getScore(a);
        });
        
        return sorted[0];
    }

    function getArtUrl(player: MprisPlayer): string {
        if (!player)
            return "";
        if (player.trackArtUrl)
            return player.trackArtUrl;
        
        const mprisArtUrl = player.metadata["mpris:artUrl"] ?? "";
        if (mprisArtUrl)
            return mprisArtUrl;

        const url = player.metadata["xesam:url"] ?? "";
        if (url.startsWith("https://www.youtube.com/watch")) {
            // Fallback for youtube
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
        }
        return "";
    }
}
