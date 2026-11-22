# lyne-dots 2: One File for Every Setting

In most rices, settings are scattered: colours in one file, bar options in another, a few numbers hard-coded in widgets. lyne puts **every** setting in a single JSON file, `state.json`, and gives the whole shell one way to read and change it. That decision is what makes its 27-page Settings app possible, and it's the first thing we build.

## The idea

```json
{
  "theme": { "name": "nord" },
  "bar": { "style": "floating", "workspaces": { "style": "dots" } }
}
```

A widget never opens this file. It asks the **state service** for a **key path**:

```qml
StateService.get("bar.style", "docked")        // "floating"
StateService.get("bar.height", 33)             // not in the file → from defaults.json, else 33
StateService.set("bar.workspaces.style", "numbers")
```

Three rules make it work:

1. **Only keys you changed are in `state.json`.** Everything else comes from **`defaults.json`**, which ships with the shell. A fresh install has no `state.json` at all.
2. **`get()` is reactive.** A binding that calls `get("bar.style")` re-evaluates when that value changes, whether it was changed by the Settings app, by `qs ipc call state set …`, or by you editing the file in a text editor.
3. **`set()` saves by itself**, a moment later, in one write.

## The defaults

@include lyne/defaults.json

These are the values the shell uses until you change them. The groups mirror lyne's own `defaults.json` (in the original it's `.data/quickshell/defaults.json`, with about 40 groups): `theme`, `opacity`, `geometry` (corner radii, spacing, padding), `typography`, `animations` (three durations in milliseconds), `bar`, `launcher`, `notifications`, `osd`, `idle`, `power`, `wallpaper` and `screenshot`.

When lyne-dots updates, `lyne update` adds new keys to `defaults.json`, and you get them without your `state.json` being touched. That's the benefit of storing only what you changed.

## The state service, line by line

@include lyne/services/StateService.qml

::: walk
@ 1 | A singleton
`pragma Singleton` makes exactly one `StateService` for the whole shell ([[ch:33-singletons]]). Any file that writes `import qs.services` can call `StateService.get(…)`.
@ 2-5 | Imports
`QtQuick` for the basics, `Quickshell` for `Singleton` and `Quickshell.env`, `Quickshell.Io` for `FileView` and `IpcHandler`. `qs.services` is this file's own folder; importing it keeps the linter happy about the other singletons in it.
@ 13-14 | Where the files are
`state.json` in `~/.config/lyne/` (the original uses `~/.config/quickshell/state.json`). `Quickshell.shellPath("defaults.json")` is the file next to `shell.qml`.
@ 16-18 | The data
`state` and `defaults` are plain JavaScript objects (`var`). `isLoading` is true until `state.json` has been read; `set()` doesn't save during that time, and the idle monitors in `shell.qml` wait for it.
@ 20-27 | The reactivity problem
QML notices when a **property** is assigned. But `state.bar.style = "dots"` changes something *inside* an object: the property `state` itself still holds the same object, so nothing would update. The fix is a small **counter per top-level key**. Reading a counter inside `get()` makes the calling binding depend on it; changing it later makes that binding run again.
@ 29-32 | A counter
A tiny object with one `int`. A `Component` lets us create as many as needed.
@ 34-42 | Depending on a key
For `"bar.workspaces.style"` the top key is `"bar"`. The first time it's needed, a counter is created and remembered in `_counters`. Then its `rev` is **read**, and reading is all it takes: QML records that the current binding used `rev`.
@ 43-46 | Announcing a change
Adding one to `rev` notifies every binding that read it. Only bindings that read something under that top key run again, so changing `bar.style` doesn't re-evaluate every theme binding in the shell.
@ 49-58 | Following a path
Split `"bar.workspaces.style"` at the dots and walk into the object one key at a time. If a step is missing, the answer is `undefined` instead of an error.
@ 60-69 | Writing at a path
The same walk, creating empty objects for missing steps, so `set("a.b.c", 1)` works even when `a` doesn't exist yet.
@ 72-80 | get()
First `state.json`, then `defaults.json`, then the fallback written in the code. Reading `revision` makes every `get()` re-run when `defaults.json` reloads.
@ 82-87 | isDefault()
True when the key isn't in `state.json`, or holds the same value as the default. Settings rows use it to show a reset button only for changed values ([[ch:ly11-settings]]). `JSON.stringify` compares lists and objects by content.
@ 89-96 | set()
If the value doesn't change, do nothing: no save, no re-evaluation. Otherwise store it, bump the top key's counter (bindings update immediately) and restart the save timer.
@ 98-102 | reset()
Set the key back to its default. `JSON.parse(JSON.stringify(…))` copies it, so later changes to the state can't change the defaults object.
@ 105-113 | Applying the file
Parse the text. A broken file (say, a missing comma after a hand edit) is reported and ignored, and the shell keeps its current settings.
@ 114-120 | Only bump what changed
Compare each top-level key before and after, and bump only the ones that differ. When you edit `bar.height` by hand, only bar bindings re-run.
@ 123-128 | Saving
300 ms after the last `set()`, the whole state is written, nicely indented. Dragging a slider calls `set()` dozens of times but writes once.
@ 130-143 | Reading the defaults
A [[FileView]] reads the file; `watchChanges` reloads it when it changes on disk.
@ 145-152 | Reading state.json
`watchChanges` again, so editing the file by hand (or with lyne's CLI, which edits the same file) applies live. `atomicWrites` writes to a temporary file and renames it, so a crash mid-write can never leave a half-written file.
@ 153-157 | No file yet
On the very first start the file doesn't exist; everything comes from the defaults, and the first `set()` creates it.
@ 160-165 | From the terminal
`qs -c lyne ipc call state get bar.style` prints the value as JSON. `set` takes JSON too, so strings need quotes: `qs -c lyne ipc call state set bar.style '"islands"'`.
:::

## Trying it

```bash
qs -c lyne ipc call state set bar.style '"floating"'
qs -c lyne ipc call state set bar.workspaces.style '"numbers"'
cat ~/.config/lyne/state.json
qs -c lyne ipc call state reset bar.style
```

Or open `~/.config/lyne/state.json` in your editor, change a value, and save: the shell follows within a moment.

> [!NOTE] In the original
> `services/StateService.qml` in lyne-dots does the same with two extras: changes you make while an outside edit arrives are merged on top of it (`_unsaved`), and it emits `stateLoaded(keys)` so services can react to outside edits. The `lyne state` command opens the file, `lyne state sync` adds new default keys after an update.

## Practice

::: exercise warm | Your first setting
Add `"clock": { "seconds": false }` to `defaults.json`. Then, in a scratch widget, show the time with seconds only when `StateService.get("clock.seconds", false)` is true. Toggle it from the terminal.
:::

::: exercise practice | A toggle helper
Add `function toggle(path)` to the service that flips a boolean setting, and an IPC function for it. Then `qs -c lyne ipc call state toggle bar.autoHide` should hide and show the bar.
--- solution
```qml
function toggle(path) { set(path, !get(path, false)); }
// in the IpcHandler:
function toggle(path: string): void { root.toggle(path); }
```
:::

::: exercise practice | Prove the reactivity trick
Remove `_depend(path);` from `get()`, restart, and change `bar.style` from the terminal. What happens, and why? Put it back.
--- why
Without reading the counter, the bindings that call `get()` don't depend on anything that changes, so they never re-run: the file changes, but the bar keeps its old style until a restart.
:::

::: exercise challenge | Undo
Keep the last 20 changes in a list (`{ path, before }`) inside `set()`, and add `undo()` that restores the most recent one. Expose it over IPC.
:::
