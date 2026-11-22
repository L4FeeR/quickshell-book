# Running Commands with Process

Quickshell has native services for audio, battery, media and more, but there will always be something without one: CPU temperature, a weather API, `brightnessctl`, a script you wrote. [[Process]] runs any program **asynchronously** (your UI never freezes) and gives you its output.

## Your first Process

```qml
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property string kernel: "…"

    Process {
        command: ["uname", "-r"]               // program + arguments, as a LIST
        running: true                          // start immediately
        stdout: StdioCollector {
            onStreamFinished: root.kernel = this.text.trim()   // all output, once the program ends
        }
    }
}
```

1. `command` is an **argv list**: the program name, then each argument as its own string. No quoting headaches.
2. Setting `running: true` starts it. When the program exits, `running` becomes `false` on its own.
3. `stdout: StdioCollector { … }` collects everything the program prints; `onStreamFinished` fires when it's done.

> [!WARN] Always .trim()
> Command output usually ends with a newline. `"6.12.1\n"` displays oddly and fails comparisons. Call `.trim()`.

## Shell features need a shell

`command` runs a program **directly**, not through bash. Pipes (`|`), redirects (`>`), `&&`, globs (`*`) and `$VARIABLES` are terminal-shell features, so wrap them in `sh -c`:

```qml
Process {
    command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity | head -1"]
    running: true
    stdout: StdioCollector { onStreamFinished: console.log("battery:", text.trim()) }
}
```

When you need to insert a value into a shell command, pass it as an **argument** instead of pasting it into the string, which avoids quoting bugs and injection:

```qml
// ✗ breaks on names with spaces or quotes
command: ["sh", "-c", "notify-send '" + title + "'"]
// ✓ $1 is the next argument, passed safely
command: ["sh", "-c", 'notify-send "$1"', "sh", title]
// ✓✓ best: no shell needed at all
command: ["notify-send", title]
```

## Re-running: polling

A Process runs once each time `running` becomes true. To refresh periodically, pair it with a Timer:

```qml
Scope {
    id: root
    property int temp: 0

    Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector { onStreamFinished: root.temp = Math.round(parseInt(text) / 1000) }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: tempProc.running = true
    }
}
```

> [!TIP] Prefer FileView for files
> Reading `/sys` or `/proc` files doesn't need a process at all. [[FileView]] reads the file directly, with no fork and exec ([[ch:38-files-json]]). Use Process for real programs.

## Streaming output: SplitParser

Some commands run forever and print events: `nmcli monitor`, `pactl subscribe`, `niri msg -j event-stream`, `cava`, `inotifywait -m`. Use [[SplitParser]] to get each line as it arrives:

```qml
Process {
    command: ["nmcli", "monitor"]
    running: true                              // keeps running
    stdout: SplitParser {
        splitMarker: "\n"                      // default; any string works
        onRead: line => {
            console.log("network event:", line)
            if (line.includes("connected")) refreshWifi()
        }
    }
}
```

| Parser | Gives you | Use for |
|---|---|---|
| [[StdioCollector]] | `text` (and `data`) when the stream ends; `onStreamFinished` | one-shot commands |
| [[SplitParser]] | `onRead(chunk)` per delimiter | long-running event streams |

`StdioCollector.waitForEnd: false` updates `text` continuously instead of only at the end.

## Handling errors and exit codes

```qml
Process {
    id: proc
    command: ["brightnessctl", "set", "50%"]
    stdout: StdioCollector { id: out }
    stderr: StdioCollector { id: err }
    onStarted: console.log("started, pid", processId)
    onExited: (exitCode, exitStatus) => {
        if (exitCode !== 0) console.warn("brightnessctl failed:", err.text)
    }
}
```

If a program doesn't exist, it fails to start and `exited` reports a non-zero code. Check `which <program>` in a terminal first.

## Sending input: stdin

```qml
Process {
    id: calc
    command: ["bc", "-l"]
    stdinEnabled: true
    running: true
    stdout: SplitParser { onRead: result => console.log("=", result) }
}
// later: calc.write("2^10\n")
```

## Other Process members

| Member | Meaning |
|---|---|
| `command` | argv list |
| `running` | start (true) / kill (false); turns false on exit |
| `processId` | PID while running, else null |
| `workingDirectory` | directory to run in |
| `environment` | extra env vars: `({ LANG: "C", FOO: null })` (null removes a variable) |
| `clearEnvironment` | start with an empty environment |
| `stdout`, `stderr` | parsers |
| `stdinEnabled`, `write(data)` | stdin |
| `signal(sig)` | send a Unix signal (`signal(15)` = SIGTERM) |
| `startDetached()` | launch a copy that outlives Quickshell |
| `exec(command)` | stop the current run and start a new command in one call |
| `onStarted`, `onExited(code, status)` | signals |

> [!TIP] Force English output
> When parsing command output, set `environment: ({ LANG: "C", LC_ALL: "C" })` so a German or Hindi locale doesn't change the text you're matching.

## Fire and forget: Quickshell.execDetached

To launch something without caring about its output (open an app, run a script, send a notification), use [[Quickshell.execDetached()]]:

```qml
TapHandler { onTapped: Quickshell.execDetached(["kitty"]) }
TapHandler { onTapped: Quickshell.execDetached(["sh", "-c", "grim -g \"$(slurp)\" - | wl-copy"]) }
```

The process is detached, so it keeps running if Quickshell reloads or quits.

## Launching apps properly

Apps started from Quickshell become children of the Quickshell process. Many rices launch apps **through the compositor** or a launcher helper so they get their own scope and environment:

```qml
Hyprland.dispatch("exec kitty")                          // Hyprland
Quickshell.execDetached(["uwsm", "app", "--", "kitty"])  // UWSM-managed sessions
Quickshell.execDetached(["app2unit", "--", "kitty"])     // systemd scopes
entry.execute()                                          // DesktopEntry's own launcher
```

## A complete example: CPU and RAM usage

```qml file="services/SystemUsage.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property real cpu: 0          // 0..1
    property real ram: 0          // 0..1
    property var _last: null

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: mem;  path: "/proc/meminfo" }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { stat.reload(); mem.reload(); root.update() }
    }

    function update(): void {
        // CPU: compare two samples of the first "cpu" line
        const p = (stat.text().split("\n")[0] || "").trim().split(/\s+/).slice(1).map(Number)
        if (p.length > 4) {
            const idle = p[3] + p[4], total = p.reduce((a, b) => a + b, 0)
            if (_last) {
                const dt = total - _last.total
                cpu = dt > 0 ? 1 - (idle - _last.idle) / dt : 0
            }
            _last = { total, idle }
        }
        // RAM
        const t = mem.text()
        const total = parseInt((t.match(/MemTotal:\s+(\d+)/) || [])[1] || 0)
        const avail = parseInt((t.match(/MemAvailable:\s+(\d+)/) || [])[1] || 0)
        ram = total ? 1 - avail / total : 0
    }
}
```

(This uses FileView for the reading. Same idea, no processes needed.)

## Practice

::: exercise warm | Kernel and uptime
Show your kernel version and uptime (`uptime -p`) in the bar.
--- solution
```qml
Process { running: true; command: ["sh", "-c", "uname -r; uptime -p"]
    stdout: StdioCollector { onStreamFinished: info.text = text.trim().replace("\n", " · ") } }
Text { id: info; color: "white" }
```
:::

::: exercise practice | Updates every 30 minutes
Show the number of available updates (`checkupdates | wc -l`), refreshed every 30 minutes.
--- solution
```qml
Process { id: upd; command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
    stdout: StdioCollector { onStreamFinished: count.text = text.trim() } }
Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: upd.running = true }
Text { id: count; color: "white" }
```
:::

::: exercise challenge | Stream lines
Run `nmcli monitor` with a `SplitParser` and log every line.
--- solution
```qml
Process { running: true; command: ["nmcli", "monitor"]
    stdout: SplitParser { onRead: line => console.log("nm:", line) } }
```
A long-running process keeps streaming; `SplitParser` calls `onRead` once per line.
:::
