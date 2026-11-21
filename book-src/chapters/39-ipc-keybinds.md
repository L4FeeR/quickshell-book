# IPC, Keybinds and Sockets

Press <kbd>Super</kbd>+<kbd>Space</kbd> and your launcher opens. Press <kbd>Super</kbd>+<kbd>L</kbd> and your lock screen appears. A script changes the wallpaper and your shell recolors. All of these need a way for the **outside world to talk to your shell**. Quickshell gives you three: [[IpcHandler]] (any compositor, any script), [[GlobalShortcut]] (Hyprland, lowest latency), and raw [[Socket]]s.

## IpcHandler

Declare functions on an `IpcHandler` with a `target` name, and they become callable from the terminal:

```qml file="services/GlobalStates.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool launcherOpen: false
    property bool locked: false

    IpcHandler {
        target: "shell"

        function toggleLauncher(): void { root.launcherOpen = !root.launcherOpen }
        function openLauncher(query: string): void { root.launcherOpen = true; root.launcherQuery = query }
        function lock(): void { root.locked = true }
        function isLocked(): bool { return root.locked }
        function setVolume(percent: int): void { Audio.setVolume(percent / 100) }
    }
    property string launcherQuery: ""
}
```

From any terminal, script or keybind:

```bash
qs ipc show                                   # list every target and function
qs ipc call shell toggleLauncher
qs ipc call shell openLauncher "fire"         # string argument
qs ipc call shell setVolume 40                # int argument
qs ipc call shell isLocked                    # prints: false
qs -c myshell ipc call shell lock             # pick the config if several run
```

### The rules

- Every parameter and the return value **must have a type annotation**, or the function isn't exposed.
- Allowed types: `string`, `int`, `bool`, `real`, `color`, and `void` for returns. At most 10 arguments.
- `target` must be unique within your shell.
- `enabled: false` temporarily disables a handler.

### IPC signals and properties

```qml
IpcHandler {
    target: "media"
    property string title: Media.active?.trackTitle ?? ""   // readable with: qs ipc prop get media title
    signal trackChanged(title: string)                      // observable with: qs ipc listen media trackChanged
}
```

```bash
qs ipc prop get media title
qs ipc listen media trackChanged      # prints each time the signal is emitted
qs ipc wait media trackChanged        # waits for one emission, then exits
```

These let external scripts react to your shell, e.g. a terminal widget that follows the current song.

## Binding keys to IPC

### Hyprland
```ini file="hyprland.conf"
bind = SUPER, Space, exec, qs -c myshell ipc call shell toggleLauncher
bind = SUPER, L,     exec, qs -c myshell ipc call shell lock
```

### Sway / i3
```ini file="~/.config/sway/config"
bindsym $mod+space exec qs -c myshell ipc call shell toggleLauncher
```

### niri
```text file="~/.config/niri/config.kdl"
binds {
    Mod+Space { spawn "qs" "-c" "myshell" "ipc" "call" "shell" "toggleLauncher"; }
}
```

### hypridle / swayidle
```ini file="hypridle.conf"
general {
    lock_cmd = qs -c myshell ipc call shell lock
}
```

## GlobalShortcut (Hyprland)

On Hyprland, [[GlobalShortcut]] registers a shortcut through Hyprland's global-shortcuts protocol. Pressing the key notifies your shell directly, with no process spawned, so latency is lower. You also get **press and release** events, which is great for "hold to show" cheatsheets and overview-on-Super.

```qml
import Quickshell.Hyprland

GlobalShortcut {
    name: "launcher"                         // registers as quickshell:launcher
    description: "Toggle the app launcher"   // shown in `hyprctl globalshortcuts`
    onPressed: GlobalStates.launcherOpen = !GlobalStates.launcherOpen
}

GlobalShortcut {
    name: "cheatsheet"
    onPressed: GlobalStates.cheatsheetOpen = true     // show while held…
    onReleased: GlobalStates.cheatsheetOpen = false   // …hide on release
}
```

```ini file="hyprland.conf"
bind  = SUPER, Space,    global, quickshell:launcher
bind  = SUPER, slash,    global, quickshell:cheatsheet
bindr = SUPER, SUPER_L,  global, quickshell:overview      # fires on RELEASE of Super alone
```

| Member | Meaning |
|---|---|
| `name` | shortcut name (can't change at runtime) |
| `appid` | prefix, defaults to `quickshell` → `quickshell:name` |
| `description` | human description |
| `pressed` (property) | currently held? |
| `onPressed`, `onReleased` | signals |

> [!WARN] Unique names
> Two Quickshell instances (or XDPH) registering the same `appid:name` will collide, and the later one may crash. Use a custom `appid` if you run more than one shell config.

### IpcHandler or GlobalShortcut?
| | IpcHandler | GlobalShortcut |
|---|---|---|
| Compositors | all | Hyprland only |
| Latency | spawns `qs` (~tens of ms) | direct, instant |
| Release events | no | yes |
| Callable from scripts | yes | no |
| Arguments and return values | yes | no |

Many shells use **both**: GlobalShortcut for keys on Hyprland, IpcHandler for scripts and other compositors.

## Sockets

[[Socket]] connects to a Unix socket, and [[SocketServer]] creates one. You'll rarely need them because compositor modules handle their sockets for you, but they're useful for custom daemons:

```qml
// Talk to a daemon's socket
Socket {
    id: sock
    path: "/run/user/1000/mydaemon.sock"
    connected: true
    parser: SplitParser { onRead: line => console.log("daemon says", line) }
    onError: e => console.warn("socket error", e)
}
// sock.write("status\n"); sock.flush()

// Offer your own socket
SocketServer {
    active: true
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/myshell.sock"
    handler: Socket {
        parser: SplitParser {
            onRead: cmd => { if (cmd === "toggle") GlobalStates.launcherOpen = !GlobalStates.launcherOpen }
        }
    }
}
```

```bash
echo toggle | socat - UNIX-CONNECT:$XDG_RUNTIME_DIR/myshell.sock
```

## Talking the other way: shell → compositor

To *control* the compositor from your shell:

```qml
Hyprland.dispatch("workspace 3")               // Hyprland dispatchers
I3.dispatch("workspace number 3")              // Sway/i3 commands
Niri.dispatch(["focus-workspace", "3"])        // niri (noctalia-qs fork module)
Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", "20"])   // anything hyprctl can do
```

> [!WILD] In the wild
> Caelestia's `caelestia` CLI is a wrapper around `qs ipc call`: `caelestia shell drawers toggle launcher` and similar. JaKooLit-style setups bind keys to `qs ipc call` so Quickshell components coexist with Waybar and rofi.

> [!TRY] Exercises
> 1. Add an IpcHandler `bar` with `toggle(): void` that hides or shows your bar, bound to <kbd>Super</kbd>+<kbd>B</kbd>.
> 2. Add `setTheme(name: string): void` and call it from the terminal.
> 3. On Hyprland, make a GlobalShortcut that shows a cheatsheet only while the key is held.
