# end-4 9: Assembling, Theming and Making It Yours

Time to put the panels together: `shell.qml`, keybinds, colours from your wallpaper, and ideas for making the rebuild your own.

## Module 1: shell.qml

@include impulse/shell.qml

::: walk
@ 1-3 | Pragmas
Native tray menus, no reload popup, and the Basic controls style so sliders and text fields can be restyled.
@ 23 | Load the colours now
Singletons are created the first time something uses them; calling `reapply()` at startup applies the theme before the first panel appears.
@ 25-28 | PanelLoader
An inline component: a `LazyLoader` that only becomes active once `Config.ready` is true. This is exactly ii's `PanelLoader` pattern: no panel is built with default settings and then rebuilt a moment later with yours.
@ 30-39 | The panels
One line per panel. `component: Bar {}` gives the loader a component to create (QML wraps the object declaration in a `Component` automatically, because the property's type is `Component`). To disable a panel, delete or comment out its line.
:::

> [!NOTE] In the original
> `shell.qml` loads a **panel family** (`IllogicalImpulseFamily` or `WaffleFamily`), and each family lists its panels with `PanelLoader`s, some with extra conditions (the dock only when enabled, the horizontal or vertical bar depending on the config). `qs -c ii ipc call panelFamily cycle` switches families live.

## Module 2: Keybinds

@include impulse/extras/hyprland.conf

- **Super+Tab** opens the overview; **tapping Super** alone opens it too (the `bindr` fires on release only if nothing else was pressed).
- Holding Super sends `workspaceNumber` press and release events (bound with the `i` "ignore modifiers" and `t` "transparent" flags, so Super still works in your other binds), which swaps the workspace icons for numbers and reveals an auto-hidden bar.
- The `layerrule`s blur behind every `quickshell:` surface and turn off Hyprland's own animations for the ones that animate themselves.

> [!NOTE] Lua configs
> end-4's own Hyprland config is Lua. The equivalent binds look like `hl.bind("SUPER + Tab", hl.dsp.global("impulse:overviewToggle"))`, and for the Super key: `hl.bind("SUPER_L", hl.dsp.global("impulse:workspaceNumber"), { ignore_mods = true, transparent = true })` plus the same with `release = true`.

## Module 3: Colours from your wallpaper

@include impulse/extras/matugen-config.toml

@include impulse/extras/colors.json.template

1. Append the template block to `~/.config/matugen/config.toml`.
2. Set a wallpaper and generate colours in one go, from a terminal or a keybind:
   ```bash
   qs -c impulse ipc call config set background.wallpaperPath ~/Pictures/Wallpapers/forest.jpg
   matugen image ~/Pictures/Wallpapers/forest.jpg
   ```
3. `MaterialThemeLoader` sees the new `colors.json` and every layer colour updates.

The template uses matugen's snake_case names (`on_primary_container`), which the loader converts to `m3onPrimaryContainer` ([[ch:ii2-foundations]]).

## Troubleshooting

| Problem | Likely cause and fix |
|---|---|
| Nothing appears at all | `Config.ready` never became true; check `~/.config/impulse/` is writable and look for errors about `Config.qml` |
| Workspace icons are question marks | the window's class doesn't match a desktop entry; check `hyprctl clients` and the app's `.desktop` `StartupWMClass` |
| Overview previews are empty | your Quickshell build lacks screencopy support, or the compositor doesn't allow it; the icons still show |
| Overview windows are in the wrong place | multi-monitor setups with scaling: compare `hyprctl monitors -j` positions with your layout |
| The sidebar steals keyboard input | it only takes the keyboard on demand; if typing stops working, check the `keyboardFocus` line |
| Super-hold does nothing | the `workspaceNumber` binds are missing, or another program registered the same global shortcut |
| Translator or clipboard tab empty | install `translate-shell` / `cliphist` (and run `wl-paste --watch cliphist store` in your autostart) |

## The rebuild vs the original

| Feature | Original | Rebuild |
|---|---|---|
| Grouped bar with hanging corners, auto-hide, styles | ✓ (+ vertical bar, popups on hover) | ✓ |
| Workspaces: merged backgrounds, trailing pill, app icons, Super for numbers | ✓ (+ masked colouring, hover indicator, special-workspace blur) | ✓ |
| Right sidebar | ✓ (+ two toggle styles, dialogs, to-do, timers, mixer) | ✓ |
| Left sidebar | AI chat, translator, booru | translator, clipboard |
| Overview with search and live previews, drag between workspaces | ✓ (+ emoji, clipboard, position drag, special workspaces) | ✓ |
| OSD, popups, screen corners, session, lock, background | ✓ | ✓ (simpler) |
| Dock, cheatsheet, media controls, OSK, region selector, translator overlay, settings app, second family | ✓ | — |

## Make it yours

- **Bar style**: `bar.cornerStyle` 0/1/2, `bar.bottom`, `bar.autoHide.enable`.
- **Colours**: a light scheme (`matugen image … -m light`), or set `Appearance.m3colors` defaults to your favourite palette for a fixed theme.
- **Motion**: every animation uses the presets in `Appearance.animation`, so one edit changes the feel of the whole shell.
- **More panels**: the dock from [[ch:r7-dock]] or the cheatsheet from [[ch:g3-islands-popups]] fit straight in: add a folder, a `GlobalStates` flag, and a `PanelLoader` line.
- **Combine both rebuilds**: Caelestia's frame with ii's grouped bar, or ii's overview inside Caelestia's drawers. Both use Material 3 roles, so the pieces match visually.

## Practice

::: exercise practice | Add the dock
Add a dock panel: copy the dock from [[ch:r7-dock]], replace its `Theme.*` colours with `Appearance.colors.*`, add `dockOpen` handling or `Config.options.dock.enable`, and load it with a `PanelLoader`.
:::

::: exercise challenge | A vertical bar
Add `bar.vertical` to the config and a `VerticalBar` panel (left edge) that reuses the modules with a `ColumnLayout`, loaded instead of `Bar` when the option is on.
:::

::: exercise project | Your illogical-impulse
Change at least five things (bar style, colours, a sidebar tab, a new panel, motion), and take a screenshot with the overview open and the right sidebar visible.
:::
