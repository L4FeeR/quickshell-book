# Debugging

Every shell breaks sometimes. This chapter is your toolbox: reading errors, logging, inspecting state, and a big table of symptoms and fixes.

## Read the error properly

```text
WARN qml: file:///home/you/.config/quickshell/myshell/modules/bar/Clock.qml:42:9: TypeError: Cannot read property 'title' of null
```

| Part | Meaning |
|---|---|
| `WARN` / `ERROR` | severity |
| `file:///…/Clock.qml` | which file |
| `42:9` | line 42, column 9 |
| `TypeError: Cannot read property 'title' of null` | the actual problem: something before `.title` was null |

Fix: `foo?.title ?? ""`.

## Logging

```qml
console.log("volume:", Audio.volume)                         // INFO
console.warn("weird state", JSON.stringify(obj))             // WARN
console.error("failed")                                      // ERROR
console.log(JSON.stringify(Hyprland.focusedMonitor?.lastIpcObject, null, 2))
console.trace()                                              // call stack
console.time("search"); /* … */ console.timeEnd("search")   // timing
```

```bash
qs -c myshell                    # logs in the terminal
qs -c myshell -v                 # + Quickshell INFO internals
qs -c myshell -vv                # + DEBUG internals
qs -c myshell --log-times        # timestamps
qs log -c myshell -f             # follow the log of a daemonized instance
qs log -c myshell -t 100         # last 100 lines
qs -c myshell --log-rules "quickshell.service.pipewire*=true"   # enable one category
```

## Inspecting live state from outside

Add a debug IPC target:

```qml
IpcHandler {
    target: "debug"
    function eval(expr: string): string {
        try { return String(eval(expr)) } catch (e) { return "error: " + e }
    }
    function dump(): string { return JSON.stringify({ launcher: GlobalStates.launcherOpen, vol: Audio.volume }) }
}
```

```bash
qs ipc call debug dump
qs ipc call debug eval "Mpris.players.values.map(p => p.identity).join(', ')"
```

> [!WARN] Remove `eval` before sharing
> An eval IPC function lets anything running as your user execute code in your shell. Keep it for local debugging only.

## Visual debugging

```qml
// outline any item
Rectangle { anchors.fill: parent; color: "transparent"; border.color: "red"; border.width: 1; z: 999 }

// show an item's size
Text { text: parent.width.toFixed(0) + "×" + parent.height.toFixed(0); color: "red"; z: 999 }
```

Environment variables for Qt Quick:

```bash
QSG_VISUALIZE=overdraw qs -c myshell     # see overdraw
QSG_VISUALIZE=batches qs -c myshell      # see draw batches
QSG_RENDER_TIMING=1 qs -c myshell        # print frame render times
QT_QUICK_BACKEND=software qs -c myshell  # rule out GPU driver issues
```

## Symptom → fix table

| Symptom | Cause | Fix |
|---|---|---|
| `X is not a type` | missing import, wrong file name case, typo | add the import; files must be `Capitalized.qml` |
| `Cannot assign to non-existent property` | wrong property name or type | check the reference page |
| `ReferenceError: foo is not defined` | id from another file, or singleton not imported | pass as property; `import qs.services` |
| `TypeError: … of null/undefined` | object not ready, or nothing playing/connected | `?.` and `??` |
| `Binding loop detected` | size depends on itself | implicit sizes up, actual sizes down ([[ch:17-sizing]]) |
| Value stops updating | assignment destroyed a binding; or `var` mutated in place | bind to state; reassign arrays/objects |
| Window doesn't appear | zero size, `visible: false`, null `screen` | set `implicitWidth/Height` ≥ 1 |
| Window is white | `color` defaults to white | `color: "transparent"` |
| Typing doesn't reach my TextInput | layer window has no keyboard focus | `WlrLayershell.keyboardFocus` + `focus: true` |
| Can't click apps behind my overlay | window catches clicks | `mask: Region {}` or a precise mask |
| Volume always 0 / can't set it | node not bound | `PwObjectTracker { objects: [...] }` |
| Notifications vanish | not tracked | `n.tracked = true` in `onNotification` |
| Notification server doesn't start | another daemon owns the name | stop dunst/mako/swaync |
| Singleton logic never runs | singletons are lazy | reference it from `shell.qml` |
| `qs -c name` says no config | a default `~/.config/quickshell/shell.qml` exists | use only named configs |
| GlobalShortcut does nothing | missing Hyprland bind / name mismatch | `bind = …, global, quickshell:<name>` |
| IPC function missing in `qs ipc show` | untyped parameters or return | add types to every param and the return |
| Popup cut off | drawn inside the bar window | use PopupWindow |
| Icon missing | name not in theme / wrong theme | `//@ pragma IconTheme …`, fallback in `iconPath` |
| Text blurry | fractional scaling, default rendering | `renderType: Text.NativeRendering` |
| Image looks pixelated | `sourceSize` too small for HiDPI | multiply by `devicePixelRatio` |
| Hot reload changed nothing | error in file (check terminal), or `watchFiles: false` | read the log |
| Old notification popups after reload | re-emitted with `keepOnReload` | skip `n.lastGeneration` |
| Process output empty | pipes without `sh -c`; program not on PATH | wrap in `sh -c`; check `which` |
| Process output parsed wrongly | localized output | `environment: ({ LC_ALL: "C" })` |
| Lock screen shows solid color after crash | shell died while locked (by design) | restart your shell / see [[ch:57-proj-lock]] |

## Bisecting a broken config

1. Comment out half of the modules in `shell.qml`. Still broken? The bug is in the remaining half.
2. Repeat until one module is left.
3. In that module, comment out children or bindings the same way.

With git: `git stash` to confirm the last commit works, `git diff` to see what changed, `git bisect` for older regressions.

## Crash reports

If Quickshell itself crashes, it writes a crash report and prints its location in the log. When reporting a bug upstream, include:

- `qs --version`, your distro, compositor version, and Qt version (`qtpaths6 --qt-version`)
- the crash report or log
- a **minimal** `shell.qml` that reproduces it

## Practice

::: exercise warm | Debug dump
Add a `debug` IPC target with a `dump(): string` function that returns your shell's main states as JSON.
--- solution
```qml
IpcHandler { target: "debug"
    function dump(): string { return JSON.stringify({ launcher: GlobalStates.launcherOpen, dnd: GlobalStates.dnd, theme: Theme.style }) } }
```
:::

::: exercise practice | Overdraw
Run with `QSG_VISUALIZE=overdraw` and find your most overdrawn widget.
:::

::: exercise challenge | Find a broken binding
Break a binding on purpose (assign to a bound property in a handler) and find it using only logs.
--- hint
Add `onWidthChanged: console.log("width", width, new Error().stack)` to the suspect item.
:::
