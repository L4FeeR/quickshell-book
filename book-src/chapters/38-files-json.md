# Files, Watching and JSON Config

Your shell needs to read files (`/sys` brightness, generated colors), watch them for changes (a new wallpaper palette), and remember settings across restarts. [[FileView]] does all of this, and [[JsonAdapter]] turns a JSON file into live, two-way QML properties.

## Reading a file

```qml
import Quickshell.Io

FileView {
    id: hostname
    path: "/etc/hostname"
}

Text { text: hostname.text().trim() }
```

`text()` returns the content as a string. Although it's a function, bindings that call it update whenever the file is (re)loaded. `data()` returns the raw bytes.

## Watching for changes

```qml
FileView {
    id: colorsFile
    path: Quickshell.env("HOME") + "/.cache/myshell/colors.json"
    watchChanges: true                  // use inotify to detect changes on disk
    onFileChanged: reload()             // re-read when it changes
    onLoaded: console.log("colors loaded")
    onLoadFailed: error => console.warn("couldn't load colors:", FileViewError.toString(error))
}
```

This is the core of live theming: matugen writes `colors.json` and your shell instantly recolors ([[ch:44-theming]]).

> [!NOTE] /sys and /proc files
> Many `/sys` files (like `/proc/stat`) don't send change notifications. For those, call `reload()` on a Timer instead of relying on `watchChanges`. Backlight brightness files usually do notify.

## Paths

Paths must be absolute. Build them with:

```qml
path: Quickshell.env("HOME") + "/.config/myshell/config.json"
path: Quickshell.shellPath("assets/data.json")      // inside your config folder
path: Quickshell.statePath("history.json")          // ~/.local/state/quickshell/by-shell/<id>/
path: Quickshell.cachePath("thumbs/index.json")     // ~/.cache/quickshell/by-shell/<id>/
path: Quickshell.dataPath("notes.txt")              // ~/.local/share/quickshell/by-shell/<id>/
```

## Writing a file

```qml
FileView {
    id: notes
    path: Quickshell.dataPath("notes.txt")
    onSaved: console.log("saved")
    onSaveFailed: err => console.warn("save failed", FileViewError.toString(err))
}
// notes.setText("remember to rice")
```

Writes are **atomic** by default (`atomicWrites: true`): the file is written to a temp file, then swapped in, so a crash never leaves it half-written.

## Loading behavior

| Property | Meaning |
|---|---|
| `preload` (default true) | start loading as soon as `path` is set |
| `blockLoading` | if the file isn't loaded yet when you call `text()`, wait for it. Use it for config that must be ready at startup, so nothing flashes with default values. |
| `blockAllReads` | always block reads while a load is in progress |
| `blockWrites` | make `setText()` block until written |
| `printErrors` (default true) | log read and write errors |
| `loaded` | read-only: is a file currently loaded |

All members are on the [[FileView]] reference page.

## JsonAdapter: settings as properties

[[JsonAdapter]] maps a JSON file to properties. Declare properties with defaults and the adapter fills them from the file. Change a property in QML and (with one line) the file is rewritten.

```qml file="services/Config.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias bar: adapter.bar
    property alias appearance: adapter.appearance
    property alias terminal: adapter.terminal

    FileView {
        path: Quickshell.env("HOME") + "/.config/myshell/config.json"
        watchChanges: true
        onFileChanged: reload()                 // edited by hand → reload
        onAdapterUpdated: writeAdapter()        // changed from QML → save
        blockLoading: true                      // ready before the first frame
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter()   // first run: create with defaults
        }

        JsonAdapter {
            id: adapter

            property JsonObject bar: JsonObject {
                property bool bottom: false
                property int height: 36
                property list<string> screens: []
                property bool showSeconds: false
            }
            property JsonObject appearance: JsonObject {
                property string font: "Inter"
                property real transparency: 0.85
                property int rounding: 14
            }
            property string terminal: "kitty"
        }
    }
}
```

The JSON file it reads and writes:

```json file="~/.config/myshell/config.json"
{
  "bar": { "bottom": false, "height": 36, "screens": [], "showSeconds": false },
  "appearance": { "font": "Inter", "transparency": 0.85, "rounding": 14 },
  "terminal": "kitty"
}
```

Use it anywhere:

```qml
import qs.services

PanelWindow {
    anchors.top: !Config.bar.bottom
    anchors.bottom: Config.bar.bottom
    implicitHeight: Config.bar.height
}

Switch {
    checked: Config.bar.showSeconds
    onToggled: Config.bar.showSeconds = checked    // → adapterUpdated → writeAdapter() → saved
}
```

### How the pieces fit

| Piece | Role |
|---|---|
| `JsonAdapter { property … }` | each property is a top-level JSON key, with a default |
| `property JsonObject x: JsonObject { … }` | a nested JSON object |
| `onAdapterUpdated: writeAdapter()` | save on any change from QML |
| `watchChanges` + `onFileChanged: reload()` | pick up manual edits |
| missing keys | keep their defaults, so you can add options later safely |
| unknown keys in the file | ignored |

Supported property types: `bool`, `int`, `real`, `string`, `color`, `list<…>`, `var` (any JSON), and `JsonObject` for nesting.

> [!WILD] In the wild
> end-4's `Config.qml` is exactly this pattern with hundreds of options, and its settings app just binds controls to `Config.options.*`. Noctalia and DankMaterialShell do the same, which is why their settings GUIs and JSON files always agree.

## Persisting state (not settings)

For data that changes often (notification history, launcher frequency, last wallpaper), use a separate file in the **state** dir:

```qml
FileView {
    path: Quickshell.statePath("launcher.json")
    onAdapterUpdated: writeAdapter()
    JsonAdapter { id: launchCounts; property var counts: ({}) }   // { "firefox.desktop": 12, … }
}
// on launch:
// launchCounts.counts = Object.assign({}, launchCounts.counts, { [id]: (launchCounts.counts[id] ?? 0) + 1 })
```

Remember the `var` rule: assign a new object to trigger saving.

## Reading other formats

- **Plain text / key=value:** `text().split("\n")` and parse.
- **JSON without an adapter:** `JSON.parse(text())`.
- **INI/TOML:** parse lines with regex, or convert with a CLI tool via Process.

## Practice

::: exercise warm | Hostname
Show your hostname from `/etc/hostname`.
--- solution
```qml
FileView { id: host; path: "/etc/hostname"; blockLoading: true }
Text { text: host.text().trim(); color: "white" }
```
:::

::: exercise practice | Config with defaults
Write `Config.qml` with a `bar.height` option. Delete the JSON file and watch it get recreated with defaults.
--- solution
```qml
pragma Singleton
import Quickshell
import Quickshell.Io
Singleton {
    property alias bar: adapter.bar
    FileView { path: Quickshell.shellPath("config.json"); watchChanges: true
        onFileChanged: reload(); onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }
        JsonAdapter { id: adapter; property JsonObject bar: JsonObject { property int height: 38 } } } }
```
:::

::: exercise practice | Live editing
Edit `config.json` by hand while `qs` runs and watch the bar resize live.
--- why
`watchChanges: true` + `onFileChanged: reload()` re-reads the file on every save, and the adapter updates its properties, which updates every binding that uses them.
:::

::: exercise challenge | Save from the UI
Add a `Switch` that toggles `Config.bar.showSeconds` and check that the file updates.
--- solution
Add `property bool showSeconds: false` to the `bar` JsonObject, then:
```qml
Switch { checked: Config.bar.showSeconds; onToggled: Config.bar.showSeconds = checked }
```
`onAdapterUpdated: writeAdapter()` saves the change to disk.
:::
