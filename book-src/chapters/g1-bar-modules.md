# Gallery: Bar Modules

Small widgets that live **inside a bar**. Each is one `.qml` file: drop it into the test harness from [[ch:g0-overview]] or into your bar's `RowLayout`.

## Expanding Pill Clock

<div class="preview"><svg width="340" height="60" viewBox="0 0 340 60"><rect x="10" y="12" width="320" height="36" rx="18" fill="#1e1e2e" stroke="#313244"/><rect x="110" y="17" rx="13" height="26" fill="#313244"><animate attributeName="width" values="70;150;150;70;70" keyTimes="0;.2;.6;.8;1" dur="5s" repeatCount="indefinite"/><animate attributeName="x" values="135;95;95;135;135" keyTimes="0;.2;.6;.8;1" dur="5s" repeatCount="indefinite"/></rect><text x="170" y="35" fill="#cdd6f4" font-size="14" font-weight="700" text-anchor="middle">14:32<animate attributeName="opacity" values="1;0;0;1;1" keyTimes="0;.15;.65;.8;1" dur="5s" repeatCount="indefinite"/></text><text x="170" y="35" fill="#cdd6f4" font-size="13" text-anchor="middle" opacity="0">Fri 21 Nov · 14:32<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;.18;.25;.6;.65;1" dur="5s" repeatCount="indefinite"/></text></svg></div>

**What it is.** A compact clock showing only the time; hover it and it smoothly grows to show the date too.

**Kind:** bar module · **Needs:** nothing extra

@include galleryshell/bar/PillClock.qml

::: walk
@ 1-2 | Imports
`Quickshell` gives us [[SystemClock]]; `QtQuick` gives the basic visual types (`Rectangle`, `Text`) and animations.
@ 4-6 | The pill and its one piece of state
The whole widget is a `Rectangle`. `expanded` is `readonly` because nobody sets it from outside: it is **derived** from the hover handler at the bottom. Naming the state (`expanded`) instead of writing `hover.hovered` everywhere makes the rest of the code read like English.
@ 8 | The clock source
[[SystemClock]] gives the current time in `clock.date`. With `precision: SystemClock.Minutes` it updates exactly when the minute changes, not every second, so the widget costs almost nothing.
@ 10-15 | Size, shape and the grow animation
- `implicitWidth: label.implicitWidth + 24`: the pill is always as wide as its text plus 12 px padding on each side. When the text gets longer, the pill gets wider automatically.
- `radius: height / 2` makes perfect round ends whatever the height.
- `clip: true` hides anything that sticks out. While the pill is still growing, the longer text would overflow; clipping keeps it tidy.
- `Behavior on implicitWidth` animates **every** change of the width. We never start an animation by hand: change the text, and the width glides there in 250 ms.
@ 17-25 | The text
- `anchors.centerIn: parent` keeps the text centered while the pill resizes.
- The `text` binding picks a long format when expanded and a short one otherwise. `Qt.formatDateTime` uses Qt's format letters: `ddd` = short weekday, `d MMM` = day + short month, `hh:mm` = 24-hour time.
- `font.features: ({ "tnum": 1 })` turns on *tabular numbers*: every digit has the same width, so the pill doesn't wobble when `1` becomes `2`.
@ 26 | Hover detection
`HoverHandler` sets `hovered` when the mouse is over the pill, which flips `expanded`, which changes the text, which changes the width, which the `Behavior` animates. One line of input drives the whole effect through bindings.
:::

**Customize**
- 12-hour clock: `"h:mm AP"`. Seconds: precision `Seconds` and `"hh:mm:ss"`.
- Click to open a calendar popup: see [[ch:49-proj-clock-calendar]].

::: exercise practice | Click to pin open
Make a click keep the pill expanded even when the mouse leaves (click again to collapse).
--- solution
```qml
property bool pinned: false
readonly property bool expanded: hover.hovered || pinned
TapHandler { onTapped: root.pinned = !root.pinned }
```
:::

## Workspace Dots with Sliding Pill

<div class="preview"><svg width="300" height="60" viewBox="0 0 300 60"><rect x="20" y="15" width="260" height="30" rx="15" fill="#313244"/><rect y="24" height="12" rx="6" fill="#cba6f7"><animate attributeName="x" values="38;38;80;80;140;140;38" keyTimes="0;.2;.3;.5;.6;.85;1" dur="5s" repeatCount="indefinite" calcMode="spline" keySplines=".2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1"/><animate attributeName="width" values="28;28;28;28;28;28;28" dur="5s" repeatCount="indefinite"/></rect><g fill="#6c7086"><circle cx="100" cy="30" r="4"/><circle cx="160" cy="30" r="4" fill="#585b70"/><circle cx="185" cy="30" r="4"/><circle cx="210" cy="30" r="4" fill="#585b70"/><circle cx="235" cy="30" r="4" fill="#f38ba8"/><circle cx="260" cy="30" r="4" fill="#585b70"/></g></svg></div>

**What it is.** One dot per workspace; occupied workspaces are brighter, urgent ones red, and the active one is a wide pill that slides with a little bounce.

**Kind:** bar module · **Needs:** Hyprland (see [[ch:48-proj-workspaces]] for Sway/niri)

@include galleryshell/bar/WorkspaceDots.qml

::: walk
@ 1-3 | Imports
`Quickshell.Hyprland` provides the [[Hyprland]] singleton with workspaces, the focused workspace and `dispatch()` for sending commands.
@ 5-13 | Container and state
- `count` is how many slots to show; change it to 5 or 10 freely.
- `active` is the focused workspace's id. `?.` (optional chaining) avoids an error if Hyprland hasn't reported a workspace yet, and `?? 1` falls back to workspace 1.
- The background pill sizes itself from the row of dots plus padding.
@ 15-24 | The sliding pill
This is the trick of the widget: the highlight is **one separate rectangle**, not part of each dot.
- `rep.itemAt(root.active - 1)` asks the Repeater for the slot of the active workspace (ids start at 1, indexes at 0).
- `x` and `width` copy that slot's position and size. When the active workspace changes, `target` changes, so `x` changes.
- `Behavior on x` with `Easing.OutBack` and `overshoot: 1.3` makes it shoot slightly past and settle back: the "bounce".
- Because it is declared *before* the `Row`, it is drawn *behind* the dots.
@ 26-35 | One slot per workspace
`Repeater { model: root.count }` creates `count` slots. Each gets an `index` (0, 1, 2…) through `required property int index`; we turn it into a workspace id with `index + 1`.
@ 36 | Look up the real workspace
Hyprland only knows workspaces that exist (have windows or are focused). `find()` returns the matching [[HyprlandWorkspace]] or `undefined`, and `?? null` makes "doesn't exist" explicit.
@ 37-39 | Slot width
The active slot is 24 px wide, the others 8 px. The sliding pill reads this width, so it grows into the wide slot as it moves.
@ 40-46 | The dot
The dot is hidden on the active slot (the pill is there instead). Its color tells a story: red if the workspace is urgent, light grey if it has windows (`toplevels.values.length > 0`), dark grey if empty.
@ 47 | Click to switch
`Hyprland.dispatch("workspace 3")` runs the same command as `hyprctl dispatch workspace 3`. `anchors.margins: -4` makes the clickable area 4 px bigger than the tiny dot, which is much easier to hit.
@ 51 | Scroll to switch
`e+1` / `e-1` mean "next/previous existing workspace". Scrolling up (`angleDelta.y > 0`) goes left.
:::

**Customize**
- Numbers instead of dots: put a `Text { text: wsId }` in each slot.
- Per-monitor bars: use `Hyprland.monitorFor(screen).activeWorkspace.id` instead of `focusedWorkspace`.

::: exercise practice | Numbers on hover
While the whole widget is hovered, show each workspace's number inside its dot (make dots 14 px so the number fits).
--- hint
Add a `HoverHandler { id: h }` on `root`, and in the dot a `Text { visible: h.hovered; text: parent.parent.wsId }`.
:::

## Active Window with App Icon

<div class="preview"><svg width="340" height="60" viewBox="0 0 340 60"><rect x="10" y="15" width="320" height="30" rx="15" fill="#313244"/><rect x="22" y="21" width="18" height="18" rx="5" fill="#fab387"/><circle cx="31" cy="30" r="5" fill="#1e1e2e"/><text x="50" y="35" fill="#cdd6f4" font-size="13">Firefox — Quickshell Book · Widget Galle…</text></svg></div>

**What it is.** The focused window's icon and title, elided when too long. Works on any compositor with foreign-toplevel support.

**Kind:** bar module · **Needs:** nothing extra

@include galleryshell/bar/ActiveWindow.qml

::: walk
@ 1-5 | Imports
`Quickshell.Wayland` provides [[ToplevelManager]] (the list of windows on any wlroots compositor), `Quickshell.Widgets` provides [[IconImage]], and `QtQuick.Layouts` gives `RowLayout`.
@ 7-11 | The focused window
`ToplevelManager.activeToplevel` is the focused window, or `null` on an empty desktop. Typing the property as [[Toplevel]] gives editor autocompletion. `visible: win !== null` hides the whole chip when nothing is focused.
@ 13-16 | Capped width
`Math.min(row.implicitWidth + 20, maxWidth)` means "as wide as the content, but never more than 320 px". Once capped, the text gets less room than it wants, and that's what makes it elide.
@ 18-22 | Layout
A `RowLayout` filling the pill (minus margins) places the icon and text side by side and gives the text the remaining width.
@ 23-26 | The app icon
Windows only tell us their `appId` (like `firefox` or `org.gnome.Nautilus`). [[DesktopEntries.heuristicLookup()]] finds the installed app that matches, and its `icon` name goes through `Quickshell.iconPath()` to get a file from your icon theme. The second argument is the fallback icon if nothing matches.
@ 27-33 | The title
`Layout.fillWidth: true` lets the text take all remaining space, and `elide: Text.ElideRight` replaces the overflow with "…". Without `fillWidth`, the text would have no fixed width and could never elide.
:::

**Customize**
- Show just the app name: `DesktopEntries.heuristicLookup(win.appId)?.name`.
- Middle-click to close: `TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: root.win.close() }`.

::: exercise practice | Fade on change
Fade the title out and back in quickly when the focused window changes.
--- hint
`onWinChanged` on `root`, then a `SequentialAnimation` on the text's `opacity`: to 0 in 80 ms, to 1 in 160 ms.
:::

## Battery Pill with Fill Level

<div class="preview"><svg width="220" height="60" viewBox="0 0 220 60"><rect x="40" y="16" width="120" height="28" rx="14" fill="#313244"/><rect x="40" y="16" height="28" rx="14" fill="#a6e3a1" opacity=".85"><animate attributeName="width" values="40;120;40" dur="6s" repeatCount="indefinite"/></rect><text x="100" y="35" fill="#1e1e2e" font-size="13" font-weight="700" text-anchor="middle">⚡ 72%</text></svg></div>

**What it is.** A pill whose background fills like a battery: green when charging, red under 15%, plus the percentage and a bolt while charging.

**Kind:** bar module · **Needs:** UPower (`upower` service)

@include galleryshell/bar/BatteryPill.qml

::: walk
@ 1 | Import
UPower is a system service that reports batteries. Quickshell talks to it through `Quickshell.Services.UPower`.
@ 4-10 | Reading the battery
- `UPower.displayDevice` is a combined "battery" device (it merges multiple batteries on laptops that have two).
- `percentage` is **0 to 1** here, not 0–100. That's why the fill can be `width * pct` directly.
- `charging` treats "fully charged while plugged in" as charging too, so the pill stays green on AC.
- `fill` picks a color with a chain of conditions: green charging, red under 15%, yellow under 30%, accent otherwise.
@ 12-17 | Hide on desktops
`isLaptopBattery` is false on desktop PCs (no battery), so the widget disappears there. `clip: true` makes sure the fill never paints outside the rounded track.
@ 19-27 | The fill
A rectangle inside the track whose width is a fraction of the parent. Two `Behavior`s make it feel alive: the width glides when the percentage changes, and the color crossfades when it crosses a threshold.
@ 28-34 | The label
The ⚡ is added only while charging. The color flips at 45%: over the fill (filled side) dark text is readable, over the track light text is. This small detail makes the widget readable at every level.
@ 37-40 | Time remaining
`timeToFull` / `timeToEmpty` are seconds. The block computes hours and minutes as a string you can show in a tooltip. It's a property with a code block: the last `return` value becomes the property's value, and it re-evaluates when `charging` or the times change.
:::

**Customize**
- Pulse when critical: `SequentialAnimation on opacity { running: root.pct < 0.1 && !root.charging; loops: Animation.Infinite; … }`.
- Show `timeLeft` in a tooltip ([[ch:32-popups-menus]]).

::: exercise practice | Show time on hover
Show `timeLeft` instead of the percentage while hovered.
--- solution
```qml
text: hover.hovered && root.timeLeft ? root.timeLeft : (root.charging ? "⚡ " : "") + Math.round(root.pct * 100) + "%"
```
:::

## Volume Chip (Scroll and Click)

<div class="preview"><svg width="240" height="60" viewBox="0 0 240 60"><rect x="40" y="16" width="160" height="28" rx="14" fill="#313244"/><path d="M58 26h5l6-5v18l-6-5h-5z" fill="#cdd6f4"/><path d="M73 25q4 5 0 10" stroke="#cdd6f4" stroke-width="2" fill="none"/><rect x="84" y="28" width="80" height="4" rx="2" fill="#45475a"/><rect x="84" y="28" height="4" rx="2" fill="#89b4fa"><animate attributeName="width" values="20;70;45;20" dur="4s" repeatCount="indefinite"/></rect><text x="185" y="35" fill="#cdd6f4" font-size="12" text-anchor="middle">62%</text></svg></div>

**What it is.** Speaker icon, a thin level bar and the percentage. Scroll to change volume, click to mute, right-click to open pavucontrol.

**Kind:** bar module · **Needs:** PipeWire

@include galleryshell/bar/VolumeChip.qml

::: walk
@ 1-4 | Imports
`Quickshell.Services.Pipewire` connects to PipeWire, the audio server on modern Linux.
@ 6-10 | The default output
`Pipewire.defaultAudioSink` is the device sound plays through right now (speakers, headphones). If you plug in headphones, this changes and every binding follows. `vol` and `muted` read from its `audio` part with safe fallbacks.
@ 12 | The tracker (don't skip this)
PipeWire objects only report live data when something **tracks** them. Without [[PwObjectTracker]], `audio.volume` stays 0 and writes are ignored. This is the #1 reason volume widgets "don't work".
@ 14-17 | The chip
Size from content; the background lightens on hover as feedback that it's interactive.
@ 23-28 | Icon by level
A ternary chain picks the icon: muted → `volume_off`, loud → `volume_up`, some → `volume_down`, zero → `volume_mute`. It turns red when muted so the state is visible at a glance.
@ 29-38 | Mini level bar
A 60×4 track with a fill. `Math.min(1, …)` keeps the fill inside the track even when volume is above 100%, and the fill turns red above 100% as a warning. The fast 120 ms `Behavior` keeps up with quick scrolling.
@ 39-43 | Percentage
Tabular numbers again, so the chip width doesn't jump between 9% and 10%.
@ 46-48 | Clicks
- Left click toggles mute. `sink?.ready` checks that PipeWire has finished binding the device.
- Right click opens `pavucontrol` with `Quickshell.execDetached`: it starts the app without waiting and without tying it to the shell (it keeps running after a reload).
@ 49-54 | Scrolling
One wheel notch is 120 units, so `angleDelta.y / 120 * 0.05` is ±5% per notch. Touchpads send many smaller deltas, which turn into smooth small steps. The value is clamped between 0 and 1.5 (150%).
:::

**Customize**
- Hide the bar and percentage until hover for a minimal look.
- Add a microphone chip the same way with `Pipewire.defaultAudioSource`.

::: exercise practice | Middle-click to switch output
Middle-click to cycle the default output between all available sinks.
--- hint
`Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)` gives outputs; set `Pipewire.preferredDefaultAudioSink` to the next one.
:::

## Keyboard Layout Indicator

<div class="preview"><svg width="160" height="60" viewBox="0 0 160 60"><rect x="40" y="16" width="80" height="28" rx="14" fill="#313244"/><text x="64" y="35" fill="#cba6f7" font-size="16" font-family="Material Symbols Rounded">⌨</text><text x="92" y="35" fill="#cdd6f4" font-size="13" font-weight="700" text-anchor="middle">US<animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;.45;.5;.95;1" dur="4s" repeatCount="indefinite"/></text><text x="92" y="35" fill="#cdd6f4" font-size="13" font-weight="700" text-anchor="middle" opacity="0">ML<animate attributeName="opacity" values="0;0;1;1;0" keyTimes="0;.45;.5;.95;1" dur="4s" repeatCount="indefinite"/></text></svg></div>

**What it is.** Shows the current keyboard layout as a short code (US, DE, ML…), updates instantly when you switch, click to switch.

**Kind:** bar module · **Needs:** Hyprland

@include galleryshell/bar/KeyboardLayout.qml

Requires `jq` for the initial value.

::: walk
@ 1-3 | Imports
`Quickshell.Io` for [[Process]], `Quickshell.Hyprland` for Hyprland's event stream.
@ 6-8 | State
`layout` holds the short code to display. It starts as `"??"` until we know better.
@ 10-13 | Shortening the name
Hyprland reports full names like `English (US)`. The regex `\(([^)]+)\)` captures what's inside the parentheses (`US`). If there are none (`German`), it takes the first two letters. The result is uppercased and limited to 3 characters.
@ 15-20 | Look
A pill sized from its label, showing a keyboard symbol and the code.
@ 22-27 | Live updates
Hyprland broadcasts events like `activelayout>>at-translated-set-2-keyboard,English (US)`. Quickshell delivers each as `rawEvent`. `event.parse(2)` splits the data into exactly 2 fields at the first comma, so a layout name containing a comma stays in one piece; `[1]` is the layout name.
@ 29-33 | The starting value
Events only arrive on *changes*, so at startup we ask once: `hyprctl devices -j` returns JSON, and `jq` picks the main keyboard's `active_keymap`. [[StdioCollector]] gathers all output and gives it to us in `onStreamFinished`.
@ 34 | Click to switch
`switchxkblayout all next` switches every keyboard to the next configured layout, the same as your layout-switch keybind.
:::

**Customize**
- niri (fork module): `Niri.currentKeyboardLayoutName`.
- Show a flag emoji with a small lookup table.

::: exercise practice | Flag colors
Color the pill differently per layout (for example blue for US, yellow for DE) with a lookup object.
--- solution
```qml
readonly property var colors: ({ US: "#89b4fa", DE: "#f9e2af" })
color: colors[layout] ?? "#313244"
```
:::

## Updates Counter

<div class="preview"><svg width="180" height="60" viewBox="0 0 180 60"><rect x="40" y="16" width="100" height="28" rx="14" fill="#313244"/><text x="62" y="36" fill="#fab387" font-size="15">⟳</text><text x="100" y="35" fill="#cdd6f4" font-size="13" font-weight="700" text-anchor="middle">23</text><circle cx="132" cy="18" r="5" fill="#f38ba8"/></svg></div>

**What it is.** Number of pending package updates (Arch: official + AUR), refreshed every 30 minutes; click to open a terminal that runs the upgrade.

**Kind:** bar module · **Needs:** `pacman-contrib` (`checkupdates`), optional `paru`/`yay`

@include galleryshell/bar/Updates.qml

::: walk
@ 5-9 | State
`count` is the number of pending updates and `checking` is true while the check runs. `visible: count > 0` hides the widget when your system is up to date: no clutter.
@ 16-22 | Label
Shows `…` while checking and `⟳` otherwise. Over 50 updates the color turns red as a nudge.
@ 24-29 | Running the check
The command runs in `sh -c` so we can use shell features:
- `checkupdates` lists official repo updates without touching your real package database.
- `paru -Qua || yay -Qua` lists AUR updates with whichever helper you have; `2>/dev/null` hides errors if neither exists.
- `{ …; …; } | wc -l` counts all lines together.

`onStarted` flips `checking` on; when output ends, the number is parsed (`|| 0` handles empty output) and `checking` turns off.
@ 30 | Every 30 minutes
A repeating `Timer` sets `check.running = true` to run the process again. `triggeredOnStart` runs it immediately at startup instead of waiting 30 minutes.
@ 32-35 | Clicks
Left click opens a terminal running the upgrade, then waits for Enter so you can read the output. Right click re-checks immediately.
:::

**Customize**
- Debian/Ubuntu: `apt list --upgradable 2>/dev/null | tail -n +2 | wc -l`. Fedora: `dnf check-update -q | grep -c .`
- Flatpak: add `flatpak remote-ls --updates | wc -l`.

::: exercise practice | Recount after upgrading
After the upgrade terminal closes, re-run the check automatically.
--- hint
Use a `Process` for the terminal instead of `execDetached`, and set `check.running = true` in its `onExited`.
:::

## Weather Chip

<div class="preview"><svg width="200" height="60" viewBox="0 0 200 60"><rect x="30" y="16" width="140" height="28" rx="14" fill="#313244"/><circle cx="54" cy="30" r="7" fill="#f9e2af"><animate attributeName="r" values="6;7.5;6" dur="3s" repeatCount="indefinite"/></circle><g stroke="#f9e2af" stroke-width="2"><path d="M54 18v3M54 39v3M42 30h3M63 30h3"/></g><text x="112" y="35" fill="#cdd6f4" font-size="13" text-anchor="middle">28°C Sunny</text></svg></div>

**What it is.** Current temperature and condition with an icon, from wttr.in (no API key), refreshed every 20 minutes.

**Kind:** bar module · **Needs:** `curl`

@include galleryshell/bar/WeatherChip.qml

::: walk
@ 7-11 | State
`city` empty means "detect from my IP address" (wttr.in does this). `temp`, `desc` and `icon` are filled in when data arrives; until then the chip shows `--`.
@ 13-21 | Weather code → icon
wttr.in returns WWO weather codes (113 = sunny, 116 = partly cloudy…). The function maps groups of codes to Material Symbols names. Order matters: specific checks first, a generic `rainy` last.
@ 28-34 | Display
An icon in a warm yellow and the temperature with description.
@ 36-38 | The request
`curl -sf --max-time 10`: silent, fail on HTTP errors, give up after 10 seconds (so a dead network doesn't leave a process hanging). `encodeURIComponent` makes city names with spaces safe in the URL. `?format=j1` asks for JSON.
@ 39-48 | Parsing
`JSON.parse(text)` turns the reply into an object; `current_condition[0]` has the current weather. The `try/catch` matters: if you're offline, `text` is empty and parsing throws, so we show "offline" instead of crashing the binding.
@ 50-51 | Refresh and click
Every 20 minutes (weather doesn't change faster, and the service is free: be polite). Clicking opens the full forecast in your browser.
:::

**Customize**
- Fahrenheit: `c.temp_F`. Feels-like: `c.FeelsLikeC`.
- Forecast popup: `JSON.parse(text).weather` has three days of hourly data.

::: exercise practice | Feels-like on hover
Store `c.FeelsLikeC` too, and show "feels 31°" while hovered.
:::

## Privacy Indicators (Mic and Screen Share)

<div class="preview"><svg width="200" height="60" viewBox="0 0 200 60"><rect x="50" y="16" width="100" height="28" rx="14" fill="#f38ba8" opacity=".18"/><circle cx="72" cy="30" r="8" fill="#f38ba8"><animate attributeName="opacity" values="1;.4;1" dur="1.4s" repeatCount="indefinite"/></circle><rect x="69" y="24" width="6" height="9" rx="3" fill="#1e1e2e"/><rect x="92" y="23" width="18" height="12" rx="2" fill="none" stroke="#fab387" stroke-width="2"/><path d="M98 38h6" stroke="#fab387" stroke-width="2"/><text x="125" y="35" fill="#f38ba8" font-size="11" font-weight="700">LIVE</text></svg></div>

**What it is.** Like a phone's privacy dots: a pulsing red mic when any app records audio, and a screen icon when your screen is being shared or captured. It names the app on hover.

**Kind:** bar module · **Needs:** PipeWire

@include galleryshell/bar/PrivacyIndicators.qml

::: walk
@ 8-11 | Who uses the microphone?
In PipeWire, when an app records, a **link group** connects a *source* (your mic, which is not a stream and not a sink) to a *target* stream (the app). We filter link groups for exactly that shape, then map each to the app's name from its properties.
@ 12-15 | Who shares the screen?
Screen sharing through the desktop portal creates a video stream whose media class starts with `Stream/Input/Video`. Each such node is an app receiving your screen.
@ 17-22 | Visibility and tint
The widget only exists while something is recording. The background is a transparent red (`Qt.rgba` with 0.18 alpha), noticeable but not loud.
@ 28-33 | Pulsing mic icon
`SequentialAnimation on opacity` with `loops: Animation.Infinite` pulses between 35% and 100%. `running: parent.visible` stops it when the icon is hidden, so it uses no CPU when idle.
@ 34-37 | Screen icon
Static icon in orange, shown only during screen sharing.
@ 38-42 | Names on hover
`new Set([...a, ...b])` removes duplicates (an app using both mic and screen), and `join(", ")` makes a readable list.
:::

**Customize**
- Add a camera indicator: video streams whose source has `media.class` `Video/Source`.
- Play a sound when recording starts (`onActiveChanged`).

::: exercise challenge | Camera indicator
Add a camera indicator: video input streams that are **not** screencasts (check the source node's `media.class` is `Video/Source`).
:::

## Screen Recording Indicator with Timer

<div class="preview"><svg width="200" height="60" viewBox="0 0 200 60"><rect x="40" y="16" width="120" height="28" rx="14" fill="#313244"/><circle cx="60" cy="30" r="6" fill="#f38ba8"><animate attributeName="opacity" values="1;.2;1" dur="1.2s" repeatCount="indefinite"/></circle><text x="108" y="35" fill="#cdd6f4" font-size="13" font-weight="700" text-anchor="middle">REC 01:27</text></svg></div>

**What it is.** A blinking red dot and elapsed time while `wf-recorder` (or gpu-screen-recorder) is running. Click it to stop recording.

**Kind:** bar module · **Needs:** `wf-recorder` or `gpu-screen-recorder`

@include galleryshell/bar/RecordingIndicator.qml

::: walk
@ 5-9 | State
`recording` comes from checking for a recorder process; `seconds` counts how long it's been running.
@ 16-21 | Blinking dot
The classic red "REC" dot, pulsing while recording.
@ 22-28 | Time label
`padStart(2, "0")` turns `5` into `05`, so the label reads `REC 01:05`. Tabular numbers keep it steady.
@ 30-38 | Detecting a recorder
`pgrep -x "wf-recorder|gpu-screen-reco"` exits with code 0 if a process with one of those exact names exists. Linux truncates process names to 15 characters, which is why the second name is cut. In `onExited`, a fresh start resets the timer before setting `recording`.
@ 39-40 | Two timers
One polls every 2 seconds (cheap: `pgrep` is tiny). The other counts seconds, and only runs while recording.
@ 42 | Click to stop
`pkill -INT` sends SIGINT (like pressing Ctrl+C). wf-recorder catches it and properly finishes the video file; a hard kill would leave a broken file.
:::

**Customize**
- Start recording from the bar too: `Quickshell.execDetached(["sh", "-c", "wf-recorder -g \"$(slurp)\" -f ~/Videos/rec-$(date +%s).mp4"])`.

::: exercise practice | Start recording too
When not recording, show a small "record" button that starts `wf-recorder -f ~/Videos/rec.mp4`.
--- hint
`visible: true` always, and pick the action in the tap handler: start if `!recording`, stop otherwise. Use `execDetached` for both.
:::

## Notification Bell with Badge

<div class="preview"><svg width="140" height="60" viewBox="0 0 140 60"><rect x="50" y="15" width="40" height="30" rx="15" fill="#313244"/><g transform="translate(70 30)"><g><animateTransform attributeName="transform" type="rotate" values="0;18;-16;10;-6;0;0" keyTimes="0;.06;.12;.18;.24;.3;1" dur="3s" repeatCount="indefinite"/><path d="M-7 4v-6a7 7 0 0 1 14 0v6l2 2h-18z" fill="#cdd6f4"/><circle cx="0" cy="8" r="2" fill="#cdd6f4"/></g></g><circle cx="83" cy="19" r="7" fill="#f38ba8"/><text x="83" y="22.5" fill="#1e1e2e" font-size="9" font-weight="800" text-anchor="middle">3</text></svg></div>

**What it is.** A bell icon with an unread-count badge that wiggles when a new notification arrives; shows a crossed bell in Do-Not-Disturb mode.

**Kind:** bar module · **Needs:** your notification service ([[ch:51-proj-notifications]]); a minimal stand-in is included

@include galleryshell/bar/NotificationBell.qml

Use it: `NotificationBell { count: Notifs.count; dnd: GlobalStates.dnd; onClicked: GlobalStates.toggle("controlCenter") }`.

::: walk
@ 3-9 | A reusable widget
This widget doesn't import your notification service. Instead it exposes `count` and `dnd` properties for you to bind (`count: Notifs.count`). That keeps it reusable in any shell.
@ 11 | React to new notifications
`onCountChanged` runs whenever `count` changes. We only ring when there's something to see.
@ 13-20 | The icon
Three icons: `notifications_off` for do-not-disturb, `notifications_unread` when there's something, plain `notifications` otherwise. `transformOrigin: Item.Top` makes rotations pivot around the top edge, like a real bell hanging from a hook.
@ 21-28 | The swing
A `SequentialAnimation` of rotations with shrinking angles (18°, −16°, 10°, −6°, 0°) imitates a swing that loses energy. `id: ring` lets line 11 `restart()` it.
@ 30-38 | The badge
A small red pill at the top-right corner, offset by −2 px so it overlaps the icon edge. Its width grows for "9+". `scale` animates from 0 with `OutBack`, so it pops in.
:::

::: exercise practice | Ring only for urgent
Add `property bool urgent` and only ring when `urgent` is true; otherwise just show the badge.
:::

## Caffeine Toggle

<div class="preview"><svg width="140" height="60" viewBox="0 0 140 60"><rect x="45" y="15" width="50" height="30" rx="12" fill="#cba6f7"/><path d="M58 24h20v10a6 6 0 0 1-6 6h-8a6 6 0 0 1-6-6z" fill="#1e1e2e"/><path d="M78 27h3a3 3 0 0 1 0 6h-3" stroke="#1e1e2e" stroke-width="2" fill="none"/><g stroke="#1e1e2e" stroke-width="1.5" fill="none" opacity=".7"><path d="M63 21q2-3 0-5"><animate attributeName="opacity" values="0;1;0" dur="2s" repeatCount="indefinite"/></path><path d="M69 21q2-3 0-5"><animate attributeName="opacity" values="1;0;1" dur="2s" repeatCount="indefinite"/></path></g></svg></div>

**What it is.** A coffee-cup button that keeps the screen awake (no idle lock or blanking) while it's on. The cup morphs from a circle into a rounded square when active.

**Kind:** bar module · **Needs:** nothing extra

@include galleryshell/bar/Caffeine.qml

::: walk
@ 5-13 | Toggle with shape morph
`on` is the state. When on, the corners get less round (`radius: 8` vs a full pill) and the color changes, both animated. Changing **shape and color** together is clearer than color alone (and helps color-blind users).
@ 15-22 | Filled icon
Material Symbols is a variable font. `font.variableAxes: ({ "FILL": 1 })` fills the coffee cup when on, outlined when off.
@ 23-26 | Preventing sleep
[[IdleInhibitor]] tells the compositor "don't go idle" (no screen dimming, no auto-lock) while `enabled`. It must be attached to a visible window; `root.QsWindow.window` is an *attached property* that finds the window this widget lives in, so it works wherever you place the widget.
@ 27 | Toggle
One tap flips the state; everything else follows through bindings.
:::

**Customize**
- Auto-off after 2 hours: `Timer { interval: 7200000; running: root.on; onTriggered: root.on = false }`.
- Persist across restarts with a [[JsonAdapter]] state file.

::: exercise practice | Remember the state
Keep caffeine on across shell restarts with a `FileView` + `JsonAdapter` in `Quickshell.statePath("caffeine.json")`.
:::

## Power Profile Chip

<div class="preview"><svg width="220" height="60" viewBox="0 0 220 60"><rect x="20" y="16" width="180" height="28" rx="14" fill="#313244"/><rect y="19" width="56" height="22" rx="11" fill="#cba6f7"><animate attributeName="x" values="24;24;82;82;140;140;24" keyTimes="0;.25;.33;.58;.66;.92;1" dur="6s" repeatCount="indefinite"/></rect><text x="52" y="34" font-size="12" fill="#cdd6f4" text-anchor="middle">🍃</text><text x="110" y="34" font-size="12" fill="#cdd6f4" text-anchor="middle">⚖</text><text x="168" y="34" font-size="12" fill="#cdd6f4" text-anchor="middle">⚡</text></svg></div>

**What it is.** A three-segment switch for Power Saver / Balanced / Performance with a sliding highlight.

**Kind:** bar module or control center · **Needs:** `power-profiles-daemon`

@include galleryshell/bar/PowerProfileSwitch.qml

::: walk
@ 6-8 | Available profiles
Not every machine supports "performance". `PowerProfiles.hasPerformanceProfile` tells us, and we build a list of 2 or 3 profiles accordingly.
@ 9-10 | Icons and current index
`icons` lines up with `profiles` by index. `current` is the index of the active profile; it updates when the profile changes from anywhere (even `powerprofilesctl` in a terminal).
@ 17-23 | Sliding highlight
One rectangle under the icons. `x: 3 + current * 36` puts it under the active icon (each slot is 34 px + 2 px spacing). `Behavior on x` slides it.
@ 29-43 | The icons
A `Repeater` over the profiles list. `modelData` is the profile value itself, `index` its position. The active icon turns dark to stay readable on the highlight.
@ 41 | Switching
`PowerProfiles.profile` is writable: assigning to it asks power-profiles-daemon to switch. The highlight moves when the system confirms the change.
:::

::: exercise practice | Auto power saver
Switch to `PowerSaver` automatically when the battery drops below 20% and isn't charging.
--- hint
`Connections { target: UPower.displayDevice; function onPercentageChanged() { … } }`
:::

## Bluetooth Headset Battery

<div class="preview"><svg width="220" height="60" viewBox="0 0 220 60"><rect x="30" y="16" width="160" height="28" rx="14" fill="#313244"/><path d="M48 33v-4a9 9 0 0 1 18 0v4" stroke="#89b4fa" stroke-width="2.5" fill="none"/><rect x="45" y="31" width="5" height="8" rx="2" fill="#89b4fa"/><rect x="64" y="31" width="5" height="8" rx="2" fill="#89b4fa"/><text x="80" y="35" fill="#cdd6f4" font-size="12">Sony WH-1000 · 80%</text></svg></div>

**What it is.** When a Bluetooth device that reports battery (headphones, controller, mouse) is connected, shows its name and battery.

**Kind:** bar module · **Needs:** BlueZ

@include galleryshell/bar/BtBattery.qml

::: walk
@ 9-10 | Which devices?
From all Bluetooth devices, keep the connected ones that report a battery (`batteryAvailable`; many mice and keyboards don't). The widget hides when the list is empty.
@ 21-25 | One entry per device
A `Repeater` with the filtered array as its model. Each delegate receives the [[BluetoothDevice]] as `modelData`.
@ 26 | Device icon
Bluetooth devices report an icon name like `audio-headset`; `Quickshell.iconPath` finds it in your icon theme, with `bluetooth` as fallback.
@ 27-31 | Battery text
Normally just the percentage (battery is 0–1, so `* 100`). On hover, the name is added. Below 20% it turns red.
:::

::: exercise practice | Low-battery notification
Send a notification once when a headset drops below 15%.
--- hint
`Quickshell.execDetached(["notify-send", "Headset battery low"])` inside an `onBatteryChanged` handler, with a flag so it fires once.
:::
