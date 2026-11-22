# Caelestia 2: Tokens, Colours and Building Blocks

Before any panel, Caelestia sets up a small design system. Every size, radius, font, colour and animation in the shell comes from three places: **Tokens** (numbers), **Colours** (the Material 3 palette) and a handful of **building blocks** that already use both. Build these first and the rest of the shell becomes short and consistent.

```text
config/      Tokens.qml  Config.qml
components/  Anim  CAnim  StyledRect  StyledText  MaterialIcon  StateLayer  IconButton  ScreenState
services/    Colours  Visibilities  Hypr
```

## Module 1: Tokens

Material 3 names its sizes on a fixed scale (extra small 4 px, small 8, medium 12, large 16, extra large 28). Caelestia uses exactly these names, and so does the rebuild.

@include cae/config/Tokens.qml

::: walk
@ 11-13 | Live scaling
Two user options feed the tokens: `roundingScale` multiplies every corner radius and `animationSpeed` divides every duration. Because tokens are bindings, moving those settings restyles the whole shell immediately ([[ch:set4-pages]] adds the sliders).
@ 15-22 | Rounding
`QtObject` groups related values so you can write `Tokens.rounding.large`. `full: 1000` is "as round as possible": any rectangle with a radius larger than half its height becomes a pill.
@ 40-52 | Fonts
`sans` comes from the config (`appearance.font`, default Rubik; Caelestia itself uses Google Sans Flex), so the settings app can switch the shell's font live.
@ 54-73 | Motion
These are the real Material 3 **expressive** motion curves, with the same numbers Caelestia uses. Each list is a cubic bézier for `Easing.BezierSpline`: two control points `(x1, y1, x2, y2)` and the end point `(1, 1)`. A y-value above 1 (like `1.67`) means the curve **overshoots**: a moving panel goes slightly past its target and settles back, which is what makes Caelestia feel springy. Effects curves never overshoot, because opacity above 100% makes no sense. `emphasized` has two segments (12 numbers) and is used for things leaving the screen.
@ 75-83 | Component sizes
Sizes that more than one file needs, like the bar width and the dashboard width.
:::

> [!NOTE] In the original
> Caelestia's tokens live in the C++ plugin (`plugin/src/Caelestia/Config/tokens.hpp`) so users can override any of them in `shell.json`. The values are the same as here.

## Module 2: Config

Tokens are for designers; **Config** is for users. It reads `~/.config/cae/shell.json`, creates it with defaults on the first run, and reloads it whenever you save it.

@include cae/config/Config.qml

::: walk
@ 11-20 | Aliases
Each `property alias` exposes one section of the JSON, so other files write `Config.border.thickness` instead of `Config.adapter.border.thickness`.
@ 24-34 | Live file
`watchChanges` + `onFileChanged: reload()` reloads the file when you save it in an editor. `onAdapterUpdated: writeAdapter()` saves changes made from QML (for example a toggle in the UI). On the very first run the file doesn't exist, so `onLoadFailed` creates the folder and writes the defaults.
@ 36-48 | JSON sections
`JsonObject` maps to a nested JSON object. The bar's `entries` list decides which modules the bar shows and in which order, which is how Caelestia lets users rearrange the bar without touching QML.
:::

After the first run, `~/.config/cae/shell.json` looks like this (shortened):

```json
{
  "border": { "thickness": 10, "rounding": 25 },
  "bar": {
    "persistent": true,
    "entries": ["logo", "workspaces", "spacer", "activeWindow", "spacer", "tray", "clock", "statusIcons", "power"],
    "workspacesShown": 5
  },
  "dashboard": { "showOnHover": true }
}
```

## Module 3: Colours

@include cae/services/Colours.qml

::: walk
@ 12-14 | The palette object
`palette` holds all Material 3 colour roles. They're defined in an **inline component** (`component M3Palette` at the bottom) and created once. Other files use `Colours.palette.m3primary`, `Colours.palette.m3surfaceContainer` and so on.
@ 16-17 | The surface colour
The frame and every drawer share one colour. With transparency on, `Qt.alpha()` gives it the configured opacity (and Hyprland can blur behind it, see [[ch:cae9-assemble]]).
@ 21-24 | A foreground for any background
`on()` picks a light or dark variant of a colour depending on how light it is: handy for text on album-art colours.
@ 26-35 | Loading a scheme
The scheme file looks like `{"name": "dynamic", "mode": "dark", "colours": {"primary": "d0bcff", …}}`: names without the `m3` prefix and hex without `#`, exactly what Caelestia's CLI writes. The loop adds the prefix and `#`, and only assigns roles the palette knows (`hasOwnProperty`), so extra keys can't break anything.
@ 37-43 | Watching the file
When matugen (or the `caelestia` CLI) writes a new scheme, the file changes, `reload()` runs, `onLoaded` applies it, and every binding that uses a colour updates. Because `StyledRect` and `StyledText` animate colour changes, the whole shell **fades** to the new theme.
@ 45-78 | Default colours
A dark purple Material palette, used until a scheme file exists.
:::

> [!TIP] The Material 3 roles you'll use most
> **surface** (frame and panels) · **surfaceContainer** / **surfaceContainerHigh/Highest** (cards and controls on panels, from darker to lighter) · **primary** + **onPrimary** (accents and text on them) · **secondaryContainer** + **onSecondaryContainer** (selected items) · **onSurface** / **onSurfaceVariant** / **outline** (text from strongest to faintest) · **error** (warnings).

## Module 4: Animation components

Caelestia never writes a raw `NumberAnimation` with numbers in it. It uses two tiny components that read the tokens.

@include cae/components/Anim.qml

::: walk
@ 6-12 | Motion types as an enum
An `enum` inside a QML file creates named constants that other files reach through the type name: `Anim.FastSpatial`. Caelestia uses the same idea with more types.
@ 14-20 | Picking duration and curve
`[a, b, c, d, e][type]` is a short way to pick one value from a list by index: the enum values are 0, 1, 2… so `type` indexes both lists. Now `Behavior on x { Anim {} }` gives a 500 ms springy move, and `Anim { type: Anim.Effects }` a 200 ms fade.
:::

@include cae/components/CAnim.qml

`CAnim` is the colour version. It's used by every `Behavior on color`, which is how theme switches fade.

## Module 5: Styled basics

@include cae/components/StyledRect.qml

@include cae/components/StyledText.qml

@include cae/components/MaterialIcon.qml

These three are used everywhere instead of `Rectangle`, `Text` and raw icon fonts. `StyledRect` is transparent by default (most rectangles are tinted containers) and fades colour changes. `StyledText` uses the theme's font and the `onSurface` colour. `MaterialIcon` sets the icon font and animates the variable `FILL` axis, so an icon can smoothly go from outlined to filled when selected.

## Module 6: State layers and buttons

Material 3 shows interaction with a **state layer**: a see-through overlay in the content colour, 8% when hovered and 12% when pressed. Caelestia uses one on every clickable thing.

@include cae/components/StateLayer.qml

::: walk
@ 6-16 | A MouseArea that fills its parent
Drop a `StateLayer` inside any item and it covers it, shows a hand cursor and reports `clicked`. `radius` defaults to the parent's radius, so the overlay is rounded the same way.
@ 18-22 | The overlay
`Qt.alpha(color, 0.08)` is the colour at 8% opacity. Because it's a `StyledRect`, the overlay fades in and out instead of blinking.
:::

@include cae/components/IconButton.qml

::: walk
@ 11-20 | Properties
`icon` is an alias to the label's text, so `IconButton { icon: "wifi" }` just works. The four colour properties have Material defaults but can be overridden per button.
@ 22-29 | The shape morph
A toggle that's checked turns from a circle into a rounded square (`radius` from `size / 2` to `Tokens.rounding.medium`). This shape change is a signature of Material 3 Expressive and of Caelestia.
@ 39-42 | No hidden state
The button only reports `clicked`. It never sets `checked` itself. If it did, the binding `checked: Networking.wifiEnabled` would be replaced by a fixed value on the first click, and the button would stop following Wi-Fi changes made elsewhere. So callers write `onClicked: Networking.wifiEnabled = !Networking.wifiEnabled`.
:::

## Module 7: State per screen

Caelestia remembers **for each monitor** which drawers are open, so opening the launcher on one screen doesn't open it on all of them.

@include cae/components/ScreenState.qml

@include cae/services/Visibilities.qml

Each monitor's frame window creates one `ScreenState` and registers it here. Keybinds then call `Visibilities.forFocused()` to act on the monitor you're looking at.

> [!NOTE] In the original
> Older Caelestia versions had exactly this `Visibilities` singleton; newer ones moved it into `services/ShellState.qml` with a `ScreenState` per screen. Same idea.

## Module 8: Hyprland commands that always work

Newer Hyprland versions can be configured in Lua, and then dispatcher commands use a different syntax. Caelestia handles both, and so does the rebuild:

@include cae/services/Hypr.qml

## Module 9: System services

Four small singletons give the rest of the shell clean access to the system. Each one hides the details (PipeWire objects, sysfs files, `/proc` parsing) behind a few properties and functions.

@include cae/services/Audio.qml

The default output (`sink`) and input (`source`) are tracked with [[PwObjectTracker]] so their volume and mute state are live and writable. `setVolume` clamps to 0–1 and unmutes; `increment`/`decrement` use the step from the config; `sinks` lists every output for the audio popout; `icon` picks the right volume icon.

@include cae/services/Brightness.qml

The backlight device is found once (`ls /sys/class/backlight`). Its `brightness` file is watched, so the value updates whenever anything changes it (keys, scripts), and the OSD reacts to that. Setting goes through `brightnessctl`, which handles permissions.

@include cae/services/Players.qml

The "active" player: the one you picked in the dashboard, else the first one that's playing, else the first one. The timer asks the player for its position once a second while playing, because MPRIS doesn't push position updates on its own.

@include cae/services/SysInfo.qml

CPU (from `/proc/stat` deltas), memory (`MemTotal − MemAvailable`), temperature (the CPU's hwmon sensor, found once), disk (`df`) and uptime. The timer only runs while `refCount > 0`: the dashboard adds itself when it opens and removes itself when it closes, so these numbers cost nothing while nobody is looking.

## Try it

Before the next chapter there's nothing to see yet, but you can test the foundations in a scratch `shell.qml`:

```qml
import Quickshell
import QtQuick
import qs.components
import qs.services

ShellRoot {
    FloatingWindow {
        implicitWidth: 300; implicitHeight: 120
        color: Colours.palette.m3surface
        Row {
            anchors.centerIn: parent
            spacing: 12
            IconButton { icon: "wifi"; toggle: true; checked: on; property bool on: false; onClicked: on = !on }
            IconButton { icon: "bluetooth" }
            StyledText { text: "Hello, Caelestia"; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
```

## Practice

::: exercise warm | Bigger corners
Make the whole shell rounder: change `Tokens.rounding.large` and `extraLarge`. Which elements change?
--- solution
Every card (`Tokens.rounding.large`) and every drawer background (`extraLarge`). Nothing else needs editing because no file hard-codes a radius.
:::

::: exercise practice | A new motion type
Add a `Bounce` type to `Anim` with a 600 ms duration and the curve `[0.34, 1.56, 0.64, 1, 1, 1]`, and use it on the IconButton shape morph.
--- solution
Add `Bounce` to the enum, then a sixth entry to both lists (`600` and the curve; add them as tokens first if you want to keep everything in `Tokens`). In IconButton: `Anim { type: Anim.Bounce }`.
:::

::: exercise practice | Light mode
Write a `scheme.json` by hand with a light palette (surface `fef7ff`, onSurface `1d1b20`, primary `6750a4`, onPrimary `ffffff`, surfaceContainer `f3edf7`) into `~/.local/state/cae/scheme.json` and watch the colours fade.
:::

::: exercise challenge | Per-monitor bar setting
Add `property list<string> hiddenScreens` to the `bar` section of Config, and make it possible to hide the bar on monitors listed there (you'll use it in [[ch:cae4-bar]]).
--- hint
The bar's wrapper knows its `screen`; check `Config.bar.hiddenScreens.includes(screen.name)`.
:::
