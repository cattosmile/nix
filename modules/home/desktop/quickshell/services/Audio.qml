pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // Keep the sink object tracked so its nested properties emit change notifications.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function setVolume(newVolume: real): void {
        if (sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + amount);
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - amount);
    }

    function toggleMute(): void {
        if (sink?.audio) {
            sink.audio.muted = !sink.audio.muted;
        }
    }
}
