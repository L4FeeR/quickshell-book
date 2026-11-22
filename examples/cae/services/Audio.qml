pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property string icon: muted ? "volume_off" : volume >= 0.5 ? "volume_up" : volume > 0 ? "volume_down" : "volume_mute"

    function setVolume(v: real): void {
        if (sink?.ready && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }
    function increment(): void { setVolume(volume + Config.services.audioStep) }
    function decrement(): void { setVolume(volume - Config.services.audioStep) }
    function toggleMute(): void { if (sink?.ready) sink.audio.muted = !muted }
    function toggleMicMute(): void { if (source?.ready) source.audio.muted = !micMuted }
    function setSink(node: PwNode): void { Pipewire.preferredDefaultAudioSink = node }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
