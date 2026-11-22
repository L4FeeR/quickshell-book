pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The music player the widgets follow, and its position. Spotify, Firefox,
// mpv (with mpv-mpris) and most players speak MPRIS over D-Bus.
Singleton {
    id: root

    // prefer Spotify when it's playing, then anything playing, then the first player
    readonly property MprisPlayer active: {
        const all = Mpris.players.values;
        return all.find(p => p.isPlaying && p.identity === "Spotify")
            ?? all.find(p => p.isPlaying) ?? all[0] ?? null;
    }
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string album: active?.trackAlbum ?? ""
    readonly property string artUrl: active?.trackArtUrl ?? ""
    readonly property real length: active?.length ?? 0          // seconds
    // MPRIS doesn't push the position while playing: we ask for it often
    property real position: 0

    Timer {
        interval: 250                     // 4 times a second: smooth enough for lyrics
        running: root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.active.positionChanged();     // asks the player for a fresh value
            root.position = root.active.position;
        }
    }
    // a new track or a seek: read the position at once
    Connections {
        target: root.active
        function onPostTrackChanged() { root.position = 0; }
        function onPositionChanged() { root.position = root.active.position; }
    }

    function seek(seconds) {
        if (active?.canSeek)
            active.position = Math.max(0, Math.min(length, seconds));
    }

    // 197 → "3:17"
    function format(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}
