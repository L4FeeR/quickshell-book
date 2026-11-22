# Gallery: Desktop Widgets

Widgets that sit on your wallpaper, below your windows: clocks, weather, system rings, graphs, a visualizer, a pomodoro timer. They all use the same recipe: a [[PanelWindow]] on the **Bottom** layer, `ExclusionMode.Ignore`, a transparent background, and usually `mask: Region {}` so clicks pass through to the desktop.

> [!TIP] A reusable base
> [[ch:62-proj-desktop]] builds a `DesktopWidget.qml` base with <kbd>Super</kbd>+drag to move and positions saved to disk. Every widget here can use it instead of a raw PanelWindow.

## Big Desktop Clock

<div class="preview"><svg width="420" height="170" viewBox="0 0 420 170"><text x="40" y="100" fill="#cba6f7" font-size="88" font-weight="900" letter-spacing="-3">14:32</text><text x="46" y="136" fill="#cdd6f4" font-size="20">Friday, 21 November</text><text x="300" y="100" fill="#cba6f7" font-size="22" font-weight="700" opacity=".6">47<animate attributeName="opacity" values=".6;.2;.6" dur="1s" repeatCount="indefinite"/></text></svg></div>

**What it is.** A huge clock and date on the desktop, with a soft shadow so it's readable on any wallpaper. Seconds are shown small and fade with each tick.

**Kind:** desktop widget · **Needs:** nothing extra

@include galleryshell/desktop/DesktopClock.qml

::: walk
@ 6-14 | A desktop-layer window
- Anchored top-left with margins: the clock's position on screen.
- `ExclusionMode.Ignore`: windows aren't pushed away by it.
- `mask: Region {}`: an empty input region, so clicks pass through to the desktop.
- `WlrLayer.Bottom`: above the wallpaper (`Background`) but below normal windows. Open a window and it covers the clock.
@ 16 | Seconds precision
This clock shows seconds, so it updates every second.
@ 21-29 | Big time
Inter Black at 110 px with negative letter spacing (`-4`) pulls the big digits together for a poster-like look. Tabular numbers keep the width constant.
@ 30-38 | Seconds that pulse
`anchors.baseline` aligns the small seconds with the bottom of the big digits, the way magazines set mixed sizes. Every time the text changes (once a second), `tick.restart()` fades it from 0.9 to 0.4: a gentle heartbeat.
@ 40-44 | Date
Placed under the time with a negative top margin to tuck it closer: big fonts have lots of empty space below the digits.
@ 45-46 | One shadow for everything
`layer.enabled` renders the whole group into a texture, and `MultiEffect` adds a soft drop shadow to it. This keeps the text readable on bright wallpapers and costs one effect instead of one per text.
:::

**Customize**
- Vertical stacked style: `"hh"` and `"mm"` on two lines with a large `lineHeight` of 0.8.
- Per-monitor: wrap in `Variants { model: Quickshell.screens }` ([[ch:31-multi-monitor]]).

::: exercise practice | 12-hour mode
Add `property bool use12h` that shows `h:mm` plus a small `AM/PM` instead of the seconds.
:::

## Analog Clock

<div class="preview"><svg width="200" height="200" viewBox="0 0 200 200"><circle cx="100" cy="100" r="80" fill="#1e1e2e" stroke="#45475a" stroke-width="2"/><g stroke="#585b70" stroke-width="3" stroke-linecap="round"><path d="M100 28v8M100 164v8M28 100h8M164 100h8"/></g><line x1="100" y1="100" x2="100" y2="58" stroke="#cdd6f4" stroke-width="6" stroke-linecap="round" transform="rotate(45 100 100)"/><line x1="100" y1="100" x2="100" y2="38" stroke="#cdd6f4" stroke-width="4" stroke-linecap="round" transform="rotate(192 100 100)"/><line x1="100" y1="112" x2="100" y2="32" stroke="#f38ba8" stroke-width="2" stroke-linecap="round"><animateTransform attributeName="transform" type="rotate" from="0 100 100" to="360 100 100" dur="60s" repeatCount="indefinite"/></line><circle cx="100" cy="100" r="5" fill="#f38ba8"/></svg></div>

**What it is.** A classic clock face with hour, minute and a smoothly sweeping second hand.

**Kind:** desktop widget · **Needs:** nothing extra

@include galleryshell/desktop/AnalogClock.qml

::: walk
@ 5-14 | Window
Top-right desktop window, click-through, updated every second.
@ 16-22 | A hand component
A hand is a thin rounded rectangle. It's positioned so its **base** sits at the center of the face (`y: face.height / 2 - len`), and it extends 10 px past the center as a tail. The rotation is added where each hand is used, because each needs a different angle.
@ 24-29 | Face
A circle (radius = half the width) with a subtle border.
@ 31-40 | Hour ticks
Twelve small rectangles at the top, each rotated around the **center of the face** (`origin.y` is the distance from the tick to the center) by `index * 30°`. Every third one (12, 3, 6, 9) is thicker and longer.
@ 41-44 | Hour and minute hands
The origin of the rotation is the hand's base. Angles: the hour hand moves 30° per hour **plus** a fraction for the minutes, so at 2:30 it sits halfway between 2 and 3. The minute hand moves 6° per minute plus a fraction for the seconds.
@ 45-51 | Second hand with a tick
Instead of binding the rotation directly, the angle goes through a property `a` with a `Behavior` using `OutBack`: each second it jumps forward with a tiny overshoot, like a mechanical watch.
@ 52 | Center cap
A dot covering the point where the hands meet.
:::

::: exercise practice | Fix the wrap-around
Follow the note below: use an ever-increasing seconds counter so the second hand never spins backwards at :00.
--- solution
```qml
property int total: 0
Timer { interval: 1000; running: true; repeat: true; onTriggered: total++ }
property real a: total * 6
```
Initialize `total` from `clock.seconds` once in `Component.onCompleted`.
:::

## Weather Card

<div class="preview"><svg width="300" height="160" viewBox="0 0 300 160"><rect x="20" y="15" width="260" height="130" rx="22" fill="#1e1e2e" opacity=".85"/><circle cx="76" cy="66" r="20" fill="#f9e2af"><animate attributeName="r" values="19;22;19" dur="3s" repeatCount="indefinite"/></circle><path d="M70 82h40a14 14 0 0 0 0-28 20 20 0 0 0-38 6 11 11 0 0 0-2 22z" fill="#cdd6f4" opacity=".9"/><text x="140" y="70" fill="#cdd6f4" font-size="34" font-weight="800">28°</text><text x="140" y="92" fill="#a6adc8" font-size="12">Partly cloudy · Kochi</text><g fill="#a6adc8" font-size="11"><text x="44" y="126">Sat 30°</text><text x="114" y="126">Sun 27°</text><text x="184" y="126">Mon 29°</text></g></svg></div>

**What it is.** A translucent card with the current weather, location, and a three-day forecast.

**Kind:** desktop widget · **Needs:** `curl` (uses wttr.in, no key)

@include galleryshell/desktop/WeatherCard.qml

::: walk
@ 7-17 | Window and data
`wx` holds the whole wttr.in JSON response, or `null` before it arrives. The card is a desktop-layer window at the bottom-left.
@ 19-27 | Code → icon
Same mapping as the weather chip, with a snow icon.
@ 29-34 | Fetch every 30 minutes
The whole response is stored; `try/catch` ignores failures (the card keeps showing the last good data).
@ 36-37 | Convenience properties
`now` is the current conditions and `place` the nearest area's name. The `?.` / `?.[0]` chains return `undefined` instead of throwing while `wx` is still `null`, so the card shows placeholders instead of errors.
@ 45-54 | Current weather
A big filled weather icon next to the temperature (in a heavy font) and "description · place".
@ 55-65 | Three-day forecast
`wx.weather` is an array of days. Each shows the short weekday and max/min temperatures.
:::

::: exercise practice | Click to refresh
Make a click on the card fetch new data immediately, with a small spinning refresh icon while loading.
:::

## System Rings Dashboard

<div class="preview"><svg width="380" height="150" viewBox="0 0 380 150"><rect x="10" y="10" width="360" height="130" rx="22" fill="#1e1e2e" opacity=".85"/><g fill="none" stroke-width="8" stroke-linecap="round"><circle cx="80" cy="70" r="34" stroke="#313244"/><circle cx="80" cy="70" r="34" stroke="#cba6f7" stroke-dasharray="70 214" transform="rotate(-90 80 70)"><animate attributeName="stroke-dasharray" values="50 214;110 214;50 214" dur="4s" repeatCount="indefinite"/></circle><circle cx="190" cy="70" r="34" stroke="#313244"/><circle cx="190" cy="70" r="34" stroke="#94e2d5" stroke-dasharray="130 214" transform="rotate(-90 190 70)"/><circle cx="300" cy="70" r="34" stroke="#313244"/><circle cx="300" cy="70" r="34" stroke="#a6e3a1" stroke-dasharray="170 214" transform="rotate(-90 300 70)"/></g><g fill="#cdd6f4" font-size="14" font-weight="700" text-anchor="middle"><text x="80" y="75">33%</text><text x="190" y="75">61%</text><text x="300" y="75">80%</text></g><g fill="#a6adc8" font-size="11" text-anchor="middle"><text x="80" y="126">CPU</text><text x="190" y="126">RAM</text><text x="300" y="126">BATTERY</text></g></svg></div>

**What it is.** Three animated rings for CPU, RAM and battery (or disk) on a translucent card.

**Kind:** desktop widget · **Needs:** nothing extra

@include galleryshell/desktop/SystemRings.qml

::: walk
@ 19-21 | State
CPU and RAM as 0–1, and the previous CPU counters.
@ 23-37 | One timer, two sources
Every 2 seconds both files are re-read. CPU usage uses the same counter-difference method as the CPU sparkline. For RAM, `get(k)` is a tiny helper that finds `k: <number>` in meminfo; `?? [0, 0]` avoids a crash if a field is missing. `Math.max(1, …)` avoids dividing by zero.
@ 39-46 | Ring component with smoothing
`shown` follows `value` through an 800 ms `Behavior`, so the arc glides to new values instead of jumping every 2 seconds. The text shows the exact `value`.
@ 47-55 | Drawing the ring
A track circle and a colored arc from 12 o'clock, plus the percentage in the middle.
@ 56-57 | Label
Small, wide-spaced caps under the ring: a common dashboard style.
@ 60-70 | Card with three rings
The battery ring only appears on laptops.
:::

::: exercise practice | Temperature ring
Add a fourth ring for CPU temperature (0–100 °C mapped to 0–1), using the sensor search from the CPU Temperature widget.
:::

## CPU History Graph

<div class="preview"><svg width="360" height="150" viewBox="0 0 360 150"><rect x="10" y="10" width="340" height="130" rx="20" fill="#1e1e2e" opacity=".85"/><text x="28" y="34" fill="#cba6f7" font-size="12" font-weight="700">CPU · 60s</text><text x="330" y="34" fill="#cdd6f4" font-size="12" text-anchor="end">42%</text><path d="M28 120 L28 90 L58 96 L88 70 L118 82 L148 60 L178 74 L208 50 L238 66 L268 58 L298 80 L330 64 L330 120 Z" fill="#cba6f7" opacity=".2"/><polyline fill="none" stroke="#cba6f7" stroke-width="2.5" stroke-linejoin="round" points="28,90 58,96 88,70 118,82 148,60 178,74 208,50 238,66 268,58 298,80 330,64"/><g stroke="#313244"><path d="M28 70h302M28 95h302"/></g></svg></div>

**What it is.** A smooth area chart of CPU usage over the last minute, with grid lines and the current value.

**Kind:** desktop widget · **Needs:** nothing extra

@include galleryshell/desktop/CpuGraph.qml

::: walk
@ 16-28 | Collecting 60 samples
Same CPU calculation as before; each new value is appended to `points` and the array is trimmed to the last 60 (one minute).
@ 33-35 | Header
Title on the left, the latest value on the right (`points[points.length - 1]`).
@ 39-42 | Grid lines
Two faint horizontal lines at one-third and two-thirds of the height make the graph easier to read.
@ 43-46 | Coordinates
`step` spreads 60 samples across the width; `x0` right-aligns them while fewer than 60 exist. `xy(i)` converts sample `i` into canvas coordinates.
@ 47-52 | Smooth line
Instead of straight segments, each step draws a quadratic curve to the **midpoint** between two samples, using the sample itself as the control point. The result is a smooth line that still passes near every value.
@ 53-56 | Gradient fill
Close the shape along the bottom, then fill it with a vertical gradient from 40% accent to fully transparent.
@ 58 | Repaint on new data
:::

::: exercise practice | RAM line
Draw a second line for RAM in another color on the same canvas.
:::

## Pomodoro Timer

<div class="preview"><svg width="240" height="210" viewBox="0 0 240 210"><rect x="20" y="10" width="200" height="190" rx="26" fill="#1e1e2e" opacity=".9"/><circle cx="120" cy="92" r="60" fill="none" stroke="#313244" stroke-width="10"/><circle cx="120" cy="92" r="60" fill="none" stroke="#f38ba8" stroke-width="10" stroke-linecap="round" stroke-dasharray="250 377" transform="rotate(-90 120 92)"><animate attributeName="stroke-dasharray" values="377 377;0 377" dur="20s" repeatCount="indefinite"/></circle><text x="120" y="100" fill="#cdd6f4" font-size="26" font-weight="800" text-anchor="middle">18:42</text><text x="120" y="122" fill="#f38ba8" font-size="11" text-anchor="middle">FOCUS</text><text x="120" y="182" fill="#a6adc8" font-size="11" text-anchor="middle">click: pause · right: reset</text></svg></div>

**What it is.** A focus timer: 25 minutes of work, then a 5-minute break (15 after every fourth). The ring empties as time passes, and a notification fires on each switch.

**Kind:** desktop widget (clickable) · **Needs:** `libnotify` (`notify-send`)

@include galleryshell/desktop/Pomodoro.qml

::: walk
@ 16-23 | Settings and state
Durations in seconds, whether we're on a break, which round (every 4th break is long), the current phase's `length`, seconds `left`, and `running`.
@ 25-30 | Switching phases
From focus to break (long every 4th round), or from break back to focus (next round). It resets `left` and sends a critical notification so you notice even with a fullscreen app.
@ 31-32 | Ticking and IPC
One-second timer while running; at zero it moves to the next phase. IPC lets a keybind start/pause it.
@ 34 | Phase color
Red for focus, green for breaks.
@ 39-46 | Shrinking ring
`sweepAngle: 360 * left / length` shrinks from a full circle to nothing over the phase.
@ 47-55 | Center text
`m:ss` with a padded seconds part, then "FOCUS"/"BREAK", a paused marker and the round number.
@ 57-58 | Mouse controls
Left click pauses/resumes. Right click resets everything to round 1. This window has no empty mask, so it does receive clicks.
:::

::: exercise practice | Save progress
Save `left`, `round` and `onBreak` to a state file so a shell reload doesn't reset your session.
:::

## Quote of the Day

<div class="preview"><svg width="420" height="130" viewBox="0 0 420 130"><text x="30" y="60" fill="#cba6f7" font-size="60" font-weight="900" opacity=".5">“</text><text x="70" y="58" fill="#cdd6f4" font-size="17" font-style="italic">Simplicity is the soul of efficiency.</text><text x="70" y="88" fill="#a6adc8" font-size="12">— Austin Freeman</text></svg></div>

**What it is.** A quote on the desktop that changes daily (or on click), from a local list, so it works offline.

**Kind:** desktop widget · **Needs:** nothing extra

@include galleryshell/desktop/Quote.qml

**Customize**
- Online quotes: `curl -s https://zenquotes.io/api/today` returns JSON `[{ q, a }]`.

::: walk
@ 15-22 | Quotes as data
Each entry is `[text, author]`.
@ 23-26 | One quote per day
`getTime() / 86400000` is the number of days since 1970. Taking it modulo the list length picks a different quote each day, the same one all day. `offset` lets you skip ahead by clicking. The clock has `Hours` precision, so the binding re-checks every hour and changes after midnight.
@ 34-41 | Fade in
The quote starts invisible and fades in when created.
@ 44-46 | Shadow and click
A soft shadow for readability, and a tap to show the next quote.
:::

::: exercise practice | Quotes from a file
Load quotes from a JSON file in your config folder with `FileView` + `JSON.parse`.
:::

## Audio Visualizer Bars

<div class="preview"><svg width="420" height="140" viewBox="0 0 420 140"><g fill="#cba6f7"><rect x="30" width="10" rx="4" y="60" height="60"><animate attributeName="height" values="20;80;35;60;20" dur="1.1s" repeatCount="indefinite"/><animate attributeName="y" values="100;40;85;60;100" dur="1.1s" repeatCount="indefinite"/></rect><rect x="48" width="10" rx="4" y="60" height="60"><animate attributeName="height" values="70;30;90;40;70" dur="0.9s" repeatCount="indefinite"/><animate attributeName="y" values="50;90;30;80;50" dur="0.9s" repeatCount="indefinite"/></rect><rect x="66" width="10" rx="4" y="60" height="60"><animate attributeName="height" values="40;95;50;75;40" dur="1.3s" repeatCount="indefinite"/><animate attributeName="y" values="80;25;70;45;80" dur="1.3s" repeatCount="indefinite"/></rect><rect x="84" width="10" rx="4" y="60" height="60" fill="#b4befe"><animate attributeName="height" values="90;45;70;30;90" dur="1s" repeatCount="indefinite"/><animate attributeName="y" values="30;75;50;90;30" dur="1s" repeatCount="indefinite"/></rect><rect x="102" width="10" rx="4" y="60" height="60" fill="#b4befe"><animate attributeName="height" values="30;70;100;55;30" dur="1.2s" repeatCount="indefinite"/><animate attributeName="y" values="90;50;20;65;90" dur="1.2s" repeatCount="indefinite"/></rect><rect x="120" width="10" rx="4" y="60" height="60" fill="#89b4fa"><animate attributeName="height" values="60;20;80;40;60" dur="0.8s" repeatCount="indefinite"/><animate attributeName="y" values="60;100;40;80;60" dur="0.8s" repeatCount="indefinite"/></rect><rect x="138" width="10" rx="4" y="60" height="60" fill="#89b4fa"><animate attributeName="height" values="85;50;30;75;85" dur="1.15s" repeatCount="indefinite"/><animate attributeName="y" values="35;70;90;45;35" dur="1.15s" repeatCount="indefinite"/></rect><rect x="156" width="10" rx="4" y="60" height="60" fill="#89b4fa"><animate attributeName="height" values="45;90;60;25;45" dur="0.95s" repeatCount="indefinite"/><animate attributeName="y" values="75;30;60;95;75" dur="0.95s" repeatCount="indefinite"/></rect><rect x="174" width="10" rx="4" y="60" height="60" fill="#94e2d5"><animate attributeName="height" values="25;65;95;50;25" dur="1.05s" repeatCount="indefinite"/><animate attributeName="y" values="95;55;25;70;95" dur="1.05s" repeatCount="indefinite"/></rect><rect x="192" width="10" rx="4" y="60" height="60" fill="#94e2d5"><animate attributeName="height" values="75;35;55;90;75" dur="1.25s" repeatCount="indefinite"/><animate attributeName="y" values="45;85;65;30;45" dur="1.25s" repeatCount="indefinite"/></rect></g><text x="230" y="80" fill="#a6adc8" font-size="12">… 32 bars, gradient by frequency</text></svg></div>

**What it is.** Real-time bars that dance to whatever's playing, using `cava`. Colors run from mauve (bass) to teal (treble).

**Kind:** desktop widget · **Needs:** `cava`

@include galleryshell/desktop/Visualizer.qml

::: walk
@ 7-14 | Full-width bottom window
A 160 px tall, click-through strip along the bottom of the screen, under windows.
@ 16-18 | State
`bars` is the number of bars, `values` the current levels (0–100), and `playing` whether any player is playing.
@ 21-27 | Running cava
cava is a terminal audio visualizer that can print raw numbers. The shell script writes a small config to the runtime directory (raw ASCII output, values 0–100, separated by `;` which is character 59), then `exec`s cava with it. The process only runs while music plays. [[SplitParser]] receives one line per frame (50 per second) and splits it into numbers. When the process stops, the bars reset to zero.
@ 30-45 | The bars
A `Repeater` creates the bars; each reads its value by index (`?? 0` before data arrives). Heights scale to 140 px with a 4 px minimum, so silent bars stay visible as dots. The color shifts hue across the bars (`Qt.hsla` with a hue that decreases from mauve toward teal), giving a gradient without any gradient object. A 60 ms `Behavior` smooths between frames.
:::

**Customize**
- Mirror the bars (center outward), or draw a curved line with Canvas.
- Lighter option without cava: a single level meter from [[PwNodePeakMonitor]].

::: exercise practice | Mirrored
Make the bars grow from the vertical center in both directions (mirrored), like a waveform.
--- hint
Anchor each bar to `parent.verticalCenter` and use `y: -height / 2` relative positioning, or place two Repeaters (one flipped with `transform: Scale { yScale: -1 }`).
:::

## Spinning Vinyl Now Playing

<div class="preview"><svg width="380" height="170" viewBox="0 0 380 170"><g><animateTransform attributeName="transform" type="rotate" from="0 85 85" to="360 85 85" dur="6s" repeatCount="indefinite"/><circle cx="85" cy="85" r="65" fill="#11111b"/><g fill="none" stroke="#313244"><circle cx="85" cy="85" r="55"/><circle cx="85" cy="85" r="45"/><circle cx="85" cy="85" r="35"/></g><circle cx="85" cy="85" r="24" fill="#cba6f7"/><path d="M85 61a24 24 0 0 1 20 12" stroke="#f5c2e7" stroke-width="6" fill="none"/><circle cx="85" cy="85" r="4" fill="#11111b"/></g><text x="170" y="74" fill="#cdd6f4" font-size="17" font-weight="800">Midnight City</text><text x="170" y="96" fill="#a6adc8" font-size="12">M83 · Hurry Up, We're Dreaming</text><rect x="170" y="112" width="180" height="4" rx="2" fill="#313244"/><rect x="170" y="112" width="80" height="4" rx="2" fill="#cba6f7"><animate attributeName="width" values="20;180" dur="20s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** A desktop "record player": album art as the label of a spinning vinyl that stops when paused, with title, artist and progress.

**Kind:** desktop widget (clickable) · **Needs:** MPRIS

@include galleryshell/desktop/Vinyl.qml

::: walk
@ 10-17 | Player and window
Hidden when there's no player.
@ 19 | Live progress
Asks the player to refresh `position` every second while playing.
@ 26-35 | The record and grooves
A black circle with four concentric transparent circles whose thin borders look like grooves.
@ 36-42 | Label = album art
Round album art in the center, and a small dark spindle hole on top.
@ 43-46 | Spinning on the render thread
`RotationAnimator` (an *Animator*, not an Animation) runs on Qt's render thread, so it stays perfectly smooth even if the shell is busy. It runs only while playing.
@ 48 | Click the record
Toggles play/pause.
@ 50-58 | Text and progress
Title in a heavy font, "artist · album", and a thin progress bar.
:::

::: exercise practice | Tonearm
Add a tonearm (a rotated rectangle at the top-right of the record) that rotates onto the record when playing and away when paused.
:::

## Sticky Note

<div class="preview"><svg width="240" height="200" viewBox="0 0 240 200"><g transform="rotate(-3 120 100)"><rect x="40" y="20" width="160" height="160" rx="6" fill="#f9e2af"/><rect x="40" y="20" width="160" height="22" rx="6" fill="#f5d48a"/><g fill="#45475a" font-size="13"><text x="54" y="66">☐ rice the lock screen</text><text x="54" y="90">☑ dynamic island</text><text x="54" y="114">☐ buy coffee</text></g></g></svg></div>

**What it is.** An editable sticky note on the desktop whose text is saved to a file automatically.

**Kind:** desktop widget (editable) · **Needs:** nothing extra

@include galleryshell/desktop/StickyNote.qml

::: walk
@ 6-14 | Clickable desktop window
Unlike other desktop widgets, the note has no empty mask: it needs clicks. `OnDemand` keyboard focus means it only takes the keyboard when you click into it, so it doesn't steal typing from your apps.
@ 16-21 | Loading
The text is stored in the shell's state directory. When the file loads, it's copied into the editor (only if different, to avoid moving the cursor).
@ 22 | Saving (debounced)
Every keystroke restarts a 600 ms timer; the file is written only when you pause. `setText()` writes the whole file.
@ 24-28 | Paper look
A yellow card rotated −2° (slightly crooked, like a real note) with a darker strip at the top.
@ 29-37 | Editing
`TextEdit` is a multi-line text editor. A placeholder appears only when empty and not focused.
:::

::: exercise practice | Color picker
Right-click the note to cycle through yellow, pink and green paper colors, and remember the choice.
:::
