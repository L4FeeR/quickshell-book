# Gallery: Build a Whole Shell from the Gallery

Every widget in this gallery is a separate file in `examples/galleryshell/`, and the folder is also a **complete, runnable Quickshell config**. This chapter shows how the pieces are put together: a bar made of chips, notifications, a launcher, a dock, a lock screen, an idle manager, a polkit agent, OSDs, a wallpaper and a dozen pickers, all wired up in one 80-line `shell.qml`.

Use it three ways:

1. **Run it as it is**, to try every widget at once.
2. **Copy it as a starting point** and delete what you don't want.
3. **Read it as a recipe** for combining widgets in your own shell.

<div class="preview"><svg width="640" height="380" viewBox="0 0 640 380"><rect width="640" height="380" rx="14" fill="#f5c2e7" opacity=".25"/><rect width="640" height="380" rx="14" fill="#11111b" opacity=".55"/><rect x="8" y="8" width="624" height="34" rx="12" fill="#1e1e2e" stroke="#313244"/><g font-size="10"><rect x="14" y="13" width="24" height="24" rx="12" fill="#313244"/><text x="21" y="29" fill="#cba6f7">▦</text><rect x="42" y="13" width="44" height="24" rx="8" fill="#cba6f7"/><text x="50" y="29" fill="#1e1e2e" font-weight="700">1 ●●</text><rect x="90" y="13" width="30" height="24" rx="8" fill="#313244"/><text x="98" y="29" fill="#cdd6f4">2 ●</text><text x="128" y="29" fill="#cdd6f4">kitty — ~/src</text><rect x="262" y="13" width="80" height="24" rx="12" fill="#313244"/><text x="302" y="29" fill="#cdd6f4" text-anchor="middle">Sat 22 Nov</text><rect x="346" y="13" width="56" height="24" rx="12" fill="#313244"/><text x="354" y="29" fill="#cba6f7">⏸ Daft…</text><rect x="420" y="13" width="56" height="24" rx="12" fill="#313244"/><circle cx="432" cy="25" r="5" fill="#89b4fa"/><circle cx="446" cy="25" r="5" fill="#a6e3a1"/><circle cx="460" cy="25" r="5" fill="#f38ba8"/><rect x="480" y="13" width="24" height="24" rx="12" fill="#313244"/><rect x="508" y="13" width="24" height="24" rx="12" fill="#313244"/><rect x="536" y="13" width="44" height="24" rx="12" fill="#313244"/><text x="544" y="29" fill="#cdd6f4">76%</text><rect x="584" y="13" width="42" height="24" rx="12" fill="#313244"/><text x="590" y="29" fill="#f38ba8">⚙ ⏻</text></g><rect x="420" y="52" width="210" height="64" rx="14" fill="#1e1e2e" stroke="#313244"/><rect x="430" y="62" width="34" height="34" rx="8" fill="#a6e3a1"/><text x="472" y="76" fill="#cdd6f4" font-size="11" font-weight="700">Spotify</text><text x="472" y="92" fill="#a6adc8" font-size="10">Instant Crush — Daft Punk</text><rect x="190" y="110" width="260" height="170" rx="18" fill="#1e1e2e" stroke="#313244"/><rect x="200" y="120" width="240" height="30" rx="15" fill="#313244"/><text x="216" y="140" fill="#cdd6f4" font-size="12">⌕ fire</text><rect x="200" y="158" width="240" height="34" rx="10" fill="#45365e"/><circle cx="218" cy="175" r="10" fill="#fab387"/><text x="236" y="179" fill="#cdd6f4" font-size="12">Firefox</text><circle cx="218" cy="210" r="10" fill="#89b4fa"/><text x="236" y="214" fill="#cdd6f4" font-size="12">Firewall Configuration</text><text x="40" y="200" fill="#cdd6f4" font-size="42" font-weight="700" opacity=".9">14:32</text><text x="42" y="222" fill="#a6adc8" font-size="12">Saturday, 22 November</text><rect x="210" y="312" width="220" height="56" rx="18" fill="#1e1e2e" stroke="#313244"/><circle cx="240" cy="338" r="16" fill="#fab387"/><circle cx="282" cy="338" r="16" fill="#89b4fa"/><circle cx="324" cy="338" r="16" fill="#a6e3a1"/><circle cx="366" cy="338" r="16" fill="#f9e2af"/><circle cx="406" cy="338" r="14" fill="#f5c2e7"/><rect x="236" y="358" width="8" height="3" rx="1.5" fill="#cba6f7"/><rect x="280" y="358" width="4" height="3" rx="1.5" fill="#a6adc8"/></svg></div>

*The assembled shell: bar, a notification popup, the launcher, a desktop clock and the dock.*

## The folder

```text
galleryshell/
├── shell.qml           the entry point (this chapter)
├── hyprland.conf       keybinds to source from your Hyprland config
├── services/           Notifs, Session (shared singletons)
├── bar/                Bar.qml + every bar chip (g1, g2, g7)
├── popups/             chips with popups, overlays, OSDs (g3, g8)
├── panels/             quick settings, app grid, power menu, pickers (g4)
├── desktop/            desktop-layer widgets (g5)
├── effects/            corners, glass, hot corners… (g6)
└── system/             notifications, lock, polkit, idle, dock, launcher, wallpaper (g9)
```

Each folder is a QML module: `import qs.bar` makes every file in `bar/` available as a type (`NetworkChip`, `Tray`…), `import qs.services` gives the `Notifs` and `Session` singletons. That's the whole mechanism; no registration or build step ([[ch:42-project-layout]]).

## Installing it

```bash
cp -r examples/galleryshell ~/.config/quickshell/galleryshell
```

```bash
qs -c galleryshell
```

Then add the keybinds to your Hyprland config:

@include galleryshell/hyprland.conf

Install what the widgets call out to (Arch package names; most are optional and only the widget that uses one needs it):

```bash
sudo pacman -S --needed ttf-material-symbols-variable-git brightnessctl cliphist wl-clipboard grim slurp jq wf-recorder hyprsunset libnotify pavucontrol blueman
```

(`ttf-material-symbols-variable-git` is from the AUR; any package that installs the **Material Symbols Rounded** font works.)

> [!IMPORTANT] Turn off what it replaces
> The shell runs its own notification daemon, polkit agent, lock screen, idle manager and wallpaper. Remove `mako`/`dunst`/`swaync`, `hyprpolkitagent`/`polkit-gnome`, `hypridle`, `hyprlock` and `swww`/`hyprpaper` from your `exec-once` lines, or the shell will report that a role is already taken.

## The entry point

@include galleryshell/shell.qml

::: walk
@ 1-2 | Pragmas
`UseQApplication` is needed for native tray menus (the tray's right-click menus). `QS_NO_RELOAD_POPUP` hides the "config reloaded" popup while you edit.
@ 3-12 | Imports
The two Quickshell modules this file uses directly, then the seven folders. Every type below comes from one of them.
@ 16 | ShellRoot
The root of a config. Everything inside it is created when the shell starts.
@ 17-20 | Background
The wallpaper draws on the background layer. The picker gets the wallpaper object through `target`, so picking an image calls `wallpaper.set()` directly; `id`s in `shell.qml` are how pieces find each other. Rounded screen corners come from [[ch:g6-effects]].
@ 22-31 | The bar
[[Variants]] creates one `Bar` per screen and recreates them when monitors are plugged in or out. Each bar receives the windows its buttons control. Variants delegates can use ids from `shell.qml`, so `notifCenter` here is the `NotificationCenter` below.
@ 33-35 | Notifications
The popups and the center both read the `Notifs` service. Neither knows about the other.
@ 37-39 | Launchers
The list launcher from [[ch:g9-system]] and the grid from [[ch:g4-panels]]. Both can exist; each has its own keybind.
@ 40-47 | Syncing quick settings
The quick settings panel from [[ch:g4-panels]] has its own `dnd` and `caffeine` toggles, while the shell's services keep theirs. Two handlers copy panel → service, and two `Connections` copy service → panel. Assigning a value a property already has doesn't emit a change, so this can't loop. This is the usual way to connect a self-contained widget to shared state without editing the widget.
@ 48-57 | Panels and overlays
Every overlay is a `Scope` with an IPC target, so each just needs to exist; `hyprland.conf` opens them with `qs ipc call`. The power menu gets an id because the bar opens it.
@ 59-63 | On-screen displays
Volume, workspace, charging and low battery. They watch their data source and show themselves.
@ 65-67 | Desktop
The dock on every screen and a clock on the desktop layer. Any widget from [[ch:g5-desktop]] can go here.
@ 69-72 | Session
Lock screen, idle manager and polkit agent: the three system roles.
@ 74-79 | Global shortcuts
[[GlobalShortcut]] registers a Hyprland global shortcut named `quickshell:<name>`; a `bind = …, global, quickshell:launcher` line in Hyprland triggers it. Unlike `exec qs ipc call`, no process is started, so it reacts instantly.
:::

## The bar

@include galleryshell/bar/Bar.qml

::: walk
@ 9-16 | Inputs
`modelData` is the screen, set by `Variants`. The four `var` properties receive other parts of the shell. They default to `null`, and every button checks before using them, so the bar also works on its own.
@ 18-22 | The window
Full width along the top, 42 px tall. The window itself is transparent; the visible bar is the rounded rectangle inside, with a 6 px gap above and 8 px at the sides. The namespace matches the blur rule in `hyprland.conf`.
@ 30-44 | Left
A launcher button, the workspace list from [[ch:g7-bar-modules-2]] limited to this screen, the submap pill (invisible unless a submap is active), and the active window title from [[ch:g1-bar-modules]].
@ 46-52 | Centre
The date chip with its calendar, and the media controls. `anchors.centerIn` keeps them centred on the screen whatever the sides contain.
@ 54-65 | Right
Status chips. Most hide themselves when there's nothing to show: no Bluetooth adapter, no battery, no tray items, Caps Lock off.
@ 66-70 | The bell
The notification bell from [[ch:g1-bar-modules]] was written with plain `count` and `dnd` properties so it doesn't depend on any service. Here they're bound to `Notifs`, and a `TapHandler` added from outside opens the center. Adding handlers to a widget from where you use it is a clean way to give it behaviour it doesn't have itself.
@ 71-86 | Quick settings and power
Two icons in one pill.
:::

## Changing it

**Swap a widget.** Replace `WorkspaceList { screen: bar.screen }` with `WorkspaceDots {}`, or `MediaMarquee {}` with `MediaPill {}`. Chips are interchangeable because they all have the same height and pill shape.

**Remove a widget.** Delete its line. Nothing else refers to it unless it has an `id` used elsewhere (only the four windows the bar opens, and the wallpaper).

**Add a widget.** Put any file from the gallery into the right folder and add one line: a chip in `Bar.qml`, anything else in `shell.qml`.

**Move the bar.** Change `anchors` to `{ bottom: true; left: true; right: true }`, swap `topMargin` for `bottomMargin`, and change the popups' `anchor.edges` from `Edges.Bottom` to `Edges.Top` (and `anchor.margins.top` to `anchor.margins.bottom`).

**Theme it.** The gallery uses Catppuccin Mocha hex colours so each file stands alone. To make the whole shell switchable, copy `services/Theme.qml` from the theming kit, then replace the colours with roles as [[ch:th4-themed-widgets]] describes; `grep -rn '"#' galleryshell/` finds them all.

## What was tested

Every file passes `qmllint`. The whole shell loads and runs under Quickshell, and the bar, tray, dock, launcher and notification center were checked on screen. Hyprland-specific parts (workspaces, submaps, global shortcuts, focus grabs, `hyprctl` calls) need a Hyprland session; on other compositors they log a warning and do nothing.

## Practice

::: exercise warm | Run it
Install the shell, run `qs -c galleryshell`, and try every keybind in `hyprland.conf`.
:::

::: exercise practice | Make it yours
Remove five widgets you don't need and add two from the gallery that aren't in the default setup (the Pomodoro timer and the system rings, for example).
:::

::: exercise practice | A second bar
Add a vertical bar on the left of your main monitor with the system monitors from [[ch:g2-system-monitors]].
--- hint
Anchor it `{ left: true; top: true; bottom: true }` with `implicitWidth: 48`, use a `ColumnLayout`, and set `screen: Quickshell.screens[0]`.
:::

::: exercise challenge | Settings for the shell
Use the settings app from [[ch:set1-overview]] to choose which bar chips are shown, saving the list in a JSON file that `Bar.qml` reads.
--- hint
Give each chip `visible: Config.chips.includes("network")`, where `Config` is a singleton with a `FileView` + `JsonAdapter`.
:::

::: exercise project | Your own rice
Starting from this shell, build your own desktop: pick a theme, rearrange the bar, choose your widgets, and write your own `hyprland.conf` keybinds. Take a screenshot and compare it with where you started in [[ch:01-what-is-ricing]].
:::
