# Shell Structure, Pragmas and Reloading

From here on we use Quickshell's own types. This chapter covers how a config is organized at the top level: the root object, the special `//@ pragma` lines, and what happens when Quickshell reloads.

## The entry point: shell.qml

Quickshell loads `shell.qml` from your config folder. Its root object can be:

- a **window** (fine for a single bar, as in [[ch:04-first-shell]]),
- a [[Scope]]: a non-visual container for many windows and objects,
- a [[ShellRoot]]: like Scope, plus an inline `settings` group.

Real configs use `ShellRoot` or `Scope`:

```qml file="shell.qml"
import Quickshell
import QtQuick

ShellRoot {
    Bar {}                 // Bar.qml, a Scope with one PanelWindow per screen
    Notifications {}       // Notifications.qml
    Launcher {}            // Launcher.qml
}
```

Each child is usually its own file. `shell.qml` stays short: it's the table of contents of your shell.

## Scope: grouping non-visual things

Windows aren't Items, so they can't be children of a `Rectangle` or `Item`. A [[Scope]] is the container for anything that isn't drawn inside another window: windows, services, timers, IPC handlers, [[Variants]].

```qml file="Bar.qml"
import Quickshell
import QtQuick

Scope {
    // several windows can live in one Scope
    PanelWindow { anchors { top: true; left: true; right: true } implicitHeight: 32 }
    PanelWindow { anchors { bottom: true; left: true; right: true } implicitHeight: 24 }
    Timer { /* … */ }
}
```

Scopes also take part in **reloading**: when your config reloads, Quickshell matches old and new objects inside scopes to reuse windows and avoid flicker.

## ShellRoot and settings

[[ShellRoot]] exposes [[QuickshellSettings]] through `settings`:

```qml
ShellRoot {
    settings.watchFiles: true            // reload on file save (default true)
    settings.workingDirectory: Quickshell.env("HOME")
}
```

The same options are available at runtime on the [[Quickshell]] singleton: `Quickshell.watchFiles`, `Quickshell.workingDirectory`.

## Pragmas

Lines starting with `//@ pragma` at the **top of `shell.qml`** configure Quickshell **before** it loads anything:

```qml file="shell.qml"
//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma ShellId myshell
import Quickshell
```

| Pragma | Effect |
|---|---|
| `UseQApplication` | Run as a full `QApplication` instead of a `QGuiApplication`. Needed by some Qt Widgets-based features (some Controls styles, native platform menus in some setups). |
| `IconTheme <name>` | Icon theme for `Quickshell.iconPath()` and `image://icon/` |
| `Env NAME=value` | Set an environment variable for the Quickshell process (and child processes) |
| `ShellId <id>` | Stable shell ID, used for the data, state and cache dirs and to identify the instance |
| `AppId <id>` | Desktop application ID (default `org.quickshell`) |
| `DataDir <path>` / `StateDir <path>` / `CacheDir <path>` | Override [[Quickshell.dataDir]], [[Quickshell.stateDir]], [[Quickshell.cacheDir]] |
| `DefaultEnv NAME=value` | Like `Env`, but only if the variable isn't already set |
| `NativeTextRendering` | Use native (hinted) text rendering everywhere |
| `RespectSystemStyle` | Don't force Quickshell's default Qt Quick Controls style |
| `IgnoreSystemSettings` | Ignore desktop settings (system fonts, palette) when starting Qt |
| `DropExpensiveFonts` | Skip font types that are expensive to load (saves startup time and memory) |

Useful environment variables to set with `Env`:

| Variable | Meaning |
|---|---|
| `QS_NO_RELOAD_POPUP=1` | Don't show the "config reloaded" popup |
| `QT_QUICK_CONTROLS_STYLE=Basic` | Controls style that's easiest to restyle |
| `QT_QUICK_FLICKABLE_WHEEL_DECELERATION=…` | Tune scroll feel |
| `QT_SCALE_FACTOR=1` | Force a scale factor |

> [!NOTE] Pragmas only in shell.qml, above the imports
> Pragmas are read from the entry file before QML loads, and reading stops at the first `import` line. Put them at the very top. In other files they're just comments. An unknown pragma prints `Unrecognized pragma` in the log.

## Hot reloading in detail

When you save any file in your config folder:

1. Quickshell parses the whole config again.
2. If there's an error, it keeps the current version running and reports the error.
3. If parsing succeeds, it creates the new object tree, **matches** windows and reloadable objects from the old tree to reuse them, then destroys the old tree.

What survives a reload:

| Survives | Doesn't survive |
|---|---|
| Windows (reused when matched, so no flicker) | Plain property values (reset to defaults) |
| [[PersistentProperties]] values | JS variables, Timer progress |
| [[NotificationServer]] notifications (with `keepOnReload`) | Process state (processes restart) |
| Files you wrote with [[FileView]] | Animations in progress |

### Matching objects across reloads: reloadableId
Quickshell matches reloadable objects by position in the tree. If you reorder things, they may not match. Give important ones a stable [[Reloadable.reloadableId]]:

```qml
PersistentProperties {
    id: persist
    reloadableId: "sidebar-state"
    property bool open: false
    property int tab: 0
}
```

### Reacting to reloads
```qml
Connections {
    target: Quickshell
    function onReloadCompleted() { Quickshell.inhibitReloadPopup(); console.log("reloaded") }
    function onReloadFailed(error) { console.warn("reload failed:", error) }
}
```

Trigger a reload from code with `Quickshell.reload(false)` (soft: reuse windows) or `Quickshell.reload(true)` (hard: recreate everything).

## Version checks

Shells that others install may need to run on several Quickshell versions:

```qml
Component.onCompleted: {
    if (!Quickshell.hasVersion(0, 2)) console.warn("This shell needs Quickshell 0.2+")
}
```

[[Quickshell.hasVersion()]] and [[Quickshell.hasQtVersion()]] let you gate features.

## Multiple instances

You can run several configs at once (`qs -c bar` and `qs -c widgets`). Each is independent. Most people run one config that contains everything, which makes sharing state trivial. Some setups (like JaKooLit's) run small single-purpose configs alongside other tools.

> [!TRY] Exercises
> 1. Convert your playground `shell.qml` into a `ShellRoot` that contains a `Bar {}` from `Bar.qml`.
> 2. Add `//@ pragma IconTheme Papirus-Dark` and `//@ pragma Env QS_NO_RELOAD_POPUP=1`.
> 3. Add a `PersistentProperties` with a `property int counter`, increment it with a click, save the file, and see the counter survive the reload.
