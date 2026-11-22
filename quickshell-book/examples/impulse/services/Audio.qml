pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false

    function setVolume(v: real): void {
        if (sink?.ready) sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute(): void { if (sink?.ready) sink.audio.muted = !muted }
    function toggleMicMute(): void { if (source?.ready) source.audio.muted = !micMuted }

    PwObjectTracker { objects: [root.sink, root.source] }
}
