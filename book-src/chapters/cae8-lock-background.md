# Caelestia 8: Lock Screen, Wallpaper and Shortcuts

Three pieces live outside the drawers window: the **lock screen** (a real Wayland session lock), the **background** (wallpaper and desktop clock on the bottom layer), and the **shortcuts daemon** that connects keybinds to drawers. This chapter also covers the wallpaper service that re-themes the shell.

```text
modules/lock/        Lock  LockSurface
modules/background/  Background
services/            Wallpapers  Time
daemons/             Shortcuts
```

## Module 1: The lock controller

@include cae/modules/lock/Lock.qml

::: walk
@ 12-16 | Shared state
The password lives here, not in the surfaces, because there's one surface **per monitor** and they all share the same field. `failed` is a signal so every surface can shake its input at once.
@ 18-23 | Submitting
Ignore Enter while a check is running or when nothing was typed; otherwise start PAM.
@ 25-38 | PAM
[[PamContext]] talks to the system's authentication (the same thing `sudo` and your login use; it also handles fingerprint readers). When PAM asks a question that needs an answer (`responseRequired`), we answer with the password. On success the lock is released; otherwise a message is shown and `failed` fires. The password is always cleared.
@ 40-45 | The real lock
[[WlSessionLock]] uses the Wayland session-lock protocol. The compositor itself keeps the screen covered until the lock is released, **even if Quickshell crashes**, so it's safe. `WlSessionLockSurface` creates one surface per monitor, each containing a `LockSurface`.
@ 47-51 | IPC
`qs -c cae ipc call lock lock` locks the screen (bind it to a key or run it from `hypridle`). There's deliberately no IPC to unlock.
:::

> [!WARNING] Test with a safety net
> Before trusting any lock screen, add a temporary `Timer { running: root.locked; interval: 60000; onTriggered: root.locked = false }` to `Lock.qml`, test wrong and right passwords, then remove the timer. If something goes wrong anyway, switch to a TTY (<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F2</kbd>) and run `pkill qs`; the compositor then shows its own fallback until you unlock with `loginctl unlock-session`.

## Module 2: The lock surface

@include cae/modules/lock/LockSurface.qml

::: walk
@ 20-34 | A frozen, blurred screen
[[ScreencopyView]] captures what was on the monitor (by default once, not live), and `MultiEffect` blurs and darkens it. The lock looks like a frosted version of your desktop, which is Caelestia's default (it can also use the wallpaper).
@ 36-52 | Clock and date
Big and centred, in the primary colour.
@ 54-66 | Profile picture
`~/.face` in a circle, like the dashboard.
@ 68-88 | An invisible text field
The real `TextInput` is fully transparent: it only collects keystrokes. It shares its text with the controller in both directions, so typing on any monitor updates every monitor. It takes focus as soon as it's created.
@ 90-104 | Dots that pop in
One dot per character (up to 16). Each dot starts at scale 0 and animates to 1 when created, so every keystroke "pops". Backspace removes the last dot.
@ 106-111 | Hint and errors
"Enter password", "Checking…" while PAM works, or the error in red.
@ 113-127 | The shake
A `Translate` transform plus a short sequence moving it left and right twice. It runs whenever the controller emits `failed`.
:::

> [!NOTE] In the original
> `modules/lock/` is much richer: a `Content.qml` with a media card, notification list, weather, system resources and a "fetch" panel, plus `Pam.qml` handling fingerprint and other PAM messages, and a profile picture with an animated ring. The structure is the same: a controller with `WlSessionLock`, a surface per screen, and an invisible input.

## Module 3: Time

@include cae/services/Time.qml

One clock for the whole shell. `format()` wraps `Qt.formatDateTime`, so modules write `Time.format("hh:mm")`.

## Module 4: Wallpapers and theming

@include cae/services/Wallpapers.qml

::: walk
@ 13-14 | List and current
`list` is every image in the wallpaper folder; `current` is stored in a small JSON file in the state folder, so it survives restarts.
@ 16-24 | Setting a wallpaper
Save the path and run **matugen** on the image, in the light or dark mode chosen in the config. `regenerate()` re-runs it for the current wallpaper (the settings app calls it when you switch modes). matugen generates a Material palette from the picture and writes every template you configured, including the `scheme.json` that `Colours` watches. So: pick a wallpaper → matugen → `scheme.json` changes → `Colours` reloads → the shell fades to the new colours.
@ 32-38 | Scanning the folder
`find` lists images up to two folders deep. The folder is passed as `$1` (not pasted into the command string), so paths with spaces or quotes are safe.
@ 40-50 | Remembering the choice
A `JsonAdapter` with one property. `onLoadFailed` writes the file the first time.
@ 52-56 | IPC
`qs -c cae ipc call wallpaper set ~/Pictures/Wallpapers/forest.jpg` from scripts or keybinds.
:::

The matugen side lives in `extras/`:

@include cae/extras/matugen-config.toml

@include cae/extras/scheme.json.template

`hex_stripped` gives colours without `#`, the format `Colours.load()` expects (it's the format the real `caelestia` CLI writes too). Add more templates to the same matugen config to theme your terminal, GTK and Hyprland borders from the same wallpaper.

## Module 5: The background

@include cae/modules/background/Background.qml

::: walk
@ 12-23 | A window under everything
One fullscreen window per monitor on the `Background` layer, below all windows. Its colour is shown until the first image loads.
@ 25-28 | Loading into the hidden image
Two images are stacked. When the wallpaper changes, the new file is loaded into whichever image is currently hidden, so the old wallpaper stays visible while the new one decodes.
@ 30-36 | Shared image settings
`sourceSize` decodes at the screen's real pixel size (logical size × scale), never at the file's full resolution.
@ 37-41 | Crossfade when ready
When the hidden image has finished loading the current wallpaper, it becomes the visible one; the opacity `Behavior`s cross-fade the two.
@ 43-59 | Desktop clock
A big clock in the bottom-left, inside the frame.
:::

## Module 6: Shortcuts and IPC

@include cae/daemons/Shortcuts.qml

::: walk
@ 13-16 | Toggle on the focused screen
Every shortcut toggles a flag in the focused monitor's `ScreenState` ([[ch:cae2-foundations]]). `drawer in s` checks the name is real before touching it.
@ 18-24 | Global shortcuts
Each `GShortcut` registers `cae:<name>` with Hyprland. Pressing the bound key notifies the shell directly, with no process started, so it's instant.
@ 26-35 | IPC
The same actions from the command line: `qs -c cae ipc call drawers toggle launcher`, and `qs -c cae ipc call settings open` for the settings window ([[ch:set1-overview]]).
@ 37-39 | One appid for all
An inline component sets `appid: "cae"` once, so the binds are `global, cae:dashboard`. (It's named `GShortcut` because `Shortcut` is already a QtQuick type for keyboard shortcuts.)
:::

> [!NOTE] In the original
> `daemons/Shortcuts.qml` also has `launcherInterrupt` (so pressing another key while Super is held cancels the "tap Super to open the launcher" bind), media and brightness shortcuts, and toaster IPC (`caelestia shell toaster info …`). Other daemons handle battery warnings, game mode (turns off animations and blur) and idle locking.

## Practice

::: exercise warm | Lock on idle
Make the screen lock after 10 minutes of inactivity using [[IdleMonitor]] in `Lock.qml`.
--- solution
```qml
IdleMonitor {
    timeout: 600
    onIsIdleChanged: if (isIdle) root.locked = true
}
```
(Add `import Quickshell.Wayland` if it isn't there; it is in `Lock.qml`.)
:::

::: exercise practice | Wallpaper lock background
Add `Config.lock.useWallpaper` and show the blurred wallpaper instead of the screen capture when it's true.
:::

::: exercise practice | Random wallpaper shortcut
Add a `GShortcut { name: "randomWallpaper" }` that picks a random file from `Wallpapers.list`.
--- solution
```qml
GShortcut {
    name: "randomWallpaper"
    onPressed: Wallpapers.set(Wallpapers.list[Math.floor(Math.random() * Wallpapers.list.length)])
}
```
:::

::: exercise challenge | Media on the lock screen
Add a media card under the password field with the current track and play/pause/next buttons (they work while locked because the lock surface is part of the shell).
:::
