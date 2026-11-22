pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Services.Pipewire

// The default output (speakers/headphones) and input (microphone).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property real step: 0.05

    // a node must be tracked before its volume can be read or changed
    PwObjectTracker { objects: [root.sink, root.source] }

    function setVolume(v) {
        if (sink?.ready) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }
    function increaseVolume() { setVolume(volume + step); }
    function decreaseVolume() { setVolume(volume - step); }
    function toggleMute() { if (sink?.ready) sink.audio.muted = !muted; }
    function toggleSourceMute() { if (source?.ready) source.audio.muted = !micMuted; }

    // the icon for a volume level (Nerd Font glyphs)
    function volumeIcon(v, isMuted) {
        return isMuted || v <= 0 ? "\u{f075f}" : v < 0.34 ? "\u{f057f}" : v < 0.67 ? "\u{f0580}" : "\u{f057e}";
    }
}
