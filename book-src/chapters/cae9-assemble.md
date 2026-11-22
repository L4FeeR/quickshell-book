# Caelestia 9: Assembling, Theming and Making It Yours

Everything is built. This chapter connects it: `shell.qml`, keybinds, colours from your wallpaper, transparency with blur, and a list of changes to make the rebuild your own.

## Module 1: shell.qml

@include cae/shell.qml

That's the whole entry point. The pragmas come first: `UseQApplication` lets tray menus use native menus, `QS_NO_RELOAD_POPUP` hides the reload notice, and `QT_QUICK_CONTROLS_STYLE=Basic` makes Qt's controls (sliders, switches, text fields) easy to restyle. Then the four top-level pieces: the background, the drawers (frame, bar and every panel on each monitor), the lock and the shortcuts. Touching `Notifs` at startup makes the notification server start at login instead of the first time something uses it.

Run it:

```bash
qs -c cae
```

## Module 2: Keybinds

@include cae/extras/hyprland.conf

- `bindr = SUPER, SUPER_L, …` fires on the **release** of Super when nothing else was pressed: tap Super to open the launcher, like Caelestia.
- The `global` dispatcher talks to the `GShortcut`s in `daemons/Shortcuts.qml`.
- Locking uses IPC because the lock module isn't a drawer.

> [!NOTE] Lua configs
> If your Hyprland is configured in Lua (Caelestia's own dots use `hyprland.lua`), the same binds look like:
> ```lua
> hl.bind("SUPER + D", hl.dsp.global("cae:dashboard"))
> hl.bind("SUPER + SUPER_L", hl.dsp.global("cae:launcher"), { release = true })
> ```
> Start `qs -c cae` from your Lua config's startup hook (see your Hyprland version's wiki).
> The shell itself already works with both config styles thanks to the `Hypr` helper.

## Module 3: Colours from your wallpaper

1. Install matugen and copy the two files from `extras/`:
   ```bash
   mkdir -p ~/.config/matugen
   cat ~/.config/quickshell/cae/extras/matugen-config.toml >> ~/.config/matugen/config.toml
   ```
2. Put some images in `~/Pictures/Wallpapers` (or set `paths.wallpaperDir` in `shell.json`).
3. Open the launcher, type `>wallpaper`, pick one. matugen writes `~/.local/state/cae/scheme.json` and the shell fades to the new palette.

> [!TIP] Using the real caelestia CLI
> If you have the `caelestia` CLI installed, point `Colours` at its scheme file instead (`~/.local/state/caelestia/scheme.json`, same format) and its `caelestia scheme set …` commands, including its preset schemes like Catppuccin and Gruvbox, will drive the rebuild too.

## Module 4: Transparency and blur

In `~/.config/cae/shell.json`:

```json
"appearance": { "transparency": true, "transparencyBase": 0.8 }
```

The frame and drawers become 80% opaque (all at once, because they're drawn in one layer; [[ch:cae3-frame]]). The `layerrule` lines in `extras/hyprland.conf` make Hyprland blur what's behind the `cae-drawers` namespace, giving the frosted look.

## Troubleshooting

| Problem | Likely cause and fix |
|---|---|
| Icons show as words ("wifi") | the Material Symbols font isn't installed; `fc-list \| grep -i "material symbols"` |
| Nothing opens on the top edge | the dashboard zone is only the middle of the edge (the dashboard's width + rounding); hover there, or press the keybind |
| Clicks in the middle of the screen don't work | something is in the mask that shouldn't be; check `ContentWindow.mask` and that closed drawers have zero depth |
| Windows overlap the frame | the `Exclusions` windows didn't start; look for errors mentioning `Exclusions.qml` in the `qs` output |
| Volume shows 0 and can't change | the PipeWire node isn't tracked; `Audio.qml` must keep its `PwObjectTracker` |
| Colours never change | matugen isn't writing to `~/.local/state/cae/scheme.json`; run `matugen image <file>` and read its output |
| Brightness slider missing | no `/sys/class/backlight` device (desktop monitor); expected |
| Workspace clicks do nothing on a Lua Hyprland config | your Quickshell is older than `Hyprland.usingLua`; update Quickshell, or replace `Hypr.lua` with `true` |

## The rebuild vs the original

| Feature | Original | Rebuild |
|---|---|---|
| Frame with drawers that melt into it | ✓ (GPU blobs, with stretch while moving) | ✓ (QML shapes) |
| Vertical bar, config-driven entries | ✓ | ✓ |
| Merged workspace backgrounds, trailing indicator, window icons | ✓ | ✓ |
| Bar popouts with morphing size | ✓ (+ tray menus, window preview, detachable) | ✓ (audio, network, Bluetooth, battery) |
| Dashboard with tabs | ✓ (+ weather tab, GPU/network cards) | ✓ |
| Launcher: apps, actions, calculator, wallpapers | ✓ (+ schemes, fuzzy search, variants) | ✓ |
| Notifications, centre, session, OSD, quick toggles | ✓ (+ grouping, recording, toasts) | ✓ |
| Lock screen | ✓ (+ media, weather, notifications, fetch) | ✓ (clock, picture, password) |
| Per-monitor config, drag gestures, game mode, settings app | ✓ | — |

## Make it yours

Small changes with a big effect, all in a few lines:

- **Frame style**: `border.thickness: 0` gives floating panels without a frame; `rounding: 0` gives sharp inner corners.
- **Bar on hover only**: `bar.persistent: false`.
- **Fonts**: change `Tokens.font.sans` (try "Google Sans Flex", "Inter", "Outfit").
- **Motion**: make everything snappier by lowering the durations in `Tokens.anim.durations`, or calmer with the `standard` curve instead of the expressive ones.
- **New drawer**: follow the left-edge drawer exercise in [[ch:cae3-frame]].
- **Mix with the Ricing Guides**: replace any module with a variant from Part R (for example the launcher layouts in [[ch:r3-launcher]]); they use the same patterns.

## Practice

::: exercise practice | Frameless mode
Make a `frameless` option: when on, the frame thickness is 0 but drawers still come out of the screen edges, with a small gap and a full rounding on all corners.
--- hint
With thickness 0 the ears have nothing to attach to; set `earRadius` to 0 for the `Bg` components and give drawers a margin from the edge.
:::

::: exercise challenge | Bar on the right
Put the bar on the right side instead: move `BarWrapper`, give the frame's **right** side the bar width, attach popouts to the right edge, and move the right-side drawers to the left.
:::

::: exercise project | Your Caelestia
Change at least five things (colours, fonts, frame, one module, one new drawer or action) and take a screenshot with the dashboard and a notification visible. That's your first complete rice built on a real architecture.
:::
