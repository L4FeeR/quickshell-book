# Singletons and Global State

Your bar shows the volume. So do the OSD, the control center and the lock screen. Your theme colors are used in every file. The question "is the launcher open?" matters to the bar button, the launcher window and a keybind. Passing all of that through properties would be a nightmare. **Singletons** solve it: one global object, accessible by name from any file.

## What a singleton is

You already use Quickshell's singletons: `Quickshell`, `Hyprland`, `UPower`, `Pipewire`, `Mpris`, `SystemTray`, `DesktopEntries`… There's exactly one of each, and you refer to them by type name without creating them.

You can write your own the same way.

## Writing a singleton

```qml file="services/GlobalStates.qml"
pragma Singleton                       // 1. this line makes the file a singleton

import Quickshell
import QtQuick

Singleton {                            // 2. root type: Quickshell's Singleton
    id: root

    property bool launcherOpen: false
    property bool sidebarOpen: false
    property bool dnd: false

    function toggleLauncher(): void {
        launcherOpen = !launcherOpen
    }
}
```

Use it from any file that imports its folder:

```qml file="modules/bar/LauncherButton.qml"
import QtQuick
import qs.services                      // the folder containing GlobalStates.qml

Text {
    text: GlobalStates.launcherOpen ? "close" : "apps"
    font.family: "Material Symbols Rounded"
    TapHandler { onTapped: GlobalStates.toggleLauncher() }
}
```

```qml file="modules/launcher/Launcher.qml"
import Quickshell
import qs.services

PanelWindow {
    visible: GlobalStates.launcherOpen   // the same global state
    // …
}
```

Both files bind to the same property. Toggle it anywhere and both update.

## Rules

1. `pragma Singleton` as the **first** non-comment line.
2. The root object is [[Singleton]] (Quickshell's reload-aware singleton root).
3. The file lives in a folder you **import** (`import qs.services` or `import "services"`). Quickshell detects the pragma automatically; you don't need a `qmldir` file.
4. Refer to it by **file name**: `services/Audio.qml` becomes `Audio`.

## Singletons are lazy

A singleton is created the **first time something uses it**. If nothing references it, it never runs. That's usually great, but it matters for things that must start at login, like a notification server or a battery warning:

```qml file="shell.qml"
import Quickshell
import qs.services

ShellRoot {
    // reference it once so it starts immediately
    Component.onCompleted: Notifs.init()
    // or simply bind something to it:  property var _keepAlive: [Notifs, BatteryWarning]
}
```

## The service pattern

The most important use of singletons in real shells is **services**: a singleton that wraps one area of the system and exposes clean properties and functions. UI files read services and never talk to the system directly.

```qml file="services/Audio.qml"
pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string icon: muted ? "volume_off"
                                 : volume > 0.6 ? "volume_up"
                                 : volume > 0 ? "volume_down" : "volume_mute"

    function setVolume(v: real): void {
        if (ready) sink.audio.volume = Math.max(0, Math.min(1.5, v))
    }
    function toggleMute(): void {
        if (ready) sink.audio.muted = !sink.audio.muted
    }

    PwObjectTracker { objects: [root.sink] }     // required for PipeWire, see Chapter 41
}
```

Now every UI file just writes `Audio.volume`, `Audio.icon`, `Audio.setVolume(…)`:

<div class="diagram"><svg viewBox="0 0 800 210" role="img" aria-label="service pattern">
<rect class="n" x="20" y="80" width="160" height="50" rx="10"/><text x="40" y="110">PipeWire / D-Bus</text>
<rect class="g" x="250" y="80" width="170" height="50" rx="10"/><text x="270" y="102">services/Audio.qml</text><text class="sm" x="270" y="120">singleton</text>
<rect class="a" x="500" y="10" width="270" height="44" rx="10"/><text x="520" y="37">bar/VolumeIcon.qml</text>
<rect class="a" x="500" y="83" width="270" height="44" rx="10"/><text x="520" y="110">osd/Osd.qml</text>
<rect class="a" x="500" y="156" width="270" height="44" rx="10"/><text x="520" y="183">sidebar/Sliders.qml</text>
<path class="ln" d="M180 105 H250 M420 105 L500 32 M420 105 H500 M420 105 L500 178"/>
</svg></div>

Benefits:

- **One place** to fix bugs and change behavior.
- **Swap implementations** without touching UI (e.g. switch Wi-Fi from `nmcli` to the Networking module).
- **Derived values** (like `icon`) computed once and shared.

> [!WILD] In the wild
> end-4's `services/` folder has `Audio`, `Battery`, `Brightness`, `Network`, `Notifications`, `MprisController`, `HyprlandData`, `Ai` and more, all singletons. Caelestia's `services/` has the same idea. Read them after Part VII.

## Singletons that use each other

Singletons can reference other singletons:

```qml file="services/Colors.qml"
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property color accent: Config.appearance.accent     // Config is another singleton
    readonly property color barBg: Qt.rgba(0.1, 0.1, 0.15, Config.appearance.transparency)
}
```

Avoid **circular** dependencies (A reads B while B reads A during creation), which can cause binding loops or `undefined` values.

## What belongs in a singleton?

| Put in a singleton | Keep local |
|---|---|
| System state (audio, battery, network, media) | Hover and pressed state of a button |
| Panel open/closed states | Animation progress |
| Theme colors, sizes, fonts | Layout details of one component |
| User config | Temporary text in a text field |
| Shared helper functions (formatting) | |

## Alternatives

- **Properties down, signals up** for parent/child relationships ([[ch:12-components]]).
- **[[PersistentProperties]]** for state that must survive reloads.
- **[[FileView]] + [[JsonAdapter]]** for state that must survive restarts, often *inside* a singleton ([[ch:38-files-json]]).

## Practice

::: exercise warm | GlobalStates
Create `services/GlobalStates.qml` with `property bool calendarOpen` and toggle it from a bar button.
--- solution
```qml
pragma Singleton
import Quickshell
Singleton { property bool calendarOpen: false }
```
```qml
import qs.services
TapHandler { onTapped: GlobalStates.calendarOpen = !GlobalStates.calendarOpen }
```
:::

::: exercise practice | Time service
Write `services/Time.qml` that owns one `SystemClock` and exposes `time` and `date` strings. Use it in two places.
--- solution
```qml
pragma Singleton
import Quickshell
import QtQuick
Singleton {
    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property string time: Qt.formatTime(clock.date, "hh:mm")
    readonly property string date: Qt.formatDate(clock.date, "ddd d MMM")
}
```
:::

::: exercise challenge | Audio service
Write the `Audio` service from this chapter and show `Audio.icon` plus a percentage in your bar; scroll changes volume.
--- solution
```qml
Row { spacing: 4
    Text { text: Audio.icon; font.family: "Material Symbols Rounded"; color: "white" }
    Text { text: Math.round(Audio.volume * 100) + "%"; color: "white" }
    WheelHandler { onWheel: e => Audio.setVolume(Audio.volume + e.angleDelta.y / 120 * 0.05) } }
```
:::
