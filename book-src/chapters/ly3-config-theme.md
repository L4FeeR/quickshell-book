# lyne-dots 3: Design Tokens, Themes and the Colour Fade

Open any widget in lyne and you won't find `"#7aa2f7"` or `radius: 12`. You'll find `Config.accentColor` and `Config.radius`. These names are **design tokens**: one place decides what "the accent" or "a normal corner" means, and every widget follows. This chapter builds the three files behind them: the theme files, the theme service that loads and exports them, and `Config`, which turns settings and themes into tokens and fades between themes.

## A theme file

@include lyne/themes/tokyonight.json

This is lyne-dots' theme format, so a theme made for the real dots works in the rebuild and the other way round. Copy a file into `~/.local/themes/` and it appears in both.

| Section | Used for |
|---|---|
| `name`, `variant` | the name in pickers; `"dark"` or `"light"` (GTK follows it) |
| `palette` | **the shell's colours**, by role (table below) |
| `opacity.background` | how see-through panels are (the original applies it; the rebuild keeps its own setting) |
| `hyprland` | window border and shadow colours, as `rrggbbaa` hex without `#` |
| `terminal` | kitty's colours: background, cursor, tabs, and the 16 (or 18) ANSI colours |

The palette roles:

| Role | Meaning |
|---|---|
| `background` | panels and the bar |
| `surface0` … `surface3` | raised layers, lightest last in a dark theme: cards, hover, borders, inactive items |
| `text`, `subtext`, `muted` | normal text, secondary text, hints and empty states |
| `textReverse` | text **on** the accent colour |
| `accent` | the one highlight colour: active workspace, selection, sliders |
| `success`, `warning`, `error` | charging, caution, critical |

Roles describe **purpose**, not looks. Widgets ask for "the colour for secondary text", so any palette that fills the roles works everywhere ([[ch:th1-colour-basics]] explains the idea in depth).

## Mixing colours properly

Fading from Tokyo Night's blue accent to Gruvbox's orange in plain RGB passes through a dull grey-brown in the middle. lyne fades in **OKLab**, a colour space designed so that equal steps look like equal changes. The maths is a few matrix multiplications:

@include lyne/services/color.js

::: walk
@ 5 | A library
`.pragma library` shares one copy of this file between every QML file that imports it, and keeps it free of any QML context. It's pure JavaScript.
@ 7-12 | Undoing the screen's curve
Colour values on screen aren't proportional to light: `0.5` is much darker than half of `1.0`. `toLinear` converts a channel to real light intensity, `toGamma` converts back. These are the standard sRGB formulas.
@ 14-26 | To OKLab
Linear RGB goes through two fixed matrices with a cube root in between (from the OKLab specification). The result is `L` (lightness), `a` (green ↔ red) and `b` (blue ↔ yellow), plus the alpha kept as is.
@ 28-40 | Back to RGB
The same steps in reverse. `clamp` keeps each channel between 0 and 1, because a mix can land just outside what a screen can show.
@ 42-45 | mix()
A straight line between two OKLab colours: each component moves the fraction `t` of the way. `t = 0` is the start colour, `t = 1` the end.
:::

## The theme service

@include lyne/services/ThemeService.qml

::: walk
@ 14-17 | Folders
Built-in themes are in the shell's `themes/` folder; yours go in `~/.local/themes`, which is also where lyne-dots keeps them. `kittyPath` is the file kitty includes.
@ 19-23 | All themes
`themes` maps a slug (the file name, like `tokyonight`) to its parsed contents. `list` is the same as an array sorted by name, ready for a picker; the Settings app draws a tile for each.
@ 25-27 | The current theme
The name comes from the state (`theme.name`), so choosing a theme is just `StateService.set("theme.name", …)`: it's saved, survives restarts, and editing `state.json` by hand works too. `current` updates when either the name or the list of themes changes.
@ 29-30 | The palette Config fades to
A separate property, so `Config` reacts only when a real palette arrives.
@ 32-34 | A switch for testing
With `LYNE_NO_EXPORT=1` in the environment, the shell still themes itself but doesn't write kitty's file or change GTK and Hyprland. Useful on a desktop you don't want touched.
@ 36-44 | Choosing
`set()` ignores names that don't exist. `step()` moves through the sorted list, wrapping around at both ends (`+ slugs.length` keeps the index positive going backwards).
@ 46-55 | When the theme changes
Publish the palette, then paint the rest of the desktop.
@ 57-66 | One process for all files
Starting a process per file would be slow, so one shell loop prints every file: its name, its contents, then the ASCII *record separator* character (`\036`), which never appears in JSON. Both folder paths are passed as arguments (`$1`, `$2`), never pasted into the command text.
@ 67-86 | Splitting the output
Cut at the separators; the first line of each chunk is the slug, the rest is JSON. A broken file is skipped with a warning instead of breaking theming. Your folder is read second, so a file of yours with a built-in's name replaces it.
@ 91-93 | Writing a file safely
`printf "%s" "$2" > "$1"` writes the text exactly, whatever characters it contains, because the text is an argument and not part of the command.
@ 95-112 | kitty
Turn the `terminal` section into kitty's format (`selection_background #283457`…), write it, then send `SIGUSR1` to every kitty: kitty reloads its config on that signal, so open terminals change colour at once. You add `include current-theme.conf` to `kitty.conf` once.
@ 114-125 | Hyprland's borders
lyne-dots configures Hyprland in **Lua**, where settings change with `hyprctl eval 'hl.config({ … })'`. A classic `hyprland.conf` uses `hyprctl keyword`. The script checks which kind of config you have and runs the matching command. Both strings travel as arguments.
@ 127-130 | GTK
`color-scheme` is the desktop-wide light/dark preference. GTK 4 apps, Firefox and many websites follow it.
@ 132-140 | From the terminal
`qs -c lyne ipc call theme set nord`, `… next`, `… list`, and `reload` after adding a theme file.
:::

> [!NOTE] In the original
> lyne's `ThemeService.qml` (about 1,000 lines) also writes a Neovim colour scheme and sends it to running editors, generates GTK CSS and a Qt/KDE colour scheme, fades Hyprland's borders inside Hyprland with an `hl.timer`, picks the light or dark twin of a theme, runs matugen for "Material You" themes from the wallpaper, and saves themes made in its theme creator.

## Config: the tokens

@include lyne/config/Config.qml

::: walk
@ 1-5 | A singleton in its own folder
`config/` is the `qs.config` module, imported by every widget. It reads from the services (`qs.services`) and uses `color.js` for the fade.
@ 13-15 | A short helper
`getState("bar.height", 33)` reads better than the full call, and there are dozens of them below.
@ 17-28 | Background and surfaces
Each colour is `_shown(role, fallback)`: the palette's colour for that role, mixed during a fade (explained below). The fallbacks are Tokyo Night, so the very first frame looks right before the theme files are read. `backgroundTransparentColor` combines the background with the opacity setting; cards use the same opacity so they don't look solid on a see-through panel.
@ 30-38 | Text and accents
The same pattern for every role in the palette.
@ 40-41 | The scrim
The dim layer behind the power menu and screenshot overlay is black in every theme, light ones included.
@ 43-48 | Geometry
Three corner radii (small for chips, normal, large for panels), the gap between items, and the padding inside them. Changing `geometry.radius` in Settings rounds the whole shell at once.
@ 50-66 | Bar tokens
The settings, plus values **derived** from them, so the arithmetic lives in one place: a floating bar has a margin, only the "corners" style has concave corners, the reserved height is bar plus margin, and islands and buttons are a little shorter than the bar.
@ 68-76 | Typography
One Nerd Font for text **and** icons: Nerd Fonts contain thousands of icon glyphs, so an icon is just a character (see `Icons` below).
@ 78-82 | Motion
Three durations used by every animation, short (100 ms), normal (200 ms) and long (400 ms). Set them to 0 in `state.json` and the whole shell stops animating.
@ 84-89 | Other modules
Notification and OSD settings used by more than one file.
@ 91-98 | The fade's state
`_target` is the palette being shown. During a fade, `_t` runs from 0 to 1, and `_fromLab`/`_toLab` hold each colour's start and end in OKLab. `themeTransitioning` lets widgets switch off their own colour animations during a fade, so two animations don't fight.
@ 100-106 | _shown()
After a fade (`_t` is 1), the target colour. During it, the mix of start and end at `_t`. Because every colour binding calls `_shown`, and `_shown` reads `_t`, animating `_t` re-evaluates every colour in the shell each frame: one animation drives hundreds of colours.
@ 108-115 | The first palette
On startup there's nothing to fade from, so the palette applies at once. So it does when the fade setting is off.
@ 116-121 | Where to start from
For each role, compute the end colour and the start colour. The start is what's **on screen right now**, so switching again mid-fade continues smoothly from wherever the colours are instead of jumping.
@ 122-127 | Go
Store both ends, show the new palette, reset `_t` to 0 and start the animation.
@ 130-134 | Listening to the theme service
The first palette at startup, then every new one.
@ 136-144 | The animation
Twice the "long" duration (800 ms by default), easing in and out.
:::

## Icons as text

@include lyne/config/Icons.qml

Nerd Fonts put icons in the "private use" area of Unicode. `"\u{f057e}"` is the volume icon (named `nf-md-volume_high` on nerdfonts.com/cheat-sheet). lyne writes these codes directly in its widgets; the rebuild names them once here so code reads `Icons.volumeHigh`. To add an icon, search the cheat sheet, copy its code, and add a line. `wifi` is a list from no signal to full, so a widget can pick `Icons.wifi[strength]`.

## Practice

::: exercise warm | Make a theme
Copy `tokyonight.json` to `~/.local/themes/mine.json`, change `name` and a few palette colours (try a pink accent), then `qs -c lyne ipc call theme reload` and `… theme set mine`.
:::

::: exercise practice | Slow-motion fade
Make the fade length a setting: add `animations.themeFade` (milliseconds) to `defaults.json` and use it for the fade's duration. Set it to 3000 and watch a theme switch.
--- solution
```qml
duration: root.getState("animations.themeFade", root.animDurationLong * 2)
```
:::

::: exercise practice | RGB versus OKLab
Temporarily change `Color.mix` to mix the RGB channels directly, then switch between Tokyo Night and Gruvbox with a 3-second fade. Compare the middle of the fade with the OKLab version.
:::

::: exercise challenge | Light/dark twin
Add `twin` to theme files (`"twin": "catppuccin-latte"` in Mocha) and a `toggleVariant()` that switches to it. Bind it over IPC.
:::
