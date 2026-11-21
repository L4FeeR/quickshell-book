# Project: Media Player

A rich media popup: blurred album-art background, colors extracted from the art, title and artist, seekable progress with timestamps, play/pause with shape morph, shuffle/loop, player switcher, and an audio visualizer.

## The popup

```qml file="modules/media/MediaPopup.qml"
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.widgets

PopupWindow {
    id: root
    required property Item anchorItem
    readonly property MprisPlayer p: Media.active

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 12
    implicitWidth: 420
    implicitHeight: 200
    color: "transparent"
    grabFocus: true
    visible: false

    function fmt(sec: real): string {
        const s = Math.max(0, Math.floor(sec))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    // accent from album art
    ColorQuantizer {
        id: palette
        source: root.p?.trackArtUrl ?? ""
        depth: 3
        rescaleSize: 64
    }
    readonly property color accent: palette.colors.length ? palette.colors[0] : Colors.primary
    readonly property color onAccent: (accent.hslLightness > 0.55) ? "#111111" : "#ffffff"

    ClippingRectangle {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Colors.surface

        // blurred, darkened art behind everything
        Image {
            id: bgArt
            anchors.fill: parent
            source: root.p?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(256, 256)
            visible: false
        }
        MultiEffect {
            anchors.fill: bgArt
            source: bgArt
            blurEnabled: true; blur: 1; blurMax: 48
            brightness: -0.35; saturation: 0.2
            visible: bgArt.status === Image.Ready
        }

        RowLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 16

            ClippingRectangle {
                Layout.preferredWidth: 140; Layout.preferredHeight: 140
                radius: Appearance.rounding.normal
                color: Colors.surfaceContainerHighest
                Image {
                    anchors.fill: parent
                    source: root.p?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(280, 280)
                    asynchronous: true
                }
                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !(root.p?.trackArtUrl)
                    icon: "music_note"; size: 48
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                RowLayout {
                    StyledText { text: root.p?.identity ?? ""; color: "#ccffffff"; font.pixelSize: Appearance.font.size.small; Layout.fillWidth: true }
                    IconButton {                                 // switch player
                        visible: Media.players.length > 1
                        icon: "swap_horiz"; size: 26
                        onClicked: {
                            const i = Media.players.indexOf(root.p)
                            Media.manualPlayer = Media.players[(i + 1) % Media.players.length]
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.p?.trackTitle || "Nothing playing"
                    color: "white"; font.bold: true; font.pixelSize: Appearance.font.size.large
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.p?.trackArtist || ""
                    color: "#ddffffff"
                }
                Item { Layout.fillHeight: true }

                // progress
                StyledSlider {
                    id: seek
                    Layout.fillWidth: true
                    enabled: root.p?.canSeek ?? false
                    from: 0; to: Math.max(1, root.p?.length ?? 1)
                    value: root.p?.position ?? 0
                    onMoved: root.p.position = value
                }
                RowLayout {
                    StyledText { text: root.fmt(root.p?.position ?? 0); color: "#ccffffff"; font.pixelSize: Appearance.font.size.tiny }
                    Item { Layout.fillWidth: true }
                    StyledText { text: root.fmt(root.p?.length ?? 0); color: "#ccffffff"; font.pixelSize: Appearance.font.size.tiny }
                }

                // controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    IconButton {
                        visible: root.p?.shuffleSupported ?? false
                        icon: "shuffle"; size: 30
                        toggled: root.p?.shuffle ?? false
                        onClicked: root.p.shuffle = !root.p.shuffle
                    }
                    IconButton { icon: "skip_previous"; size: 34; onClicked: root.p.previous() }
                    Rectangle {
                        implicitWidth: 48; implicitHeight: 48
                        radius: root.p?.isPlaying ? 16 : 24          // morph: circle ↔ squircle
                        color: root.accent
                        Behavior on radius { Anim {} }
                        Behavior on color { CAnim {} }
                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: root.p?.isPlaying ? "pause" : "play_arrow"
                            fill: 1; size: 28
                            color: root.onAccent
                        }
                        StateLayer { tint: root.onAccent; onClicked: root.p.togglePlaying() }
                    }
                    IconButton { icon: "skip_next"; size: 34; onClicked: root.p.next() }
                    IconButton {
                        visible: root.p?.loopSupported ?? false
                        icon: root.p?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                        size: 30
                        toggled: (root.p?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                        onClicked: root.p.loopState = root.p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                                                    : root.p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
                                                    : MprisLoopState.None
                    }
                }
            }
        }
    }
}
```

Open it from the bar's media chip:

```qml
// in MediaChip.qml
MediaPopup { id: mediaPopup; anchorItem: root }
TapHandler { acceptedButtons: Qt.LeftButton; onTapped: mediaPopup.visible = !mediaPopup.visible }
```

## A visualizer with cava

`cava` can write raw bar heights to stdout. Configure it for ASCII output:

```ini file="~/.config/quickshell/myshell/scripts/cava.conf"
[general]
bars = 24
framerate = 60
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
```

```qml file="modules/media/Visualizer.qml"
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Row {
    id: root
    property bool active: true
    property var bars: []
    spacing: 3
    height: 40

    Process {
        running: root.active && (Media.active?.isPlaying ?? false)
        command: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]
        stdout: SplitParser {
            onRead: line => root.bars = line.split(";").filter(x => x !== "").map(Number)
        }
    }

    Repeater {
        model: root.bars.length
        Rectangle {
            required property int index
            width: 5
            height: Math.max(3, root.height * (root.bars[index] ?? 0) / 100)
            anchors.bottom: parent.bottom
            radius: 2.5
            color: Colors.primary
            Behavior on height { NumberAnimation { duration: 60 } }
        }
    }
}
```

The process only runs while something is playing and the visualizer is visible. For lighter CPU use, try [[PwNodePeakMonitor]] on the default sink for a single level meter, no external program needed:

```qml
PwNodePeakMonitor { id: peaks; node: Pipewire.defaultAudioSink; enabled: popup.visible }
Rectangle { width: 6; height: 40 * peaks.peak; color: Colors.primary }
```

> [!WILD] In the wild
> Caelestia ships a C++ plugin for its visualizer and beat detection so it costs almost no CPU; end-4 uses cava through a Process for its media controls.

> [!TRY] Exercises
> 1. Add a volume slider bound to `player.volume` when `volumeSupported`.
> 2. Show a list of all players and let the user pick one.
> 3. Animate the cover art (scale + fade) on `trackChanged`.
