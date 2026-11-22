# Timers, Dates and Time

Clocks, auto-hiding OSDs, polling a command, debouncing input, countdowns. This chapter covers `Timer`, Quickshell's [[SystemClock]] and [[ElapsedTimer]], and formatting dates.

## Timer

```qml
Timer {
    id: t
    interval: 1000            // milliseconds
    running: true             // start immediately (bindable)
    repeat: true              // false = fire once
    triggeredOnStart: false   // true = also fire immediately when started
    onTriggered: console.log("tick")
}
```

| Member | Meaning |
|---|---|
| `interval` | delay in ms |
| `running` | active? Set or bind it |
| `repeat` | repeat or one-shot |
| `triggeredOnStart` | fire once right away on start |
| `start()`, `stop()`, `restart()` | control |
| `onTriggered` | the signal |

### Patterns

**Auto-hide after inactivity** (OSDs, popups):
```qml
Timer { id: hideTimer; interval: 1500; onTriggered: osd.visible = false }
function poke() { osd.visible = true; hideTimer.restart() }     // every poke resets the countdown
```

**Polling** (re-run a command every N seconds):
```qml
Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: cpuProc.running = true }
```

**Poll only while visible** (saves power):
```qml
Timer { interval: 1000; repeat: true; running: dashboard.visible; onTriggered: refresh() }
```

**Debounce** (wait until typing pauses before an expensive search):
```qml
TextField { onTextChanged: debounce.restart() }
Timer { id: debounce; interval: 200; onTriggered: runSearch() }
```

**Delay once**, e.g. ignore startup events:
```qml
property bool armed: false
Timer { interval: 2000; running: true; onTriggered: root.armed = true }
```

## SystemClock: the right way to show time

A `Timer` with `interval: 1000` drifts and fires at arbitrary offsets, so a clock can visibly lag up to a second behind real minutes. [[SystemClock]] updates **exactly** on second, minute or hour boundaries, and only as often as you need:

```qml
import Quickshell

SystemClock {
    id: clock
    precision: SystemClock.Minutes      // Seconds | Minutes | Hours
}

Text { text: Qt.formatDateTime(clock.date, "hh:mm") }
```

It provides `date`, `hours`, `minutes`, `seconds` and `enabled` (set false to pause updates). See its reference page for every member.

> [!TIP] Battery-friendly clocks
> `precision: SystemClock.Minutes` wakes your shell 60 times less often than seconds precision. Use `Seconds` only if you actually display seconds, and switch dynamically: `precision: showSeconds ? SystemClock.Seconds : SystemClock.Minutes`.

## Formatting dates and times

`Qt.formatDateTime(date, format)`, `Qt.formatDate(date, format)`, `Qt.formatTime(date, format)`.

| Code | Meaning | Example |
|---|---|---|
| `h` / `hh` | hour (0–23 or 1–12 with AP) / zero-padded | `9` / `09` |
| `H` / `HH` | hour, always 24h | `21` |
| `m` / `mm` | minute | `5` / `05` |
| `s` / `ss` | second | `7` / `07` |
| `AP` / `ap` | AM/PM marker; makes `h` 12-hour | `PM` |
| `d` / `dd` | day of month | `1` / `01` |
| `ddd` / `dddd` | day name short / long | `Fri` / `Friday` |
| `M` / `MM` | month number | `3` / `03` |
| `MMM` / `MMMM` | month name short / long | `Nov` / `November` |
| `yy` / `yyyy` | year | `26` / `2026` |
| `'text'` | literal text in quotes | `'Week'` |

```qml
Qt.formatDateTime(clock.date, "ddd d MMM  hh:mm")     // Fri 21 Nov  14:05
Qt.formatDateTime(clock.date, "h:mm AP")             // 2:05 PM
Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")   // Friday, 21 November 2026
```

Names follow the system locale. For a specific locale: `clock.date.toLocaleString(Qt.locale("de_DE"), "dddd")`.

## Date arithmetic

```js
const d = new Date(clock.date)
const tomorrow = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1)
const daysInMonth = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
const firstWeekday = new Date(d.getFullYear(), d.getMonth(), 1).getDay()   // 0 = Sunday
const mondayFirst = (firstWeekday + 6) % 7
const diffMs = target - d                       // subtract dates → milliseconds
const minutesLeft = Math.ceil(diffMs / 60000)
```

These are the building blocks of the calendar popup in [[ch:49-proj-clock-calendar]].

## Durations ("1:23:45", "3 min left")

```qml
function fmtDuration(totalSec: int): string {
    const h = Math.floor(totalSec / 3600)
    const m = Math.floor((totalSec % 3600) / 60)
    const s = totalSec % 60
    const pad = n => String(n).padStart(2, "0")
    return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`
}
```

Used for media position and length (MPRIS gives seconds) and battery time-to-empty.

## ElapsedTimer: measuring time

[[ElapsedTimer]] measures time precisely, without the overhead of `Date`:

```qml
ElapsedTimer { id: stopwatch }
// stopwatch.restart() → later: stopwatch.elapsed() (seconds), elapsedMs(), elapsedNs()
```

Useful for stopwatches, "pressed for how long", or measuring how long a command took.

## A countdown / pomodoro widget

```qml
Item {
    id: pomo
    property int remaining: 25 * 60
    property bool running: false

    Timer {
        interval: 1000; repeat: true; running: pomo.running && pomo.remaining > 0
        onTriggered: {
            pomo.remaining--
            if (pomo.remaining === 0)
                Quickshell.execDetached(["notify-send", "Pomodoro", "Time for a break!"])
        }
    }
    Text {
        text: Math.floor(pomo.remaining / 60) + ":" + String(pomo.remaining % 60).padStart(2, "0")
        font.features: ({ "tnum": 1 })
        color: pomo.running ? "#a6e3a1" : "#cdd6f4"
        TapHandler { onTapped: pomo.running = !pomo.running }
        TapHandler { acceptedButtons: Qt.RightButton; onTapped: { pomo.running = false; pomo.remaining = 25 * 60 } }
    }
}
```

## Practice

::: exercise warm | SystemClock
Replace a Timer-based clock with `SystemClock` (minutes precision).
--- solution
```qml
SystemClock { id: clock; precision: SystemClock.Minutes }
Text { text: Qt.formatTime(clock.date, "hh:mm"); color: "white" }
```
:::

::: exercise practice | Greeting
Show "Good morning / afternoon / evening" based on `clock.hours`.
--- solution
```qml
Text { text: clock.hours < 12 ? "Good morning" : clock.hours < 18 ? "Good afternoon" : "Good evening" }
```
:::

::: exercise practice | Auto-hiding box
Make a box that appears for 1.5 s each time you click a button, restarting the countdown on every click.
--- solution
```qml
Rectangle { id: osd; visible: false; width: 120; height: 40; color: "#1e1e2e" }
Timer { id: hide; interval: 1500; onTriggered: osd.visible = false }
Rectangle { y: 60; width: 80; height: 30; color: "#313244"
    TapHandler { onTapped: { osd.visible = true; hide.restart() } } }
```
:::

::: exercise challenge | Countdown
Build a Pomodoro: click to start a 25-minute countdown shown as `mm:ss`; click again to pause.
--- solution
```qml
Text {
    id: pomo
    property int left: 25 * 60
    color: "white"; font.pixelSize: 24
    text: String(Math.floor(left / 60)).padStart(2, "0") + ":" + String(left % 60).padStart(2, "0")
    Timer { id: tick; interval: 1000; repeat: true; onTriggered: if (--pomo.left <= 0) { stop(); pomo.left = 25 * 60 } }
    TapHandler { onTapped: tick.running = !tick.running }
}
```
:::
