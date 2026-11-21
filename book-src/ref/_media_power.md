=== Mpris
@@@ intro
Lists every **media player** that speaks MPRIS: Spotify, Firefox and Chromium tabs, mpv, VLC, music players. Each is an [[MprisPlayer]].

@@@ example Example
```qml
import Quickshell.Services.Mpris
import QtQuick

Column {
    Text { text: Mpris.players.values.length + " players" }
    Repeater {
        model: Mpris.players
        Text { required property MprisPlayer modelData; text: modelData.identity + (modelData.isPlaying ? " ▶" : "") }
    }
}
```

@@@ notes
Pick the "active" player with `Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0]`.

=== MprisPlayer
@@@ intro
One media player. Read the current track's metadata and playback state, and control playback. Get players from [[Mpris.players]].

@@@ example Example: every property and function
```qml
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FloatingWindow {
    implicitWidth: 560; implicitHeight: 640
    color: "#1e1e2e"
    readonly property MprisPlayer p: Mpris.players.values[0] ?? null

    // position isn't pushed continuously: refresh it while playing
    Timer { running: p?.isPlaying ?? false; interval: 1000; repeat: true; onTriggered: p.positionChanged() }

    ColumnLayout {
        anchors { fill: parent; margins: 14 }
        visible: p !== null
        spacing: 3
        // ---- identity ----
        Text { color: "white"; text: "identity: " + p?.identity + " · desktopEntry: " + p?.desktopEntry + " · dbus: " + p?.dbusName }
        // ---- track ----
        Image { source: p?.trackArtUrl ?? ""; Layout.preferredWidth: 120; Layout.preferredHeight: 120; fillMode: Image.PreserveAspectCrop }
        Text { color: "white"; text: "title: " + (p?.trackTitle || "Unknown title") }
        Text { color: "white"; text: "artist: " + (p?.trackArtist || "Unknown artist") }
        Text { color: "white"; text: "album: " + p?.trackAlbum + " · album artist: " + p?.trackAlbumArtist }
        Text { color: "white"; text: "uniqueId: " + p?.uniqueId + " · metadata keys: " + Object.keys(p?.metadata ?? {}).join(", ") }
        // ---- position ----
        Slider {
            Layout.fillWidth: true
            enabled: (p?.canSeek ?? false) && (p?.positionSupported ?? false)
            from: 0; to: p?.lengthSupported ? p.length : 1
            value: p?.position ?? 0
            onMoved: p.position = value                     // seconds
        }
        Text { color: "white"; text: `position ${p?.position?.toFixed(1)}s / length ${p?.length?.toFixed(1)}s` }
        // ---- state ----
        Text { color: "white"; text: "state: " + MprisPlaybackState.toString(p?.playbackState) + " · isPlaying " + p?.isPlaying }
        Text { color: "white"; text: "loop: " + MprisLoopState.toString(p?.loopState) + " (supported " + p?.loopSupported + ")" }
        Text { color: "white"; text: "shuffle: " + p?.shuffle + " (supported " + p?.shuffleSupported + ")" }
        Text { color: "white"; text: `rate ${p?.rate} (min ${p?.minRate}, max ${p?.maxRate}) · fullscreen ${p?.fullscreen}` }
        Slider { from: 0; to: 1; enabled: p?.volumeSupported ?? false; value: p?.volume ?? 1; onMoved: p.volume = value }
        // ---- capabilities ----
        Text { color: "#a6adc8"; text: `canControl ${p?.canControl} canPlay ${p?.canPlay} canPause ${p?.canPause} canTogglePlaying ${p?.canTogglePlaying}` }
        Text { color: "#a6adc8"; text: `canSeek ${p?.canSeek} canGoNext ${p?.canGoNext} canGoPrevious ${p?.canGoPrevious} canQuit ${p?.canQuit} canRaise ${p?.canRaise} canSetFullscreen ${p?.canSetFullscreen}` }
        Text { color: "#a6adc8"; text: "uri schemes: " + p?.supportedUriSchemes.join(",") + " · mime: " + p?.supportedMimeTypes.length }
        // ---- controls ----
        RowLayout {
            Button { text: "⏮"; enabled: p?.canGoPrevious ?? false; onClicked: p.previous() }
            Button { text: "-10s"; onClicked: p.seek(-10) }
            Button { text: p?.isPlaying ? "⏸" : "▶"; onClicked: p.togglePlaying() }   // or play() / pause()
            Button { text: "⏹"; onClicked: p.stop() }
            Button { text: "+10s"; onClicked: p.seek(10) }
            Button { text: "⏭"; enabled: p?.canGoNext ?? false; onClicked: p.next() }
            Button { text: "raise"; enabled: p?.canRaise ?? false; onClicked: p.raise() }
            Button { text: "quit"; enabled: p?.canQuit ?? false; onClicked: p.quit() }
        }
    }
    Connections { target: p; function onTrackChanged() { console.log("new track:", p.trackTitle) } }
}
```

@@@ member position
In seconds. Not updated continuously (for efficiency): call `positionChanged()` on a Timer while playing to make bindings refresh. Setting it seeks (if `canSeek`).

@@@ member trackArtUrl
Can be `file://`, `http(s)://` or empty. Images load asynchronously; show a placeholder.

@@@ member trackTitle
Empty string if the player didn't provide one: `p.trackTitle || "Unknown title"`.

@@@ member trackChanged
Emitted when the track changes; `postTrackChanged` comes after all track properties are updated.

@@@ see
[[ch:54-proj-media]] · [[MprisPlaybackState]] · [[MprisLoopState]]

=== UPower
@@@ intro
Access to the **UPower** service: your combined battery (`displayDevice`), every power device (`devices`), and whether you're on battery.

@@@ example Example: every property
```qml
import Quickshell.Services.UPower
import QtQuick

Column {
    Text { text: "on battery: " + UPower.onBattery }
    Text { text: "battery: " + Math.round(UPower.displayDevice.percentage * 100) + "% (" + UPowerDeviceState.toString(UPower.displayDevice.state) + ")" }
    Repeater {
        model: UPower.devices
        Text { required property UPowerDevice modelData; text: UPowerDeviceType.toString(modelData.type) + " " + modelData.model }
    }
}
```

@@@ see
[[UPowerDevice]] · [[PowerProfiles]]

=== PowerProfiles
@@@ intro
Read and switch the system **power profile** (power-profiles-daemon): Power Saver, Balanced, Performance.

@@@ example Example: every property
```qml
import Quickshell.Services.UPower
import QtQuick

Column {
    Text { text: "profile: " + PowerProfile.toString(PowerProfiles.profile) }
    Text { text: "has performance: " + PowerProfiles.hasPerformanceProfile }
    Text { text: "degraded: " + PerformanceDegradationReason.toString(PowerProfiles.degradationReason) }   // e.g. LapDetected
    Text { text: "holds: " + PowerProfiles.holds.length }               // other apps requesting a profile
    Row {
        Repeater {
            model: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
            Text {
                required property int modelData
                visible: modelData !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                text: "[" + PowerProfile.toString(modelData) + "] "
                font.bold: PowerProfiles.profile === modelData
                TapHandler { onTapped: PowerProfiles.profile = modelData }
            }
        }
    }
}
```

@@@ member profile
Setting `Performance` fails if `hasPerformanceProfile` is false.

@@@ notes
Requires `power-profiles-daemon` (or tuned-ppd) running.
