# lyne-dots 12: Assembling the Shell and Configuring Hyprland

Every piece exists. This chapter connects them: `shell.qml` loads the modules and turns keybinds into actions, and the Hyprland configuration (in **Lua**, the way lyne-dots does it, or classic) starts the shell, binds the keys, blurs the shell's surfaces and floats the Settings window. Then you run the whole thing.

## The entry point

@include lyne/shell.qml

::: walk
@ 1-2 | Pragmas
No "config reloaded" popup while you edit; `UseQApplication` makes tray menus work.
@ 3-17 | Imports
Each module folder is imported by its `qs.` name.
@ 19-22 | Three jobs
That's all `shell.qml` does. Everything else lives in services and modules.
@ 26-29 | Always there
The wallpaper, one bar per screen (with its panels inside it), and the notification popup stack, which only maps a window while there are popups.
@ 31-37 | Only while needed
A [[LazyLoader]] creates its window when `active` turns true and destroys it when it turns false. The launcher, wallpaper picker, OSD, power menu, Settings and lock screen cost nothing while closed. Each is driven by its service's flag, so a keybind, a bar button and `qs ipc call` all open them the same way: by changing the service ([[ch:34-lazy-loading]]).
@ 38 | Screenshots
The overlay manages its own windows (a `Variants` that's empty while inactive), so it's always created and needs an id for the shortcut below.
@ 40-52 | Idle
Lock after the lock timeout, screens off after the screen timeout, back on at the first input. Both are paused by caffeine, respect apps that inhibit idle, and wait until the settings have loaded ([[ch:ly9-lock-power]]).
@ 54-56 | Global shortcuts
A [[GlobalShortcut]] registers a shortcut **with Hyprland**, named `quickshell:<name>`. A Hyprland bind triggers it, with no process started, so it reacts instantly. These are **the same names lyne-dots uses**, so lyne's keybind files drive the rebuild unchanged.
@ 57-65 | Shell shortcuts
Each calls a service. The screenshot goes through `openExclusive` so it closes open popups first and they don't end up in the picture.
@ 67-72 | Media keys
Change the level, then show the OSD for it.
:::

## Hyprland in Lua

Recent Hyprland versions can be configured in **Lua** instead of `hyprland.conf`, and lyne-dots uses that: `~/.config/hypr/hyprland.lua` loads files from `conf/` (appearance, input, keybinds, rules…) and then every `.lua` in `local/`, where its Settings app writes your machine's settings. In Lua, settings are function calls:

```lua
hl.config({ general = { gaps_in = 5, gaps_out = 5, border_size = 2 } })
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.window_rule({ name = "float-pavucontrol", match = { class = "pavucontrol" }, float = true })
```

The rebuild's Hyprland part fits in one file you `require` from your own `hyprland.lua`:

@include lyne/extras/lyne.lua

::: walk
@ 1-3 | Using it
Copy it to `~/.config/hypr/lyne.lua` and add `require("lyne")` to `hyprland.lua`. `require` looks for files relative to the config folder.
@ 7-11 | Autostart
`hl.on("hyprland.start", …)` runs once when Hyprland starts (the Lua version of `exec-once`): the shell, and `wl-paste --watch cliphist store`, which saves everything you copy for the launcher's clipboard mode.
@ 13-16 | A helper
`hl.dsp.global("quickshell:app_launcher")` is the dispatcher that triggers a shell shortcut; `shell("app_launcher")` is shorter.
@ 18-25 | Tap Super for the launcher
A bind on Super alone with `release = true` fires on release, and only if no other key was pressed while Super was held, so Super+1 still switches workspace. Inside a release bind Hyprland would send the shortcut as "released" only, and `GlobalShortcut` acts on "pressed". So the bind starts a one-shot timer of 1 ms that dispatches the shortcut just outside the bind. `LYNE_TAP` is a global so the timer isn't garbage-collected before it fires. (lyne's `conf/binds.lua` does the same for any lone-modifier bind.)
@ 26-33 | Shell keys
The same keys as lyne-dots: Super+V clipboard, Print screenshot, Super+End power menu, Super+Escape lock, Super+B wallpapers, Super+I settings, plus Super+A for the dashboard and Super+N for notifications (unbound by default in lyne).
@ 35-42 | Media keys
`repeating` repeats while the key is held; `locked` makes the bind work on the lock screen too, so you can change the volume while locked.
@ 44-53 | Blur
Each shell window has a namespace (`lyne_bar`, `lyne_attached`…). Layer rules blur behind them. `ignore_alpha` skips fully transparent pixels, so the empty area around a rounded panel isn't blurred. `xray` makes the bar and attached panels blur only the **wallpaper**, not the windows under them, so they always have the same tint: that's why lyne's bar and its panels look like one surface.
@ 55-56 | Floating Settings
The Settings app is a normal window; this rule floats and centres it by its title.
:::

## Hyprland, classic

If you use a classic `hyprland.conf`, source this file instead:

@include lyne/extras/hyprland.conf

The same setup in the classic syntax. Tapping Super uses `bindr` (bind on release) with an IPC call instead of the global shortcut, for the reason explained above. `bindel` repeats and works while locked, `bindl` works while locked.

## kitty

@include lyne/extras/kitty.conf

The theme service writes `~/.config/kitty/current-theme.conf` on every theme change and reloads kitty ([[ch:ly3-config-theme]]). Add this one line to `kitty.conf` once.

## Running it

```bash
cp -r examples/lyne ~/.config/quickshell/lyne
cp ~/.config/quickshell/lyne/extras/lyne.lua ~/.config/hypr/lyne.lua
echo 'require("lyne")' >> ~/.config/hypr/hyprland.lua
echo 'include current-theme.conf' >> ~/.config/kitty/kitty.conf
```

Remove other bars, notification daemons (mako, dunst, swaync) and idle or lock tools (hypridle, hyprlock) from your autostart, then log out and back in, or start it by hand:

```bash
qs -c lyne
```

Useful while working on it:

```bash
qs -c lyne log -f                      # follow the shell's log
qs -c lyne ipc show                    # every IPC target and function
qs -c lyne ipc call theme next
qs -c lyne ipc call state set bar.style '"islands"'
hyprctl globalshortcuts                # the shortcuts the shell registered
```

Quickshell reloads the shell when you save a file, so you can edit a widget and see the change straight away.

## What runs where

| You press / do | Hyprland | Shell |
|---|---|---|
| tap Super | release bind → timer → `quickshell:app_launcher` | `LauncherService.toggle()` → `LazyLoader` creates `Launcher` |
| Volume up | `quickshell:volume_up` | `AudioService.increaseVolume()` + `OsdService.show("volume")` |
| click the clock | – | `DashboardService.toggle("", screen)` → the bar's `DashboardWindow` slides out |
| choose Nord in Settings | `hyprctl eval` (borders) | `StateService.set("theme.name", "nord")` → `ThemeService` → `Config` fades → kitty reloads |
| `qs -c lyne ipc call power toggle` | – | `PowerService.toggle()` |

## Practice

::: exercise warm | Run it for real
Install the rebuild with the steps above and use it for a day. Note three things you'd change.
:::

::: exercise practice | Your own key
Add a global shortcut `quicksettings` to `shell.qml` (opening Quick Settings on the focused screen) and bind it to Super+S in `lyne.lua`.
--- solution
```qml
GlobalShortcut { name: "quicksettings"; onPressed: QuickSettingsService.toggle(DashboardService.focusedScreen()) }
```
```lua
hl.bind(mainMod .. " + S", shell("quicksettings"))
```
:::

::: exercise practice | Gaps from a setting
Add `hyprland.gaps` to `defaults.json`, and make the theme service (or a new small service) apply it with `hyprctl eval 'hl.config({ general = { gaps_out = N } })'` whenever it changes. Add a slider for it in Settings.
:::

::: exercise challenge | Generated keybinds
lyne lists its keybinds in Settings and lets you change them. Start small: export the list of binds from `lyne.lua` to a JSON file at startup (`hl.exec_cmd` with a `printf`), and show them on a "Keybinds" page in Settings.
:::
