# Settings App 5: Managing the Rice, and Testing It

Single settings are only half the job. People also want to **save a whole look and switch to another**, keep a **backup**, and **start over** when they've broken something. This chapter builds the `Profiles` service behind the last page, then shows how to **test a settings app without running the shell**, a technique that found three real bugs in this one.

```text
services/Profiles.qml
extras/defaults.json
modules/settings/pages/ProfilesPage.qml   (from the previous chapter)
```

## Module 1: The profiles service

A **profile** is one JSON file in `~/.config/cae/profiles/` holding the complete `shell.json` plus the wallpaper:

```json
{
  "config": { "border": { "thickness": 0, "rounding": 25 }, "appearance": { "font": "Inter", … }, … },
  "wallpaper": "/home/you/Pictures/Wallpapers/night-city.jpg",
  "saved": "2026-11-21T22:41:00.000Z"
}
```

Loading a profile writes its `config` into `shell.json` and applies its wallpaper. The shell is watching `shell.json`, so the whole rice changes in one step: frame, bar layout, fonts, motion and (through matugen) every colour.

@include cae/services/Profiles.qml

::: walk
@ 14-18 | Paths and state
Profiles live next to `shell.json`. `defaultsPath` points to `extras/defaults.json` inside the shell's own folder (`Quickshell.shellPath` resolves paths relative to the config root, in both the shell and the standalone app). `names` feeds the list on the page; `lastMessage` shows what just happened.
@ 24-27 | Writing files safely
One helper writes text to any path: `mkdir -p` the folder, then `printf "%s" "$2" > "$1"`. The path and the text are passed as **arguments**, never pasted into the shell command, so a profile name with spaces or a config containing quotes, `$` or backticks can't break the command or run anything.
@ 29-37 | Saving
The name is cleaned to letters, digits, `.`, `_` and `-` (so it can't contain `/` and escape the folder). The current `shell.json` is re-read from disk (`blockLoading: true` makes `text()` return the fresh content immediately), wrapped with the wallpaper and a timestamp, and written. The list refreshes a moment later.
@ 39-43 | Loading
A `Process` reads the profile file; its handler (below) applies it.
@ 45-49 | Deleting
Removes the file and refreshes the list.
@ 51-55 | Exporting
A plain copy of `shell.json` to a path of your choice, for backups or sharing.
@ 57-62 | Resetting
Writes the shipped defaults over `shell.json`. The defaults file uses `~/` for paths so it works for anyone; it's expanded to your home folder while writing, because the shell uses paths as-is.
@ 71-77 | Listing
`ls` the folder and strip `.json` with `sed`. The folder is again passed as an argument.
@ 79-94 | Applying a profile
Parse the file, write its config into `shell.json`, set its wallpaper. A broken or hand-edited file can't crash anything: the `try`/`catch` reports it instead.
:::

@include cae/extras/defaults.json

Keep this file in sync with the defaults in `Config.qml`. A full file (every key present) matters: writing a partial JSON would leave missing options at whatever value they had.

> [!NOTE] In the original
> Caelestia's colour schemes and wallpapers are managed by its `caelestia` CLI (`caelestia scheme list`, `caelestia scheme set`), and end-4's settings app has an "Advanced" page and first-run defaults copied from `defaults/config.json`. Neither ships named whole-rice profiles. This is an addition you can carry over to either.

## Module 2: Reloading the shell

The "Reload the shell" button calls an IPC handler added to `shell.qml`:

```qml
IpcHandler {
    target: "shell"
    function reload(): void { Quickshell.reload(true) }
}
```

`Quickshell.reload(true)` rebuilds every component from scratch (a "hard" reload). Most settings never need it, because they apply through bindings, but it helps after editing QML files.

## Module 3: Testing a settings app without the shell

A settings app has a lot of UI and very little that needs a running compositor. You can render it **headlessly** with Qt's own `qml` tool and catch layout and loading bugs before you ever start the shell.

The obstacle: Quickshell's types (`Singleton`, `FileView`, `FloatingWindow`…) only exist inside Quickshell. The trick is to give the pages **stand-ins** for the few singletons they use:

| Real | Stand-in |
|---|---|
| `Config` (a `JsonAdapter` on a file) | a `QtObject` with the same nested properties and default values |
| `Colours` | a `QtObject` with the palette |
| `Wallpapers`, `Profiles` | `QtObject`s with empty lists and functions that do nothing |
| `FloatingWindow` | a `Rectangle` of the same size |

Everything else (the rows, controls, sections, pages, even `Border` and `PanelBg`) runs **unchanged**. A small script copies the files into a temporary `qs/` folder, strips the `import Quickshell…` lines, swaps in the stand-ins, and writes `qmldir` files (marking `pragma Singleton` files as singletons). Then a test file renders each page to a PNG:

```qml
import QtQuick
import QtQuick.Window
import qs.modules.settings

Window {
    width: 1000; height: 700; visible: true
    SettingsWindow { id: win }

    Timer {
        interval: 800; running: true
        onTriggered: {
            SettingsState.page = 2;          // the Bar page
            SettingsState.query = "";
            grab.restart();
        }
    }
    Timer {
        id: grab
        interval: 400
        onTriggered: win.grabToImage(r => { r.saveToFile("bar-page.png"); Qt.quit(); })
    }
}
```

Run it without a display:

```bash
QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qml -I /tmp/mock test.qml
```

- `QT_QPA_PLATFORM=offscreen` renders without a screen.
- `QT_FORCE_STDERR_LOGGING=1` matters on many desktops: without it, Qt sends warnings and `console.log` output to the system journal, and the tool seems to fail silently ("Did not load any objects").
- `-I /tmp/mock` is where the `qs/` stand-in tree lives.

Testing this settings app that way found three real bugs, all fixed in the code you've read:

1. **A `Behavior` on a read-only property.** The switch knob's size was `readonly property real size`, and `Behavior on size` can't animate a read-only property; the whole page failed to load. It's now a normal property.
2. **A missing import.** `SliderRow` used `Slider.SnapAlways` without `import QtQuick.Controls`, a runtime `ReferenceError` that lint didn't flag.
3. **A layout that ate the window.** The navigation column filled the width (its children did), squeezing the pages to a sliver; [[ch:set3-window]] explains the fix.

Combine this with `qmllint` (`/usr/lib/qt6/bin/qmllint -I <folder with the qs tree> File.qml`) to catch typos and wrong property names, and the first real run in the shell is usually uneventful.

## Adapting the app to the end-4 rebuild

The same app works for `impulse` ([[ch:ii1-overview]]) with three changes:

1. Replace `Config.border.thickness`-style paths with `Config.options.bar.…` (ii's nested options).
2. Use `Appearance.colors.colLayer*` and `Appearance.rounding` in the rows and controls instead of `Colours.palette` and `Tokens` (or keep the components and give them ii's colours).
3. Open it the end-4 way: `Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])` from the right sidebar's settings button.

## Practice

::: exercise warm | Your first profiles
Save your current setup as "daily". Change the font, roundness and wallpaper a lot, save as "wild", and switch between them.
:::

::: exercise practice | Import a backup
Add an "Import settings" row with a path field that copies a file into `shell.json` (validate it with `JSON.parse` first).
--- hint
Read the file with a `Process` running `cat` (like `load()`), parse it in a `try`, and only call `writeFile(configPath, …)` when it parsed.
:::

::: exercise practice | Profile previews
Show each profile's wallpaper as a small thumbnail in its row (read it from the profile file when listing).
:::

::: exercise challenge | Undo
Keep the last 20 changes in a list (setting path, old value, new value) and add an Undo button that restores the previous value. Hint: the pages already funnel every change through `onEdited`; record it there.
:::

::: exercise project | A settings app for your own shell
Take the shell you built in Part R or your own config, and give it a settings app with at least three pages, search, reset buttons and profiles. Test it headlessly with stand-ins before running it.
:::
