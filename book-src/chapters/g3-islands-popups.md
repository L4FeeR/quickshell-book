# Gallery: Dynamic Islands, Popups and OSDs

Floating elements that appear, morph and disappear: the Dynamic Island, toasts, on-screen displays, cheatsheets. These are their own windows, so put them directly inside `ShellRoot { }`, not inside the bar.

## Dynamic Island

<div class="preview"><svg width="460" height="150" viewBox="0 0 460 150"><rect x="0" y="0" width="460" height="6" fill="#11111b"/><rect rx="21" fill="#000"><animate attributeName="width" values="120;120;300;300;400;400;120" keyTimes="0;.12;.2;.45;.52;.85;1" dur="8s" repeatCount="indefinite" calcMode="spline" keySplines=".3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1"/><animate attributeName="x" values="170;170;80;80;30;30;170" keyTimes="0;.12;.2;.45;.52;.85;1" dur="8s" repeatCount="indefinite" calcMode="spline" keySplines=".3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1"/><animate attributeName="height" values="32;32;40;40;120;120;32" keyTimes="0;.12;.2;.45;.52;.85;1" dur="8s" repeatCount="indefinite" calcMode="spline" keySplines=".3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1;.3 1.3 .4 1"/><animate attributeName="y" values="10;10;10;10;10;10;10" dur="8s" repeatCount="indefinite"/></rect><g><animate attributeName="opacity" values="1;1;0;0;0;0;1" keyTimes="0;.12;.15;.5;.85;.95;1" dur="8s" repeatCount="indefinite"/><text x="230" y="31" fill="#fff" font-size="13" font-weight="700" text-anchor="middle">14:32</text></g><g opacity="0"><animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;.18;.22;.44;.47;1" dur="8s" repeatCount="indefinite"/><rect x="92" y="16" width="28" height="28" rx="8" fill="#cba6f7"/><text x="130" y="35" fill="#fff" font-size="12">Midnight City · M83</text><g fill="#a6e3a1"><rect x="330" y="22" width="3" height="16" rx="1.5"><animate attributeName="height" values="6;16;9;14;6" dur="0.9s" repeatCount="indefinite"/></rect><rect x="336" y="22" width="3" height="16" rx="1.5"><animate attributeName="height" values="14;6;16;8;14" dur="0.9s" repeatCount="indefinite"/></rect><rect x="342" y="22" width="3" height="16" rx="1.5"><animate attributeName="height" values="9;15;6;16;9" dur="0.9s" repeatCount="indefinite"/></rect><rect x="348" y="22" width="3" height="16" rx="1.5"><animate attributeName="height" values="16;8;13;6;16" dur="0.9s" repeatCount="indefinite"/></rect></g></g><g opacity="0"><animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;.53;.57;.83;.86;1" dur="8s" repeatCount="indefinite"/><rect x="48" y="26" width="80" height="80" rx="14" fill="#cba6f7"/><text x="144" y="46" fill="#fff" font-size="15" font-weight="700">Midnight City</text><text x="144" y="64" fill="#a6adc8" font-size="12">M83 · Hurry Up, We're Dreaming</text><rect x="144" y="78" width="250" height="4" rx="2" fill="#45475a"/><rect x="144" y="78" width="110" height="4" rx="2" fill="#fff"/><text x="200" y="104" fill="#fff" font-size="16">⏮</text><text x="240" y="104" fill="#fff" font-size="16">⏸</text><text x="280" y="104" fill="#fff" font-size="16">⏭</text></g></svg></div>

**What it is.** An iPhone-style black pill at the top center of the screen. It shows the time when idle, grows into a strip with album art and moving bars while music plays, briefly widens with the volume level when you change it, pops out notifications, and expands into full media controls when you click it. Every change is a spring-like morph.

**Kind:** its own window · **Needs:** PipeWire, MPRIS (optional: your notification service)

@include galleryshell/popups/DynamicIsland.qml

Add to your shell: `DynamicIsland { id: island }`. From your notification service, call `island.notify(n.summary, n.body)`.

::: walk
This is the biggest widget in the gallery, but it's built from one simple idea: **one black shape, one `mode` string, and content that fades in for each mode.**
@ 1-7 | Imports
Media comes from `Quickshell.Services.Mpris` (players like Spotify and browsers), volume from Pipewire, and [[ClippingRectangle]] from `Quickshell.Widgets` for rounded album art.
@ 9-15 | Data sources
A `Scope` is an invisible container for non-visual things and windows. `player` is the first player that is currently playing (or `null`). `sink` is the default audio output, tracked so its volume is readable.
@ 17-22 | Temporary states
`expanded` is the click-to-open state. `flash` holds a temporary mode ("volume" or "notify") that should disappear by itself. `showFlash()` sets it and restarts a 2-second timer; the timer clears it. Restarting means a second volume change while the first flash is showing extends it instead of cutting it short.
@ 24-31 | React to volume changes
`Connections` listens to signals of the sink's audio object. The `armed` flag ignores changes during the first 1.5 seconds, because PipeWire reports the initial volume at startup and we don't want a flash then.
@ 32-33 | An API for notifications
A public function your notification service can call: `island.notify(n.summary, n.body)`. The island doesn't need to know where notifications come from.
@ 35-39 | Choosing the mode
A chain of conditions with clear **priorities**: expanded beats a notification, which beats a volume flash, which beats media, which beats idle. Everything else in the widget just reads `mode`.
@ 40-46 | Size per mode
An object maps each mode to a size, and `[mode]` picks the current one. Want a bigger notification? Change one number here.
@ 48-58 | The window
The window is fixed at 420×160 (the biggest the island gets) and centered at the top. It doesn't push windows (`ExclusionMode.Ignore`) and lives on the `Overlay` layer above everything. `mask: Region { item: island }` is essential: only the black pill catches clicks; the transparent rest of the window lets clicks through to your apps.
@ 60-71 | The morphing shape
Width and height come from `targetSize`. `radius: Math.min(height / 2, 28)` keeps a pill shape when small and caps the roundness when tall. `clip: true` hides content outside the shape while it's still growing. `SpringAnimation` (instead of a normal easing) simulates a spring: `spring` is stiffness, `damping` how fast it calms down. Low damping (0.32) gives the slight wobble that makes it feel physical.
@ 73 | Click to expand
Toggling `expanded` changes `mode` (only if something is playing), which changes the size and content.
@ 75-83 | Idle content
A clock that is visible only in idle mode. Every content block follows this pattern: `opacity: mode === "x" ? 1 : 0` with a short `Behavior`, so modes crossfade.
@ 85-91 | Media strip container
Same pattern, plus `visible: opacity > 0`: fully faded blocks become invisible, so they don't catch clicks or cost rendering time.
@ 92-100 | Art and title
Small rounded art, then title · artist, eliding when long.
@ 101-117 | Fake equalizer
Four thin bars whose heights loop up and down. Each bar uses slightly different durations (`280 + index * 70`), so they drift out of sync and look random. They run only in media mode.
@ 120-139 | Volume flash
An icon and a bar showing the current volume, the same as a small OSD.
@ 141-150 | Notification
Title in bold, body dimmer, both eliding.
@ 152-191 | Expanded controls
Large art, title, artist, a progress bar, and three buttons. The buttons come from a `Repeater` over a list of `{ i: icon, f: function }` objects, so each button's action is stored next to its icon; `modelData.f()` calls it.
@ 194-196 | Keeping progress live
MPRIS doesn't push position updates continuously. While expanded and playing, this timer emits `positionChanged()` every second, which makes the progress binding re-read `position`.
:::

**Customize**
- Put it at the bottom: `anchors.bottom: true` and anchor the island to the bottom.
- Add more modes: charging (green bolt when `UPower.onBattery` turns false), screen recording timer, Caps Lock.
- Swap the fake equalizer for real levels with [[PwNodePeakMonitor]].
- Hover to peek: `HoverHandler` that switches to a slightly larger `"peek"` size.

::: exercise challenge | Charging mode
Add a `"charging"` mode: when you plug in your laptop, flash a green bolt with the battery percentage for 2 seconds.
--- hint
Listen to `UPower.onBatteryChanged`, call `showFlash("charging")`, add it to the `mode` chain and `targetSize`, and add a content block with the same opacity pattern.
:::

## Expanding Media Pill

<div class="preview"><svg width="380" height="70" viewBox="0 0 380 70"><rect y="17" height="36" rx="18" fill="#313244"><animate attributeName="width" values="150;340;340;150;150" keyTimes="0;.2;.65;.85;1" dur="6s" repeatCount="indefinite"/><animate attributeName="x" values="115;20;20;115;115" keyTimes="0;.2;.65;.85;1" dur="6s" repeatCount="indefinite"/></rect><circle cx="139" cy="35" r="13" fill="#cba6f7"><animate attributeName="cx" values="139;44;44;139;139" keyTimes="0;.2;.65;.85;1" dur="6s" repeatCount="indefinite"/><animateTransform attributeName="transform" type="rotate" values="0 139 35;360 139 35" dur="4s" repeatCount="indefinite"/></circle><text x="160" y="40" fill="#cdd6f4" font-size="12">Midnight City<animate attributeName="x" values="160;66;66;160;160" keyTimes="0;.2;.65;.85;1" dur="6s" repeatCount="indefinite"/></text><g opacity="0"><animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;.18;.25;.62;.66;1" dur="6s" repeatCount="indefinite"/><text x="250" y="40" fill="#cdd6f4" font-size="14">⏮  ⏸  ⏭</text></g></svg></div>

**What it is.** A small pill with a spinning album-art disc and the song title; hover and it expands to reveal previous/play/next controls.

**Kind:** bar module · **Needs:** MPRIS

@include galleryshell/bar/MediaPill.qml

::: walk
@ 6-10 | Which player?
Prefer a player that is playing; otherwise the first player; otherwise `null`. The pill hides when no player exists.
@ 12-17 | Growing pill
The pill sizes itself from its row, and `Behavior on implicitWidth` animates every size change. `clip: true` hides controls while the pill is still too small.
@ 19-22 | Left-anchored row
The row is anchored to the **left**, so the pill grows to the right and the disc stays put.
@ 23-27 | Spinning disc
Round album art (radius = half the size) that rotates once every 6 seconds while playing, like a record. When paused, the animation stops where it is.
@ 28-33 | Title with a growing limit
`Layout.maximumWidth` allows 120 px normally and 220 px when open, so hovering reveals more of the title.
@ 34-44 | Controls appear on hover
The trick: when not hovered, the Repeater's model is an empty array, so no buttons exist. On hover the model gets three entries, three buttons are created, the row grows, and the pill animates to fit. Each entry pairs an icon with a function.
:::

::: exercise practice | Scroll to skip
Scroll up/down over the pill to go to the next/previous track.
--- solution
```qml
WheelHandler { onWheel: e => e.angleDelta.y < 0 ? root.p.next() : root.p.previous() }
```
:::

## Toast Notification

<div class="preview"><svg width="380" height="110" viewBox="0 0 380 110"><g><animateTransform attributeName="transform" type="translate" values="0 -70;0 0;0 0;0 -70;0 -70" keyTimes="0;.12;.7;.82;1" dur="5s" repeatCount="indefinite"/><rect x="60" y="20" width="260" height="56" rx="16" fill="#1e1e2e" stroke="#45475a"/><circle cx="88" cy="48" r="14" fill="#a6e3a1"/><path d="M81 48l5 5 9-10" stroke="#1e1e2e" stroke-width="3" fill="none"/><text x="112" y="44" fill="#cdd6f4" font-size="13" font-weight="700">Screenshot saved</text><text x="112" y="62" fill="#a6adc8" font-size="11">Copied to clipboard</text></g></svg></div>

**What it is.** A small message that slides down from the top, stays 2.5 seconds, and slides away. Trigger it from anywhere: other widgets, IPC, scripts.

**Kind:** its own window · **Needs:** nothing extra

@include galleryshell/popups/Toast.qml

```bash
qs -c gallery ipc call toast ok "Screenshot saved" "Copied to clipboard"
```

::: walk
@ 7-13 | State
What to show (title, body, icon, color) and whether it's on screen.
@ 15-20 | Showing
`show()` fills in the content, sets `shown`, and restarts a 2.5-second hide timer. Calling it again while visible replaces the content and extends the time.
@ 22-27 | IPC entry points
Three variants for scripts and keybinds: neutral `show`, green `ok`, red `error`. `qs ipc call toast ok "Saved"` from a terminal calls `ok()` here.
@ 29-38 | The window
A 340×100 transparent window at the top. `visible: root.shown || slide.running` keeps it alive while the card slides **out**; without it, the window would vanish instantly and you'd never see the exit animation.
@ 40-46 | Slide in from above
The card's `y` is 12 when shown and above the window (`-height - 10`) when hidden. `OutBack` with a little overshoot makes it drop in and settle. `id: slide` names the animation so the window can check `slide.running`.
@ 48-58 | Content
A filled icon in the toast's color, then title and optional body (`visible: text` hides an empty body, and the card stays compact).
@ 59 | Click to dismiss
Users can tap it away early.
:::

::: exercise practice | Screenshot toast
Write a Hyprland keybind that takes a screenshot with `grim` and shows an `ok` toast afterwards.
--- solution
```ini
bind = , Print, exec, grim ~/Pictures/shot.png && qs -c myshell ipc call toast ok "Screenshot saved" "~/Pictures/shot.png"
```
:::

## Vertical Volume OSD

<div class="preview"><svg width="200" height="200" viewBox="0 0 200 200"><rect x="80" y="20" width="44" height="160" rx="22" fill="#1e1e2e" stroke="#313244"/><rect x="86" width="32" rx="16" fill="#cba6f7"><animate attributeName="height" values="60;120;90;60" dur="4s" repeatCount="indefinite"/><animate attributeName="y" values="114;54;84;114" dur="4s" repeatCount="indefinite"/></rect><path d="M96 158h5l6-5v14l-6-5h-5z" fill="#1e1e2e"/></svg></div>

**What it is.** A tall pill on the right edge that fills like a glass when volume or brightness changes, then fades away.

**Kind:** its own window · **Needs:** PipeWire

@include galleryshell/popups/VerticalOsd.qml

::: walk
@ 8-11 | State
`value` is the displayed level: 0 when muted, capped at 1. `shown` controls visibility; `armed` blocks the startup flash.
@ 13-20 | Triggering
The tracker makes volume readable. Two timers: one arms the OSD after startup, the other hides it 1.5 s after the last change. Both volume and mute changes show it and restart the hide timer.
@ 22-30 | Window
Anchored only to the right edge, so it's vertically centered there. `mask: Region {}` is an **empty** region: the window never catches clicks. It stays mapped while fading out.
@ 32-38 | Card with fade
A tall pill that fades in and out.
@ 40-46 | Fill from the bottom
Anchoring to `bottom` makes the fill grow upward as its height increases. `Math.max(width, …)` keeps it at least a circle so it never looks like a broken sliver at low volume.
@ 47-52 | Icon inside the fill
The icon sits at the bottom inside the fill, in a dark color so it reads on the accent.
:::

::: exercise practice | Slide in
The card has `x: root.shown ? 0 : 20` but no animation on it. Add a `Behavior on x` so it slides in from the right while fading.
:::

## Circular OSD

<div class="preview"><svg width="200" height="150" viewBox="0 0 200 150"><circle cx="100" cy="75" r="56" fill="#1e1e2e"/><circle cx="100" cy="75" r="44" fill="none" stroke="#313244" stroke-width="8"/><circle cx="100" cy="75" r="44" fill="none" stroke="#f9e2af" stroke-width="8" stroke-linecap="round" transform="rotate(-90 100 75)" stroke-dasharray="180 277"><animate attributeName="stroke-dasharray" values="80 277;230 277;80 277" dur="4s" repeatCount="indefinite"/></circle><text x="100" y="72" fill="#f9e2af" font-size="20" text-anchor="middle">☀</text><text x="100" y="94" fill="#cdd6f4" font-size="13" font-weight="700" text-anchor="middle">65</text></svg></div>

**What it is.** A round gauge in the middle-bottom of the screen for brightness (or volume): a ring that fills around an icon and a number.

**Kind:** its own window · **Needs:** `brightnessctl` for keys; reads sysfs

@include galleryshell/popups/CircularOsd.qml

::: walk
@ 9-14 | Backlight state
`dev` is the backlight device name (check `ls /sys/class/backlight`). `max` and `cur` come from sysfs; `value` is their ratio.
@ 16 | Maximum brightness
Read once. Template strings (backticks with `${}`) build the path from `dev`.
@ 17-22 | Watching the brightness file
`watchChanges: true` asks the kernel to notify us when the file changes; `onFileChanged: reload()` re-reads it; `onLoaded` updates `cur` and shows the OSD. This catches **every** brightness change: your keys, a script, or auto-brightness, without polling.
@ 26-34 | Window
Bottom-center, click-through, mapped while the pop animation runs.
@ 36-42 | Pop in
The content scales from 0.6 to 1 with `OutBack` (a small overshoot) while fading in.
@ 43-55 | Ring
A dark circle, a gray full ring as the track, and a yellow arc from the top whose sweep is `360 * value`.
@ 56-62 | Center
A sun icon and the percentage.
:::

::: exercise practice | Find the device
Detect the backlight device automatically with a `Process` running `ls /sys/class/backlight | head -1`.
:::

## Charging Animation Popup

<div class="preview"><svg width="240" height="140" viewBox="0 0 240 140"><rect x="40" y="20" width="160" height="100" rx="24" fill="#1e1e2e"/><rect x="80" y="45" width="70" height="36" rx="8" fill="none" stroke="#a6e3a1" stroke-width="3"/><rect x="150" y="56" width="6" height="14" rx="2" fill="#a6e3a1"/><rect x="85" y="50" height="26" rx="4" fill="#a6e3a1"><animate attributeName="width" values="10;60;10" dur="2.5s" repeatCount="indefinite"/></rect><path d="M118 52l-8 12h7l-3 10 9-13h-7z" fill="#1e1e2e"/><text x="120" y="104" fill="#cdd6f4" font-size="13" font-weight="700" text-anchor="middle">Charging · 64%</text></svg></div>

**What it is.** When you plug in the charger, a card with a filling battery animation pops up for two seconds, like on phones.

**Kind:** its own window · **Needs:** UPower

@include galleryshell/popups/ChargingPopup.qml

::: walk
@ 8-17 | Detecting "plugged in"
`UPower.onBattery` is true on battery, false on AC. Comparing with the previous value tells us the **direction** of the change: we only show the popup when it goes from battery to AC, not when unplugging.
@ 18 | Auto-hide
2.2 seconds is long enough to see one fill animation.
@ 20-26 | Window
With no anchors, a layer-shell window is centered on screen. Click-through.
@ 28-34 | Card animation
Scales and fades in with a small bounce.
@ 36-40 | Battery outline
A bordered rounded rectangle plus a small "tip" on the right, drawn as a second rectangle positioned at `x: parent.width`.
@ 41-49 | Filling animation
The inner rectangle's width loops from almost empty up to the current charge level, pauses, and repeats: a "charging" motion that stops at the real percentage.
@ 50-57 | Bolt and label
A filled bolt icon over the battery, and the percentage below.
:::

::: exercise practice | Unplugged popup
Show a different, gray popup when you **unplug** the charger.
:::

## Hold-to-Show Keybind Cheatsheet

<div class="preview"><svg width="420" height="170" viewBox="0 0 420 170"><g opacity="0"><animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;.1;.18;.7;.78;1" dur="5s" repeatCount="indefinite"/><rect x="30" y="15" width="360" height="140" rx="20" fill="#1e1e2e" stroke="#45475a"/><text x="210" y="40" fill="#cba6f7" font-size="13" font-weight="700" text-anchor="middle">Keybinds</text><g font-size="11"><rect x="50" y="54" width="56" height="20" rx="5" fill="#313244"/><text x="78" y="68" fill="#cdd6f4" text-anchor="middle">SUPER+⏎</text><text x="116" y="68" fill="#a6adc8">Terminal</text><rect x="220" y="54" width="56" height="20" rx="5" fill="#313244"/><text x="248" y="68" fill="#cdd6f4" text-anchor="middle">SUPER+Q</text><text x="286" y="68" fill="#a6adc8">Close</text><rect x="50" y="84" width="56" height="20" rx="5" fill="#313244"/><text x="78" y="98" fill="#cdd6f4" text-anchor="middle">SUPER+␣</text><text x="116" y="98" fill="#a6adc8">Launcher</text><rect x="220" y="84" width="56" height="20" rx="5" fill="#313244"/><text x="248" y="98" fill="#cdd6f4" text-anchor="middle">SUPER+L</text><text x="286" y="98" fill="#a6adc8">Lock</text><rect x="50" y="114" width="56" height="20" rx="5" fill="#313244"/><text x="78" y="128" fill="#cdd6f4" text-anchor="middle">SUPER+1-9</text><text x="116" y="128" fill="#a6adc8">Workspace</text><rect x="220" y="114" width="56" height="20" rx="5" fill="#313244"/><text x="248" y="128" fill="#cdd6f4" text-anchor="middle">SUPER+V</text><text x="286" y="128" fill="#a6adc8">Clipboard</text></g></g></svg></div>

**What it is.** Hold a key and a grid of your keybinds appears; release it and it disappears. It reads your binds live from Hyprland, so it's always up to date.

**Kind:** its own window · **Needs:** Hyprland, `jq`

@include galleryshell/popups/Cheatsheet.qml

```ini file="hyprland.conf"
bind = SUPER, slash, global, quickshell:cheatsheet
```

The global-shortcuts protocol reports both the press and the release of that one bind.

Add descriptions with `bindd = SUPER, Return, Terminal, exec, kitty` and they show instead of the raw command.

::: walk
@ 8-11 | State
`shown` while the key is held, `binds` the parsed keybind list.
@ 13-17 | Global shortcut
[[GlobalShortcut]] registers `quickshell:cheatsheet` with Hyprland. Unlike an IPC call from a keybind, it reports both **press and release**. On press we reload the binds (so they're always current) and show; on release we hide.
@ 19-33 | Parsing hyprctl
`hyprctl binds -j` returns JSON. `modmask` is a bit field: each modifier is one bit (Super = 64, Shift = 1, Ctrl = 4, Alt = 8). `mods()` checks each bit with `&` and returns the names. Mouse binds and keyless entries are skipped. Each bind becomes `{ keys: "SUPER+SHIFT+Q", what: "…" }`, using your `bindd` description when you wrote one. We keep 40 to fit the screen.
@ 35-46 | Window and fade
Sized from the grid's height. A short fade keeps it snappy, which matters for a hold-to-show overlay.
@ 48-66 | Two-column grid
A `GridLayout` with 2 columns. Each row shows the keys in a monospace "keycap" box and the action next to it, eliding if long.
:::

::: exercise practice | Group by modifier
Sort the binds so all `SUPER+SHIFT` binds come after plain `SUPER` binds.
--- hint
`.sort((a, b) => a.keys.split("+").length - b.keys.split("+").length)`
:::
