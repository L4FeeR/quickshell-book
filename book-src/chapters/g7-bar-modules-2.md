# Gallery: More Bar Modules

Fifteen more chips for your bar: network, Bluetooth, brightness, microphone, a scrolling media title, a taskbar, a tray with an overflow drawer, workspaces with app icons, and small tools like a stopwatch and a countdown. Each is one file in `galleryshell/bar/`. Drop it into a bar `RowLayout`, or see all of them working together in [[ch:g10-full-shell]].

> [!NOTE] Icons
> Like the rest of the gallery, these chips draw icons with the **Material Symbols Rounded** font ([[ch:27-fonts-icons]]). Without it installed you'll see the icon names as words (`volume_up`), which is a quick way to tell the font is missing.

## Network Chip

<div class="preview"><svg width="360" height="60" viewBox="0 0 360 60"><rect x="10" y="17" width="150" height="26" rx="13" fill="#313244"/><text x="24" y="35" fill="#89b4fa" font-size="14">📶</text><text x="46" y="35" fill="#cdd6f4" font-size="12">HomeNet-5G</text><rect x="180" y="17" width="110" height="26" rx="13" fill="#313244"/><text x="194" y="35" fill="#89b4fa" font-size="14">🖧</text><text x="216" y="35" fill="#cdd6f4" font-size="12">Ethernet</text><rect x="310" y="17" width="34" height="26" rx="13" fill="#313244"/><text x="319" y="35" fill="#6c7086" font-size="14">⊘</text></svg></div>

**What it is.** Shows how you're online: Wi-Fi strength and network name, "Ethernet" when wired, or a crossed-out icon when offline. Click hides the name, right-click turns Wi-Fi off and on.

**Kind:** bar module · **Needs:** NetworkManager

@include galleryshell/bar/NetworkChip.qml

::: walk
@ 8-10 | Finding the devices
[[Networking]] lists every network device NetworkManager knows. Quickshell currently gives a specific type only to Wi-Fi (`DeviceType.Wifi`), so any **other** device that is connected (and isn't the loopback `lo`) is treated as wired.
@ 11-12 | The current network
A Wi-Fi device has a list of visible `networks`; the one with `connected` set is yours. `signalStrength` goes from 0 to 1.
@ 15-19 | Picking the icon
One chained conditional, checked top to bottom: wired wins, then "Wi-Fi switched off", then "not connected", then four strength levels. Reading it out loud gives the rules.
@ 20 | The label
The network's name, or a short status. `??` falls back when `net` is null.
@ 22-26 | The pill
Width follows the content plus padding. The `Behavior` animates the width when the name appears or disappears.
@ 32-43 | Icon and name
The icon is blue when online, grey otherwise. The name is capped at 120 px and elided, so a long SSID can't push the rest of your bar away.
@ 46-49 | Clicks
Left toggles `showName`, right flips `Networking.wifiEnabled` (that's a real switch: NetworkManager turns the radio off), middle opens NetworkManager's editor.
:::

For choosing a network, pair it with the Wi-Fi picker from [[ch:g4-panels]].

::: exercise practice | Show the IP address on hover
Add a second text that appears while hovered, showing the device's address.
--- hint
`NetworkDevice` has an `address` property. Use `(root.wired ?? root.wifi)?.address`.
:::

## Bluetooth Chip

<div class="preview"><svg width="360" height="60" viewBox="0 0 360 60"><rect x="10" y="17" width="34" height="26" rx="13" fill="#313244"/><text x="21" y="35" fill="#6c7086" font-size="14">ᛒ</text><rect x="60" y="17" width="190" height="26" rx="13" fill="#313244"/><text x="74" y="35" fill="#89b4fa" font-size="14">ᛒ</text><text x="92" y="35" fill="#cdd6f4" font-size="12">WH-1000XM4</text><text x="200" y="35" fill="#a6adc8" font-size="11">80%</text></svg></div>

**What it is.** The Bluetooth state at a glance: grey when off, blue when something is connected, with the device's name and battery level. Click toggles Bluetooth.

**Kind:** bar module · **Needs:** BlueZ (`bluetooth.service` running)

@include galleryshell/bar/BluetoothChip.qml

::: walk
@ 8-10 | Adapter and devices
`Bluetooth.defaultAdapter` is your Bluetooth controller (or `null` if there is none). `Bluetooth.devices` holds every known device; filtering on `connected` gives the ones in use right now.
@ 12 | No adapter, no chip
Desktops without Bluetooth simply don't show it.
@ 22-26 | Icon
Three states, three icons and colours.
@ 27-32 | Device name
One device: its name. Several: a count.
@ 33-39 | Battery
Many headphones report their battery over Bluetooth. `batteryAvailable` says whether this one does; `battery` is 0 to 1.
@ 42-44 | Clicks
Left toggles the adapter's `enabled`, which powers the radio on or off. Right opens Blueman for pairing.
:::

::: exercise practice | Connect to your headphones with a click
Add a property `favourite: "AA:BB:CC:DD:EE:FF"` (a device address). Middle-click connects or disconnects that device.
--- solution
```qml
property string favourite: "AA:BB:CC:DD:EE:FF"
TapHandler {
    acceptedButtons: Qt.MiddleButton
    onTapped: {
        const d = Bluetooth.devices.values.find(d => d.address === root.favourite)
        if (d) d.connected ? d.disconnect() : d.connect()
    }
}
```
:::

## Brightness Chip

<div class="preview"><svg width="200" height="60" viewBox="0 0 200 60"><rect x="40" y="17" width="90" height="26" rx="13" fill="#313244"/><text x="54" y="35" fill="#f9e2af" font-size="14">☀</text><text x="76" y="35" fill="#cdd6f4" font-size="12">65%</text></svg></div>

**What it is.** Screen brightness for laptops. Scroll over it to change brightness in 5% steps; click to jump between dim and full.

**Kind:** bar module · **Needs:** `brightnessctl`, a backlight (laptops; most external monitors need `ddcutil` instead)

@include galleryshell/bar/BrightnessChip.qml

::: walk
@ 8-9 | State
`level` is 0–1. `device` lets you pick a specific backlight (`brightnessctl -l` lists them); empty means the default one.
@ 11-13 | Building commands
A small helper adds `-d device` only when a device is set, so every command goes through one place.
@ 14-17 | Setting brightness
Clamp to 1–100% (0% can turn some screens fully black), update `level` immediately so the chip responds at once, then run `brightnessctl set 42%` in the background.
@ 19-30 | Reading brightness
`brightnessctl -m` prints one machine-readable line. Field 3 is the current raw value and field 5 the maximum, so their ratio is the level.
@ 31-32 | Staying in sync
Brightness keys or other tools can change it too. Re-reading every 5 seconds keeps the chip honest without real cost.
@ 55-57 | Input
Scrolling one notch (`angleDelta.y` = 120) changes it by 5%. A click toggles between 20% and 100%.
:::

::: exercise challenge | React instantly to brightness keys
Instead of polling, watch the backlight's `brightness` file with a `FileView` and `watchChanges: true`.
--- hint
The file is `/sys/class/backlight/<name>/brightness`, and `max_brightness` is next to it. Unlike LED files, backlight files do send change notifications on most drivers.
:::

## Microphone Chip

<div class="preview"><svg width="260" height="60" viewBox="0 0 260 60"><rect x="20" y="17" width="34" height="26" rx="13" fill="#45475a"/><text x="30" y="35" fill="#6c7086" font-size="14">🎙</text><rect x="80" y="17" width="34" height="26" rx="13" fill="#313244"/><text x="90" y="35" fill="#cdd6f4" font-size="14">🎙</text><rect x="140" y="17" width="34" height="26" rx="13" fill="#f38ba8"><animate attributeName="opacity" values="1;.7;1" dur="1.4s" repeatCount="indefinite"/></rect><text x="150" y="35" fill="#1e1e2e" font-size="14">🎙</text><text x="186" y="35" fill="#a6adc8" font-size="11">in use</text></svg></div>

**What it is.** Microphone mute toggle. It turns red while any app is recording, so you always know when you're live.

**Kind:** bar module · **Needs:** PipeWire

@include galleryshell/bar/MicChip.qml

::: walk
@ 8-10 | The default microphone
`Pipewire.defaultAudioSource` is the input apps record from. Missing values default to "muted" so nothing claims to be live by accident.
@ 11-12 | Is anyone recording?
A recording app shows up as a PipeWire **stream** node that is not a sink (it consumes audio instead of playing it). If one exists, the mic is in use.
@ 14 | Tracking
As with the volume chip ([[ch:g1-bar-modules]]), a node must be tracked before its `audio` properties are valid.
@ 20-21 | Colour
Muted is dim, in use is red, otherwise the normal chip colour, fading between them.
@ 27-36 | Icon and level
The volume percentage only appears on hover, keeping the chip small.
@ 39-43 | Input
Click toggles mute; scrolling changes the input volume, capped at 100%.
:::

::: exercise practice | Push to talk
Make the mic unmuted only while the left button is held down.
--- hint
A `TapHandler` has `pressed`. Use `onPressedChanged: root.source.audio.muted = !pressed`.
:::

## Scrolling Media Title

<div class="preview"><svg width="340" height="60" viewBox="0 0 340 60"><rect x="20" y="17" width="290" height="26" rx="13" fill="#313244"/><text x="32" y="35" fill="#cdd6f4" font-size="13">⏮</text><text x="52" y="35" fill="#cba6f7" font-size="14">⏸</text><text x="72" y="35" fill="#cdd6f4" font-size="13">⏭</text><clipPath id="mq"><rect x="96" y="17" width="200" height="26"/></clipPath><g clip-path="url(#mq)"><text y="35" fill="#cdd6f4" font-size="12">Daft Punk — Instant Crush (feat. Julian Casablancas)<animate attributeName="x" from="100" to="-220" dur="9s" repeatCount="indefinite"/></text></g></svg></div>

**What it is.** Previous, play/pause and next buttons with the artist and title. When the text is too long it scrolls endlessly like a marquee, and stops scrolling when paused.

**Kind:** bar module · **Needs:** an MPRIS player (Spotify, Firefox, mpv with mpris…)

@include galleryshell/bar/MediaMarquee.qml

::: walk
@ 8-10 | Which player
A playing player wins; otherwise the first one. `line` joins artist and title, skipping the dash when there's no artist.
@ 13 | Hidden when idle
No player, or nothing loaded: no chip.
@ 23-37 | Controls
Three icon buttons. Previous and next are greyed out when the player says it can't do them.
@ 40-45 | The viewport
An `Item` with `clip: true` is the window the text slides through. It is as wide as the text, but never wider than `textWidth`. `overflow` says whether scrolling is needed.
@ 47-52 | Two copies
The title is placed twice, 40 px apart. When the first copy has scrolled fully out on the left, the second one is exactly where the first started.
@ 54-60 | The scroll
The row moves left by exactly one copy plus the gap, then the loop restarts at 0. Because of the second copy, the jump back can't be seen. The duration grows with the text length, so the speed stays the same for short and long titles. When paused or short, `x` is reset to 0.
:::

::: exercise practice | Pause on hover
Stop the scrolling while the pointer is over the title, so it can be read.
--- solution
Add `HoverHandler { id: titleHover }` inside `viewport` and change `running` to `viewport.overflow && (root.player?.isPlaying ?? false) && !titleHover.hovered`. Use `paused:` instead of `running:` if you want it to continue from where it stopped.
:::

## Taskbar

<div class="preview"><svg width="260" height="60" viewBox="0 0 260 60"><rect x="40" y="15" width="150" height="30" rx="10" fill="#313244"/><rect x="44" y="17" width="26" height="26" rx="8" fill="#45475a"/><circle cx="57" cy="29" r="7" fill="#fab387"/><rect x="51" y="40" width="12" height="3" rx="1.5" fill="#cba6f7"/><circle cx="85" cy="29" r="7" fill="#89b4fa"/><rect x="83" y="40" width="4" height="3" rx="1.5" fill="#6c7086"/><circle cx="113" cy="29" r="7" fill="#a6e3a1"/><rect x="111" y="40" width="4" height="3" rx="1.5" fill="#6c7086"/><circle cx="141" cy="29" r="7" fill="#f5c2e7" opacity=".4"/><rect x="139" y="40" width="4" height="3" rx="1.5" fill="#6c7086"/><circle cx="169" cy="29" r="7" fill="#f9e2af"/><rect x="167" y="40" width="4" height="3" rx="1.5" fill="#6c7086"/></svg></div>

**What it is.** One icon per open window, like a classic taskbar. Click focuses a window, middle-click closes it, right-click minimizes it. Works on any compositor with the foreign-toplevel protocol (Hyprland, Sway, niri, KDE…).

**Kind:** bar module · **Needs:** nothing extra

@include galleryshell/bar/Taskbar.qml

::: walk
@ 9-11 | Which windows
[[ToplevelManager]] lists every window. Each `Toplevel` knows which `screens` it is on, so setting `screen` to the bar's screen shows only that monitor's windows.
@ 13-16 | Finding an icon
Windows only have an app id like `org.mozilla.firefox`. `DesktopEntries.heuristicLookup` finds the matching `.desktop` file (it also tries lowercase and other common spellings), whose `icon` is then resolved by `Quickshell.iconPath`, with a generic fallback.
@ 30-35 | One button per window
The active window (`activated`) gets a raised background.
@ 36-41 | Icon
Minimized windows are drawn faded.
@ 42-48 | Indicator
A short line under every window, wider and purple for the active one.
@ 49-55 | Clicks
`activate()` focuses the window (and un-minimizes it), `close()` asks it to close, and `minimized` can be set directly.
:::

::: exercise practice | Group windows by app
Show one icon per app id with a dot per window, like a dock. Clicking cycles through that app's windows.
--- hint
Build the model from `[...new Set(root.windows.map(t => t.appId))]` and keep the window list per id. The Dock in [[ch:g9-system]] does exactly this.
:::

## Submap Indicator

<div class="preview"><svg width="200" height="60" viewBox="0 0 200 60"><rect x="50" y="17" width="90" height="26" rx="13" fill="#f9e2af"><animate attributeName="opacity" values="1;.65;1" dur="1.4s" repeatCount="indefinite"/></rect><text x="95" y="34" fill="#1e1e2e" font-size="11" font-weight="700" text-anchor="middle" letter-spacing="1">RESIZE</text></svg></div>

**What it is.** Hyprland submaps are modes like "resize": while one is active, your keys do different things. This yellow pill shows which mode you're in and disappears when you leave it.

**Kind:** bar module · **Needs:** Hyprland

@include galleryshell/bar/SubmapIndicator.qml

::: walk
@ 10-16 | Listening to Hyprland
`Hyprland.rawEvent` delivers every event from Hyprland's event socket. The `submap` event carries the submap name, or an empty string when you return to the default map.
@ 18-24 | Growing and shrinking
Width is 0 in the default map, so the pill takes no space. When a submap starts, it springs open (`OutBack` overshoots slightly). `clip` hides the text while it's narrow.
@ 26-31 | The label
The submap name in capitals with a little letter spacing.
@ 33-40 | Pulse
While a submap is active the opacity breathes between 65% and 100%. When it stops, opacity is restored to 1 so the next pulse starts clean.
:::

::: exercise warm | Try it
Add a resize submap to your Hyprland config (`bind = SUPER, R, submap, resize` … `submap = reset`), press Super+R and watch the pill.
:::

## Caps Lock and Num Lock

<div class="preview"><svg width="200" height="60" viewBox="0 0 200 60"><rect x="50" y="19" width="48" height="22" rx="6" fill="#fab387"/><text x="74" y="34" fill="#1e1e2e" font-size="11" font-weight="700" text-anchor="middle">CAPS</text><rect x="104" y="19" width="42" height="22" rx="6" fill="#fab387"/><text x="125" y="34" fill="#1e1e2e" font-size="11" font-weight="700" text-anchor="middle">NUM</text></svg></div>

**What it is.** Small orange badges that appear while Caps Lock or Num Lock is on, so you never type a password in capitals again.

**Kind:** bar module · **Needs:** nothing extra (reads `/sys/class/leds`)

@include galleryshell/bar/LockKeys.qml

::: walk
@ 10-11 | Paths
Where the two LED state files are. They're found at startup, because the input number in their names (`input3`) differs between machines.
@ 13-24 | Finding the files
A one-off shell command lists the first capslock and numlock LEDs. Each file contains `1` when the LED is on.
@ 25-28 | Reading them
Two [[FileView]]s read the files. Files in `/sys` don't announce changes, so a timer calls `reload()` four times a second. That is only a tiny file read, no process is started, so it costs almost nothing.
@ 30-38 | A badge component
An inline component: a label and an `on` flag; it's only visible while on.
@ 39-40 | The two badges
`text()` returns the file's contents. Used in a binding, it updates whenever the file is reloaded with new contents.
:::

::: exercise practice | Scroll Lock too
Add a third badge for `*::scrolllock`.
:::

## Ring Clock

<div class="preview"><svg width="200" height="70" viewBox="0 0 200 70"><circle cx="100" cy="35" r="18" fill="none" stroke="#313244" stroke-width="4"/><circle cx="100" cy="35" r="18" fill="none" stroke="#cba6f7" stroke-width="4" stroke-linecap="round" stroke-dasharray="113" transform="rotate(-90 100 35)"><animate attributeName="stroke-dashoffset" from="113" to="0" dur="6s" repeatCount="indefinite"/></circle><text x="100" y="33" fill="#cdd6f4" font-size="10" font-weight="700" text-anchor="middle">14</text><text x="100" y="44" fill="#a6adc8" font-size="10" text-anchor="middle">32</text></svg></div>

**What it is.** A tiny round clock for vertical bars or minimal setups: hours and minutes stacked in the middle, and a ring that fills up once a minute with the seconds.

**Kind:** bar module · **Needs:** nothing extra

@include galleryshell/bar/ClockRing.qml

::: walk
@ 8-11 | Size and time
One `size` sets both dimensions. The clock ticks every second, and `progress` is how far through the minute we are.
@ 13-15 | Shapes
`Shape` draws vector paths. The curve renderer gives smooth, antialiased arcs even at this small size ([[ch:26-shapes-canvas]]).
@ 16-19 | The track
A full circle (sweep 360°) in a dark colour.
@ 20-28 | The progress arc
Starts at −90°, which is 12 o'clock (0° is 3 o'clock in Qt), and sweeps clockwise in proportion to the seconds. Round caps make the end look soft.
@ 30-35 | The time
Hours above minutes in a `Column` with negative spacing, so the two lines sit close together.
:::

::: exercise practice | Battery ring
Turn it into a battery ring: sweep by `UPower.displayDevice.percentage`, green while charging, red below 20%.
:::

## Stopwatch

<div class="preview"><svg width="240" height="60" viewBox="0 0 240 60"><rect x="20" y="17" width="90" height="26" rx="13" fill="#313244"/><text x="34" y="35" fill="#cdd6f4" font-size="13">⏱</text><text x="56" y="35" fill="#cdd6f4" font-size="12">03:27</text><rect x="130" y="17" width="90" height="26" rx="13" fill="#a6e3a1"/><text x="144" y="35" fill="#1e1e2e" font-size="13">⏸</text><text x="166" y="35" fill="#1e1e2e" font-size="12">12:05</text></svg></div>

**What it is.** A stopwatch chip. Click to start and pause, right-click to reset. It turns green while running.

**Kind:** bar module · **Needs:** nothing extra

@include galleryshell/bar/Stopwatch.qml

::: walk
@ 7-12 | Measuring time properly
Counting timer ticks drifts (timers can fire late). Instead the stopwatch stores **when** it started (`startedAt`) and how much time earlier runs added up to (`elapsed`). `total` is computed from the real clock, so it's always exact.
@ 14-18 | Formatting
Seconds to `mm:ss`, with hours in front only when needed. `padStart` adds the leading zero.
@ 19-22 | Start and pause
Pausing adds the current run to `elapsed`. Starting records the start time.
@ 24-25 | Ticking
The timer only updates `now` so the display refreshes; it doesn't count anything. It only runs while the stopwatch runs.
@ 49-51 | Input
Left: toggle. Right: stop and clear.
:::

::: exercise practice | Laps
Middle-click records a lap. Show the number of laps next to the time and print all lap times with `console.log` on reset.
:::

## Countdown Timer

<div class="preview"><svg width="240" height="60" viewBox="0 0 240 60"><clipPath id="cd"><rect x="60" y="17" width="110" height="26" rx="13"/></clipPath><rect x="60" y="17" width="110" height="26" rx="13" fill="#313244"/><g clip-path="url(#cd)"><rect x="60" y="17" height="26" fill="#45365e"><animate attributeName="width" from="110" to="0" dur="8s" repeatCount="indefinite"/></rect></g><text x="74" y="35" fill="#cba6f7" font-size="13">⌛</text><text x="96" y="35" fill="#cdd6f4" font-size="12">4:12</text></svg></div>

**What it is.** A kitchen timer for your bar. Scroll to choose the minutes, click to start; the background drains as time passes, and a notification pops up at the end.

**Kind:** bar module · **Needs:** `notify-send` (libnotify)

@include galleryshell/bar/Countdown.qml

::: walk
@ 8-13 | State
`endsAt` is the moment the timer finishes (0 when stopped). Everything else is derived from it: `active`, `remaining` and the `fraction` left. Like the stopwatch, it uses real time, not tick counts.
@ 15-24 | Checking
Twice a second, refresh `now`. When time is up, stop and send a critical notification so it stays on screen.
@ 32-38 | Draining background
A rectangle behind the text whose width is the fraction left. `clip` on the chip keeps its corners inside the pill.
@ 49-54 | Time left
Round **up** to whole seconds first, then split into minutes and seconds, so 4:59.5 shows as 5:00 and the display reaches 0:00 exactly when it ends.
@ 57-62 | Start and stop
A click starts the timer (`endsAt` = now + duration) or cancels it.
@ 63-66 | Choosing minutes
Scrolling changes the duration from 1 to 180 minutes, but only while stopped.
:::

::: exercise practice | Play a sound
Play a sound when time is up as well: `Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/complete.oga"])`.
:::

## Game Mode

<div class="preview"><svg width="200" height="60" viewBox="0 0 200 60"><rect x="50" y="17" width="34" height="26" rx="13" fill="#313244"/><text x="59" y="35" fill="#cdd6f4" font-size="14">🎮</text><rect x="110" y="17" width="34" height="26" rx="13" fill="#a6e3a1"/><text x="119" y="35" fill="#1e1e2e" font-size="14">🎮</text></svg></div>

**What it is.** One click switches off Hyprland's animations, blur, shadows, gaps and rounding, for games or older laptops. Click again to get your config back.

**Kind:** bar module · **Needs:** Hyprland with a classic (`hyprland.conf`) config

@include galleryshell/bar/GamemodeChip.qml

::: walk
@ 10-14 | Turning effects off
`hyprctl --batch` sends several `keyword` commands in one call. They only change the running session, not your config file.
@ 15-16 | Turning them back on
`hyprctl reload` re-reads your config, which restores everything you had.
@ 19-24 | The starting state
At startup, ask Hyprland whether animations are on. `getoption -j` returns JSON with the value in `int`. If they're already off, the chip starts green.
@ 26-38 | The chip
Green when on. A click flips `on` and applies it.
:::

> [!WARNING] Lua configs
> With a Lua Hyprland config, `hyprctl keyword` doesn't apply. Use `hyprctl eval` with `hl.config({...})` calls instead (see [[ch:th7-beyond-the-shell]]).

::: exercise practice | Turn on game mode automatically
Turn game mode on whenever a fullscreen window is focused, and off when it isn't.
--- hint
`ToplevelManager.activeToplevel?.fullscreen` tells you. Watch it with a `Connections` or an `onXChanged` handler on a property bound to it.
:::

## Night Light

<div class="preview"><svg width="240" height="60" viewBox="0 0 240 60"><rect x="40" y="17" width="34" height="26" rx="13" fill="#313244"/><text x="49" y="35" fill="#cdd6f4" font-size="14">☀</text><rect x="100" y="17" width="90" height="26" rx="13" fill="#fab387"/><text x="114" y="35" fill="#1e1e2e" font-size="14">☾</text><text x="136" y="35" fill="#1e1e2e" font-size="12">4000K</text></svg></div>

**What it is.** A warm-screen toggle for evenings. Click to turn on, scroll to make it warmer or cooler.

**Kind:** bar module · **Needs:** `hyprsunset`

@include galleryshell/bar/NightLight.qml

::: walk
@ 9-10 | State
The colour temperature in Kelvin, and whether it's on. "On" simply **is** "hyprsunset is running": the process's `running` property is the state, so they can never disagree.
@ 12-15 | The process
hyprsunset tints the screen for as long as it runs and restores normal colours when it exits.
@ 16-18 | Changing temperature
hyprsunset reads `-t` at start, so a new value means restarting it. The 300 ms timer waits until you stop scrolling, so it restarts once instead of on every notch.
@ 30-39 | Content
A moon when on. The temperature shows while on or hovered.
@ 42-43 | Input
Click starts or stops the process. Scrolling moves between 2500 K (very warm) and 6500 K (neutral).
:::

::: exercise challenge | On at sunset
Turn the night light on automatically between 20:00 and 07:00 using a `SystemClock`, but let a manual click override it until the next switch time.
:::

## Tray with Overflow Drawer

<div class="preview"><svg width="320" height="130" viewBox="0 0 320 130"><rect x="80" y="12" width="140" height="26" rx="13" fill="#313244"/><circle cx="100" cy="25" r="7" fill="#89b4fa"/><circle cx="128" cy="25" r="7" fill="#a6e3a1"/><circle cx="156" cy="25" r="7" fill="#f38ba8"/><circle cx="184" cy="25" r="7" fill="#f9e2af"/><text x="204" y="30" fill="#a6adc8" font-size="12">▴</text><rect x="150" y="50" width="120" height="70" rx="12" fill="#1e1e2e" stroke="#45475a"/><g><circle cx="172" cy="72" r="8" fill="#cba6f7"/><circle cx="200" cy="72" r="8" fill="#94e2d5"/><circle cx="228" cy="72" r="8" fill="#fab387"/><circle cx="172" cy="100" r="8" fill="#f5c2e7"/></g></svg></div>

**What it is.** The system tray (Discord, Steam, Nextcloud…). Only the first four icons sit in the bar; the rest are folded into a drawer behind a chevron, so a busy tray can't take over your bar. Every icon supports click, middle-click, scroll and its right-click menu.

**Kind:** bar module · **Needs:** nothing extra

@include galleryshell/bar/Tray.qml

::: walk
@ 10-14 | Splitting the items
[[SystemTray]] lists every tray item. `slice` cuts the list into the visible part and the overflow; change `maxVisible` to taste.
@ 22-26 | One component for both places
`TrayIcon` is an inline component, used in the bar row **and** in the drawer, so both behave identically.
@ 27-33 | The icon
Tray items give their icon as a ready-to-use source. It grows a little on hover.
@ 35-44 | Clicks and scroll
Left click activates the app (usually opens its window), unless the item says it is "only a menu". Middle click is the secondary action. Right click (or any click on a menu-only item) opens the menu. Scrolling is forwarded too (volume apps use it).
@ 45-51 | The app's menu
[[QsMenuAnchor]] shows the app's own menu as a native popup below the icon. For a custom-drawn menu, see [[ch:50-proj-tray]].
@ 54-67 | The bar part
The first items, then the chevron, which only appears when there is an overflow.
@ 69-88 | The drawer
A [[PopupWindow]] anchored under the chevron, holding the remaining items in a four-column grid.
:::

::: exercise practice | Hide items you never use
Add `property list<string> hiddenIds: ["nm-applet"]` and leave those out of both lists.
--- hint
Filter first: `SystemTray.items.values.filter(i => !root.hiddenIds.includes(i.id))`.
:::

## Workspaces with App Icons

<div class="preview"><svg width="340" height="60" viewBox="0 0 340 60"><rect x="20" y="17" width="66" height="26" rx="9" fill="#cba6f7"/><text x="32" y="35" fill="#1e1e2e" font-size="12" font-weight="700">1</text><circle cx="52" cy="30" r="6" fill="#fab387"/><circle cx="70" cy="30" r="6" fill="#89b4fa"/><rect x="92" y="17" width="48" height="26" rx="9" fill="#313244"/><text x="104" y="35" fill="#cdd6f4" font-size="12" font-weight="700">2</text><circle cx="124" cy="30" r="6" fill="#a6e3a1"/><rect x="146" y="17" width="30" height="26" rx="9" fill="#313244"/><text x="157" y="35" fill="#cdd6f4" font-size="12" font-weight="700">3</text><rect x="182" y="17" width="104" height="26" rx="9" fill="#f38ba8"/><text x="194" y="35" fill="#1e1e2e" font-size="12" font-weight="700">4</text><circle cx="214" cy="30" r="6" fill="#1e1e2e" opacity=".5"/><circle cx="232" cy="30" r="6" fill="#1e1e2e" opacity=".5"/><circle cx="250" cy="30" r="6" fill="#1e1e2e" opacity=".5"/><text x="262" y="34" fill="#1e1e2e" font-size="10">+2</text></svg></div>

**What it is.** Workspace buttons that show which apps are on each workspace. The focused one is purple, urgent ones red; each grows to fit its icons.

**Kind:** bar module · **Needs:** Hyprland

@include galleryshell/bar/WorkspaceList.qml

::: walk
@ 10-14 | Which workspaces
With a `screen` set, only workspaces on that screen's monitor are shown (`Hyprland.monitorFor` finds the Hyprland monitor for a Quickshell screen). Special workspaces have negative ids and are skipped. The list is sorted by id.
@ 17-20 | Icons for Hyprland windows
A `HyprlandToplevel` links to its Wayland `Toplevel` (`wayland`), which has the app id. If that isn't available yet, Hyprland's own window info (`lastIpcObject.class`) is used.
@ 24-33 | One button per workspace
Its window list comes straight from `modelData.toplevels`. Colour and width animate.
@ 39-43 | The number
`name` is the workspace's name, which is its number unless you named it.
@ 44-56 | The icons
Up to four icons, then a `+N` for the rest.
@ 58-59 | Clicking
`activate()` switches to the workspace, with no dispatcher string needed (so it works with both classic and Lua configs).
:::

::: exercise practice | Always show 1 to 5
Show workspaces 1–5 even when empty (dimmed), like the dots in [[ch:g1-bar-modules]].
--- hint
Model `5`, and look up each one with `Hyprland.workspaces.values.find(w => w.id === index + 1)`. An empty slot is activated with `Hyprland.dispatch("workspace " + (index + 1))`.
:::
