# Colors and Wallpaper Theming

The signature of modern rices: change the wallpaper and **everything** recolors to match (bar, popups, terminal, GTK apps). This is Material You-style dynamic color. You'll build the pipeline end to end, then add static themes like Catppuccin as an alternative.

## The pipeline

<div class="diagram"><svg viewBox="0 0 860 130" role="img" aria-label="theming pipeline">
<rect class="n" x="10" y="35" width="140" height="56" rx="10"/><text x="30" y="68">wallpaper.jpg</text>
<rect class="a" x="190" y="35" width="140" height="56" rx="10"/><text x="215" y="62">matugen</text><text class="sm" x="210" y="80">M3 palette</text>
<rect class="n" x="370" y="35" width="140" height="56" rx="10"/><text x="392" y="68">colors.json</text>
<rect class="g" x="550" y="35" width="140" height="56" rx="10"/><text x="570" y="62">Colors.qml</text><text class="sm" x="565" y="80">FileView watches</text>
<rect class="n" x="730" y="35" width="120" height="56" rx="10"/><text x="752" y="68">every widget</text>
<path class="ln" d="M150 63 H190 M330 63 H370 M510 63 H550 M690 63 H730"/>
</svg></div>

1. A **generator** (matugen) extracts a Material 3 palette from the wallpaper.
2. It renders **templates** into config files: one JSON file for your shell, plus files for kitty, Hyprland, GTK…
3. Your `Colors` singleton reads the JSON with a watching [[FileView]].
4. Every widget **binds** to `Colors.*`, so they all update instantly. Add `Behavior on color` and they crossfade.

## Material 3 color roles (quick primer)

M3 generates *roles*, not just "a few colors". The ones you'll use:

| Role | Use |
|---|---|
| `primary` / `onPrimary` | main accent (active toggle, selected workspace) / text on it |
| `primaryContainer` / `onPrimaryContainer` | softer accent backgrounds |
| `secondary`, `secondaryContainer`, `onSecondaryContainer` | secondary accents (chips, media) |
| `tertiary`, `tertiaryContainer` | a contrasting third accent |
| `surface` / `onSurface` | main background / main text |
| `surfaceContainerLowest` … `surfaceContainerHighest` | layered backgrounds (cards on panels on bar) |
| `onSurfaceVariant` | secondary text |
| `outline`, `outlineVariant` | borders, dividers |
| `error` / `onError` | warnings (low battery) |
| `shadow`, `scrim` | shadows, dimming overlays |

Rule: put `onX` text on an `X` background, and contrast is guaranteed.

## Step 1: matugen

```bash
paru -S matugen-bin       # or: cargo install matugen
matugen image ~/Pictures/Wallpapers/forest.jpg --dry-run --show-colors   # preview the palette
```

Matugen reads `~/.config/matugen/config.toml`, which lists templates to render:

```toml file="~/.config/matugen/config.toml"
[config]

[templates.quickshell]
input_path  = "~/.config/matugen/templates/quickshell.json"
output_path = "~/.cache/myshell/colors.json"

[templates.kitty]
input_path  = "~/.config/matugen/templates/kitty.conf"
output_path = "~/.config/kitty/colors.conf"
post_hook   = "pkill -USR1 kitty"

[templates.hyprland]
input_path  = "~/.config/matugen/templates/hyprland.conf"
output_path = "~/.config/hypr/colors.conf"
```

Templates use `{{colors.<role>.<scheme>.hex}}` placeholders (`default` follows the chosen mode; also `light` and `dark`):

```json file="~/.config/matugen/templates/quickshell.json"
{
  "primary": "{{colors.primary.default.hex}}",
  "onPrimary": "{{colors.on_primary.default.hex}}",
  "primaryContainer": "{{colors.primary_container.default.hex}}",
  "onPrimaryContainer": "{{colors.on_primary_container.default.hex}}",
  "secondary": "{{colors.secondary.default.hex}}",
  "secondaryContainer": "{{colors.secondary_container.default.hex}}",
  "onSecondaryContainer": "{{colors.on_secondary_container.default.hex}}",
  "tertiary": "{{colors.tertiary.default.hex}}",
  "error": "{{colors.error.default.hex}}",
  "onError": "{{colors.on_error.default.hex}}",
  "surface": "{{colors.surface.default.hex}}",
  "surfaceContainerLow": "{{colors.surface_container_low.default.hex}}",
  "surfaceContainer": "{{colors.surface_container.default.hex}}",
  "surfaceContainerHigh": "{{colors.surface_container_high.default.hex}}",
  "surfaceContainerHighest": "{{colors.surface_container_highest.default.hex}}",
  "onSurface": "{{colors.on_surface.default.hex}}",
  "onSurfaceVariant": "{{colors.on_surface_variant.default.hex}}",
  "outline": "{{colors.outline.default.hex}}",
  "outlineVariant": "{{colors.outline_variant.default.hex}}",
  "shadow": "{{colors.shadow.default.hex}}"
}
```

```text file="~/.config/matugen/templates/hyprland.conf"
$primary = rgb({{colors.primary.default.hex_stripped}})
$surface = rgb({{colors.surface.default.hex_stripped}})
general {
    col.active_border = $primary
    col.inactive_border = $surface
}
```

(Then `source = ~/.config/hypr/colors.conf` in `hyprland.conf`.)

## Step 2: the wallpaper script

```bash file="scripts/wallpaper.sh"
#!/usr/bin/env bash
# usage: wallpaper.sh /path/to/image [dark|light]
set -euo pipefail
img="$(realpath "$1")"
mode="${2:-dark}"
mkdir -p ~/.cache/myshell
ln -sf "$img" ~/.cache/myshell/wallpaper        # the shell's Wallpaper module shows this
matugen image "$img" --mode "$mode"             # renders all templates → colors.json changes
```

```bash
chmod +x ~/.config/quickshell/myshell/scripts/wallpaper.sh
~/.config/quickshell/myshell/scripts/wallpaper.sh ~/Pictures/Wallpapers/forest.jpg
```

## Step 3: the Colors singleton

```qml file="services/Colors.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // public roles: bound to the JSON, with smooth transitions
    property color primary: c.primary
    property color onPrimary: c.onPrimary
    property color primaryContainer: c.primaryContainer
    property color onPrimaryContainer: c.onPrimaryContainer
    property color secondary: c.secondary
    property color secondaryContainer: c.secondaryContainer
    property color onSecondaryContainer: c.onSecondaryContainer
    property color tertiary: c.tertiary
    property color error: c.error
    property color onError: c.onError
    property color surface: c.surface
    property color surfaceContainerLow: c.surfaceContainerLow
    property color surfaceContainer: c.surfaceContainer
    property color surfaceContainerHigh: c.surfaceContainerHigh
    property color surfaceContainerHighest: c.surfaceContainerHighest
    property color onSurface: c.onSurface
    property color onSurfaceVariant: c.onSurfaceVariant
    property color outline: c.outline
    property color outlineVariant: c.outlineVariant
    property color shadow: c.shadow

    // derived colors
    readonly property color barBackground: Qt.rgba(surface.r, surface.g, surface.b, Config.appearance.transparency ?? 0.85)
    function alpha(col: color, a: real): color { return Qt.rgba(col.r, col.g, col.b, a) }

    // crossfade when the palette changes
    Behavior on primary { ColorAnimation { duration: 600 } }
    Behavior on surface { ColorAnimation { duration: 600 } }
    Behavior on onSurface { ColorAnimation { duration: 600 } }
    Behavior on surfaceContainer { ColorAnimation { duration: 600 } }
    Behavior on secondaryContainer { ColorAnimation { duration: 600 } }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/myshell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        blockLoading: true
        printErrors: false            // first run: file may not exist yet, defaults are used

        JsonAdapter {
            id: c
            // defaults (Catppuccin Mocha-ish) used until matugen has run
            property string primary: "#cba6f7"
            property string onPrimary: "#1e1e2e"
            property string primaryContainer: "#45475a"
            property string onPrimaryContainer: "#f5e0dc"
            property string secondary: "#89b4fa"
            property string secondaryContainer: "#313244"
            property string onSecondaryContainer: "#cdd6f4"
            property string tertiary: "#f5c2e7"
            property string error: "#f38ba8"
            property string onError: "#1e1e2e"
            property string surface: "#1e1e2e"
            property string surfaceContainerLow: "#181825"
            property string surfaceContainer: "#24243a"
            property string surfaceContainerHigh: "#2a2a40"
            property string surfaceContainerHighest: "#313244"
            property string onSurface: "#cdd6f4"
            property string onSurfaceVariant: "#a6adc8"
            property string outline: "#6c7086"
            property string outlineVariant: "#45475a"
            property string shadow: "#000000"
        }
    }
}
```

Change the wallpaper with the script: the JSON is rewritten, `fileChanged` fires, the adapter reloads, every `Colors.*` binding updates, and the Behaviors animate the change.

## Static themes as an alternative

Ship theme files with the same keys and switch the path:

```text
assets/themes/catppuccin-mocha.json
assets/themes/gruvbox-dark.json
assets/themes/rose-pine.json
```

```qml
FileView {
    path: Config.appearance.theme === "dynamic"
        ? Quickshell.env("HOME") + "/.cache/myshell/colors.json"
        : Quickshell.shellPath("assets/themes/" + Config.appearance.theme + ".json")
    // …same adapter…
}
```

Now theme switching is one config value, and it even animates.

## Light and dark mode

Run matugen with `--mode light` or `--mode dark`. Store the mode in Config, and expose an IPC function that re-runs the script with the current wallpaper and the new mode:

```qml
IpcHandler {
    target: "theme"
    function setMode(mode: string): void {
        Config.appearance.mode = mode
        Quickshell.execDetached([Quickshell.shellPath("scripts/wallpaper.sh"),
                                 Quickshell.env("HOME") + "/.cache/myshell/wallpaper", mode])
    }
}
```

## Quick colors without matugen: ColorQuantizer

For per-widget colors (a media card tinted by its album art), Quickshell's [[ColorQuantizer]] extracts dominant colors from any image in-process:

```qml
ColorQuantizer {
    id: q
    source: Media.active?.trackArtUrl ?? ""
    depth: 3                 // 2^3 = 8 colors
    rescaleSize: 64          // downscale first (fast)
}
Rectangle { color: q.colors.length ? q.colors[0] : Colors.secondaryContainer }
```

## Theming everything else

| App | How |
|---|---|
| kitty, foot, alacritty | matugen template + reload signal |
| Hyprland borders | template sourced into `hyprland.conf` |
| GTK 3/4 | matugen template to `~/.config/gtk-4.0/gtk.css` (`@define-color accent_color …`) |
| Qt apps | `qt6ct` color scheme template |
| Firefox | pywalfox-style extensions or `userChrome.css` |
| VS Code / Neovim | theme extensions reading generated files |

> [!WILD] In the wild
> end-4 runs matugen plus its own Python scripts (`switchwall.sh`) to produce Material colors, and its `Appearance.qml` reads the result. Caelestia's `caelestia scheme` command writes a scheme file that its `Colours` service loads, supporting both dynamic and static schemes. Same pipeline, different tools.

> [!TRY] Exercises
> 1. Set up matugen, the template and `Colors.qml`, and run the script on two different wallpapers.
> 2. Replace every hard-coded color in your bar with `Colors.*`.
> 3. Add a Catppuccin static theme and a Config option to switch between dynamic and static.
