=== Process
@@@ intro
Runs an external program **asynchronously** and gives you its output. It's the way to use any command-line tool from your shell: `brightnessctl`, `nmcli`, `curl`, your own scripts.

@@@ example Example: every property, function and signal
```qml
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property string out: ""

    Process {
        id: proc
        command: ["sh", "-c", "echo hello $NAME; echo oops >&2; read line; echo got $line"]
        workingDirectory: Quickshell.env("HOME")           // cwd
        environment: ({ NAME: "rice", LANG: "C" })          // extra vars (null value = unset)
        clearEnvironment: false                             // true = start from an empty env
        stdinEnabled: true                                  // allow write()
        running: false                                      // true starts it

        stdout: SplitParser { onRead: line => console.log("stdout:", line) }
        stderr: StdioCollector { onStreamFinished: console.warn("stderr:", text) }

        onStarted: { console.log("pid", processId); write("from-qml\n") }
        onExited: (code, status) => console.log("exit code", code, "status", status)
    }

    Timer {
        interval: 1000; running: true
        onTriggered: proc.running = true                    // start
    }
    // other functions:
    //   proc.signal(15)                 send SIGTERM (or any signal number)
    //   proc.startDetached()            run a copy that outlives Quickshell
    //   proc.exec(["ls", "-la"])        stop current run and start this command now
    //   proc.running = false            kill it
}
```

@@@ member command
A list: program first, then each argument. It isn't run through a shell, so no quoting is needed, but pipes and `$VARS` need `["sh", "-c", "…"]`.

@@@ member running
Becomes `false` when the program exits. To run the same command again, set it to `true` again (for example from a Timer).

@@@ member exec
Accepts a command list (or a context object with `command`, `environment`, `workingDirectory`…). Stops any current run first.

@@@ notes
- Wrap output in `.trim()`.
- Set `environment: ({ LC_ALL: "C" })` when parsing output, so other languages don't change it.
- For files in `/proc` or `/sys`, use [[FileView]] instead; it's much cheaper.

@@@ see
[[ch:37-processes]] · [[StdioCollector]] · [[SplitParser]] · [[Quickshell.execDetached()]]

=== StdioCollector
@@@ intro
Collects **all** output of a stream (a process's stdout/stderr, or a socket) into `text`. Fires `streamFinished` when the stream closes. Best for commands that run, print and exit.

@@@ example Example
```qml
Process {
    command: ["uname", "-a"]
    running: true
    stdout: StdioCollector {
        id: col
        waitForEnd: true                          // default: only update text at the end
        onStreamFinished: console.log(col.text.trim())   // `data` holds the raw bytes
    }
}
```

@@@ member waitForEnd
Set `false` to update `text` continuously while data arrives (e.g. to show progress).

=== SplitParser
@@@ intro
Splits a stream into chunks at a delimiter (default newline) and emits `read(chunk)` for each. Best for long-running commands that print events line by line.

@@@ example Example
```qml
Process {
    command: ["sh", "-c", "for i in 1 2 3; do echo tick $i; sleep 1; done"]
    running: true
    stdout: SplitParser {
        splitMarker: "\n"                 // any string; "" = emit whatever arrives
        onRead: chunk => console.log("got:", chunk)
    }
}
```

=== DataStreamParser
@@@ intro
The base type of [[SplitParser]] and [[StdioCollector]]. It defines the `read(data)` signal. You use the subtypes; the base appears as the type of `stdout`, `stderr` and `Socket.parser`.

=== DataStream
@@@ intro
The base type of streams that feed a parser, such as [[Socket]]. Its `parser` property takes a [[SplitParser]] or [[StdioCollector]].

=== Socket
@@@ intro
A **Unix socket client**. Connect to a daemon's socket, read with a parser, write with `write()` + `flush()`.

@@@ example Example: every member
```qml
import Quickshell
import Quickshell.Io
import QtQuick

Socket {
    id: sock
    path: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/.socket2.sock`
    connected: true                                   // connect now (set false to disconnect)
    parser: SplitParser { onRead: line => console.log("event:", line) }
    onConnectedChanged: console.log("connected:", connected)
    onError: e => console.warn("socket error:", e)
    // sock.write("some command\n"); sock.flush()
}
```

@@@ notes
Changing `path` while connected has no effect until you reconnect.

=== SocketServer
@@@ intro
Creates a **Unix socket server**. Each client connection creates a [[Socket]] from the `handler` component.

@@@ example Example
```qml
SocketServer {
    active: true
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/myshell.sock"
    handler: Socket {
        parser: SplitParser {
            onRead: cmd => {
                if (cmd === "toggle") GlobalStates.launcherOpen = !GlobalStates.launcherOpen
            }
        }
    }
}
```
```bash
echo toggle | socat - UNIX-CONNECT:$XDG_RUNTIME_DIR/myshell.sock
```

=== FileView
@@@ intro
Reads, watches and writes a file. Reading is cheap (no process), and with `watchChanges` you're notified the moment another program edits the file. With an `adapter` ([[JsonAdapter]]) the file's contents become QML properties.

@@@ example Example: every property, function and signal
```qml
import Quickshell
import Quickshell.Io
import QtQuick

Column {
    FileView {
        id: fv
        path: Quickshell.statePath("demo.txt")    // "" unloads
        preload: true                             // load as soon as path is set (default)
        blockLoading: false                       // true: text() waits for the first load
        blockAllReads: false                      // true: every read waits for loads
        blockWrites: false                        // true: setText() blocks until written
        atomicWrites: true                        // write to temp file then swap (default)
        printErrors: false                        // don't log missing-file errors
        watchChanges: true                        // emit fileChanged on external edits

        onLoaded: console.log("loaded:", text())
        onLoadFailed: err => {
            console.log("load failed:", FileViewError.toString(err))
            if (err === FileViewError.FileNotFound) setText("created at " + new Date())
        }
        onSaved: console.log("saved")
        onSaveFailed: err => console.warn("save failed:", FileViewError.toString(err))
        onFileChanged: reload()                   // re-read after external change
    }

    Text { text: fv.loaded ? fv.text() : "(not loaded)" }    // text() is bindable
    Text { text: "[append]"; TapHandler { onTapped: fv.setText(fv.text() + "\nmore") } }
    // fv.data()        raw bytes (ArrayBuffer)
    // fv.setData(buf)  write raw bytes
    // fv.waitForJob()  block until the current load finishes
}
```

@@@ member text
Although it's a function, you can use it in bindings like a property: they update after each load.

@@@ member blockLoading
Useful for config files read at startup, so nothing flashes with default values. Don't use it for big files.

@@@ member watchChanges
Uses inotify. Some `/proc` and `/sys` files never notify; for those call `reload()` on a Timer.

@@@ see
[[ch:38-files-json]] · [[JsonAdapter]] · [[FileViewError]]

=== FileViewAdapter
@@@ intro
The base type of adapters you put in [[FileView.adapter]]. Quickshell's adapter is [[JsonAdapter]]. Its `adapterUpdated` signal is forwarded to the FileView's `adapterUpdated`, which you connect to `writeAdapter()`.

=== JsonAdapter
@@@ intro
Turns a **JSON file into live properties**, both ways. Declare properties (with defaults) inside a `JsonAdapter` placed in a [[FileView]]: values load from the file, and changes you make in QML can be written back.

@@@ example Example: a complete config
```qml file="services/Config.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    property alias options: adapter

    FileView {
        path: Quickshell.env("HOME") + "/.config/myshell/config.json"
        watchChanges: true
        onFileChanged: reload()                  // manual edits → reload
        onAdapterUpdated: writeAdapter()         // QML edits → save
        blockLoading: true
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }  // create with defaults

        JsonAdapter {
            id: adapter
            property string terminal: "kitty"              // "terminal": "kitty"
            property bool darkMode: true
            property real opacity: 0.85
            property color accent: "#cba6f7"
            property list<string> pinnedApps: ["firefox", "kitty"]
            property var extra: ({})                       // any JSON value
            property JsonObject bar: JsonObject {          // nested object
                property int height: 36
                property bool bottom: false
            }
        }
    }
}
```
```qml
Text { text: Config.options.terminal }
Switch { checked: Config.options.bar.bottom; onToggled: Config.options.bar.bottom = checked }   // saved automatically
```

@@@ notes
- Missing keys keep their defaults; unknown keys in the file are ignored.
- For `var`/`list` properties, assign a new value to trigger saving (`x = [...x, item]`).

@@@ see
[[ch:38-files-json]] · [[JsonObject]]

=== JsonObject
@@@ intro
A nested JSON object inside a [[JsonAdapter]]. Declare it as a typed property and put properties inside; it maps to `{ … }` in the file.

@@@ example Example
```qml
JsonAdapter {
    property JsonObject appearance: JsonObject {
        property string font: "Inter"
        property JsonObject animation: JsonObject {       // nesting can go deeper
            property int duration: 250
        }
    }
}
// JSON: { "appearance": { "font": "Inter", "animation": { "duration": 250 } } }
```

=== IpcHandler
@@@ intro
Exposes **functions, properties and signals** to the outside world via `qs ipc`. That's how keybinds, scripts and other programs control your shell on any compositor.

@@@ example Example: functions, property and signal
```qml
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property real volume: 0.5

    IpcHandler {
        id: ipc
        target: "audio"                          // unique name: qs ipc call audio …
        enabled: true

        property real level: root.volume         // qs ipc prop get audio level
        signal levelChanged2(value: real)        // qs ipc listen audio levelChanged2

        function get(): real { return root.volume }
        function set(v: real): void { root.volume = Math.max(0, Math.min(1, v)); levelChanged2(root.volume) }
        function up(step: int): void { set(root.volume + step / 100) }
        function mute(on: bool): void { console.log("mute", on) }
        function tint(c: color): color { return Qt.darker(c, 1.2) }
        function name(): string { return "speakers" }
    }
}
```
```bash
qs ipc show
qs ipc call audio set 0.3
qs ipc call audio up 5
qs ipc call audio mute true
qs ipc call audio get              # → 0.3
qs ipc call audio tint "#ff8800"   # → #ffd46d00
qs ipc prop get audio level
qs ipc listen audio levelChanged2
```

@@@ notes
- Every parameter and the return type **must** be annotated (`string`, `int`, `bool`, `real`, `color`, `void`), or the function isn't exposed.
- Up to 10 arguments. Signals may have zero or one argument.

@@@ see
[[ch:39-ipc-keybinds]] · [[GlobalShortcut]]
