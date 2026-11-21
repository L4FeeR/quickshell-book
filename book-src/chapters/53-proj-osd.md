# Project: Volume and Brightness OSD

An on-screen display that pops up when volume, mute, brightness or the microphone changes, from **anywhere** (media keys, pavucontrol, scripts), shows the level, and fades away after 1.5 seconds. It needs no special keybinds: it watches the system state.

## Brightness service

```qml file="services/Brightness.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string device: ""                  // auto-detected below
    property int max: 1
    property int current: 0
    readonly property real value: max > 0 ? current / max : 0
    readonly property bool available: device !== ""

    function set(v: real): void {
        if (!available) return
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100)
        Quickshell.execDetached(["brightnessctl", "-d", device, "set", pct + "%"])
    }

    // find the first backlight device
    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -1"]
        stdout: StdioCollector { onStreamFinished: root.device = text.trim() }
    }
    FileView {
        path: root.available ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text())
    }
    FileView {
        path: root.available ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = parseInt(text())
    }
}
```

> [!NOTE] External monitors
> For external monitors use `ddcutil` (`ddcutil getvcp 10`, `ddcutil setvcp 10 70`). It's slow (hundreds of ms), so debounce changes with a Timer and poll rarely.

## The OSD

```qml file="modules/osd/Osd.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    id: root
    property string kind: "volume"          // volume | brightness | mic
    property bool shown: false
    property bool armed: false              // ignore the initial "changes" at startup

    function show(k: string): void {
        if (!armed || GlobalStates.locked) return
        kind = k
        shown = true
        hide.restart()
    }

    Timer { interval: 2000; running: true; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }

    Connections {
        target: Audio
        function onVolumeChanged() { root.show("volume") }
        function onMutedChanged() { root.show("volume") }
    }
    Connections {
        target: Pipewire.defaultAudioSource?.audio ?? null
        function onMutedChanged() { root.show("mic") }
    }
    Connections {
        target: Brightness
        function onCurrentChanged() { root.show("brightness") }
    }
    PwObjectTracker { objects: [Pipewire.defaultAudioSource] }

    readonly property real level: kind === "volume" ? (Audio.muted ? 0 : Audio.volume)
                                : kind === "brightness" ? Brightness.value
                                : (Pipewire.defaultAudioSource?.audio?.muted ? 0 : 1)
    readonly property string icon: kind === "brightness" ? (level > 0.5 ? "brightness_high" : "brightness_low")
                                 : kind === "mic" ? (level > 0 ? "mic" : "mic_off")
                                 : Audio.icon

    LazyLoader {
        active: root.shown || fadeOut.running

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            anchors.bottom: true
            margins.bottom: 90
            implicitWidth: 320
            implicitHeight: 64
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}                                // purely visual, never blocks clicks
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:osd"

            StyledRect {
                id: pill
                anchors.fill: parent
                anchors.margins: 6
                level: 2
                radius: height / 2
                color: Colors.surfaceContainer

                opacity: root.shown ? 1 : 0
                y: root.shown ? 0 : 12
                Behavior on opacity { NumberAnimation { id: fadeOut; duration: 200 } }
                Behavior on y { Anim {} }

                RowLayout {
                    anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                    spacing: 14
                    MaterialIcon { icon: root.icon; fill: 1; size: 24; color: Colors.primary }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: 4
                        color: Colors.surfaceContainerHighest
                        visible: root.kind !== "mic"
                        Rectangle {
                            width: parent.width * Math.min(1, root.level)
                            height: parent.height
                            radius: 4
                            color: root.level > 1 ? Colors.error : Colors.primary   // over-amplified volume
                            Behavior on width { Anim { duration: Appearance.anim.fast } }
                        }
                    }
                    StyledText {
                        Layout.fillWidth: root.kind === "mic"
                        text: root.kind === "mic" ? (root.level > 0 ? "Microphone on" : "Microphone muted")
                                                  : Math.round(root.level * 100)
                        font.bold: true
                        font.features: ({ "tnum": 1 })
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: root.kind === "mic" ? -1 : 34
                    }
                }
            }
        }
    }
}
```

## Media keys

The OSD reacts to state, so keybinds only change the state:

```ini file="hyprland.conf"
bindel = , XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl  = , XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindl  = , XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindel = , XF86MonBrightnessUp,   exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bindl  = , XF86AudioPlay,         exec, playerctl play-pause
bindl  = , XF86AudioNext,         exec, playerctl next
bindl  = , XF86AudioPrev,         exec, playerctl previous
```

## Variants

- **Vertical OSD** on the right edge: anchor `right`, swap the RowLayout for a ColumnLayout, and fill the track bottom-up.
- **Media OSD:** show album art and title when the track changes (`Connections { target: Media.active; function onTrackChanged() {…} }`).
- **Caps Lock / keyboard layout OSD:** Hyprland `activelayout` events.

> [!TRY] Exercises
> 1. Add a keyboard-layout OSD.
> 2. Show which output device changed when `Pipewire.defaultAudioSink` changes (headphones plugged in).
> 3. Scroll on the OSD to adjust the shown value (remove the empty mask first).
