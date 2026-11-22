# Desktop Ricing 5: The Look of Hyprland

The compositor draws every window: their gaps, borders, corners, shadows, blur and every animation. This chapter shapes all of it, in Hyprland's **Lua** config (used by lyne-dots and newer setups) and the classic `hyprland.conf`.

<div class="preview"><svg width="560" height="230" viewBox="0 0 560 230"><defs><linearGradient id="hb" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7aa2f7"/><stop offset="1" stop-color="#bb9af7"/></linearGradient></defs><rect width="560" height="230" fill="#24283b"/><rect x="12" y="12" width="320" height="206" rx="12" fill="#1a1b26" stroke="url(#hb)" stroke-width="2"/><rect x="344" y="12" width="204" height="97" rx="12" fill="#1a1b26" opacity=".94" stroke="#414868" stroke-width="2"/><rect x="344" y="121" width="204" height="97" rx="12" fill="#1a1b26" opacity=".94" stroke="#414868" stroke-width="2"/><g font-size="10" fill="#a9b1d6"><text x="30" y="40">focused: gradient border</text><text x="360" y="40">unfocused: 94% opacity</text><text x="30" y="200">gaps_in 5 · gaps_out 12 · rounding 12</text></g></svg></div>

@include desktop/hypr/look.lua

::: walk
@ 4-9 | Environment
`hl.env` sets environment variables for everything Hyprland starts: the cursor theme for hyprcursor and XCursor ([[ch:d4-gtk-qt]]), and `qt6ct` for Qt apps.
@ 11-22 | Gaps and borders
`gaps_in` between windows, `gaps_out` to the screen edge. Two colours with an angle make a **gradient border** on the focused window; unfocused windows get a dim, semi-transparent border. Colours are `rgba(rrggbbaa)`.
@ 24-29 | Corners and opacity
`rounding` in pixels. `rounding_power` 2 draws circular corners; higher values give a smoother "squircle" like Apple's icons. Unfocused windows fade to 94%, which shows at a glance which window has focus.
@ 31-37 | Shadows
A soft shadow under every window: its reach, how quickly it fades (`render_power`), an offset downward, and a translucent black.
@ 39-48 | Blur
Blur behind see-through windows (the terminal) and popups. Bigger `size` and more `passes` are smoother but cost GPU time; 8 and 3 is a good balance. A touch of `noise` looks like frosted glass, `vibrancy` keeps colours saturated through the blur.
@ 51-55 | Small things
Animations on, and no Hyprland wallpaper or splash text behind your own wallpaper.
@ 58-63 | Curves
A bezier curve is four numbers, like CSS `cubic-bezier`: two control points. `easeOut` starts fast and settles; `overshot` goes past the end (y 1.1) and comes back, a small bounce; `smoothOut` pulls back before leaving.
@ 65-71 | Animations
Each animation (a "leaf" in Hyprland's tree) gets a speed (higher is slower: tenths of a second), a curve and a style. Windows pop in from 80% with a little bounce, fade and shrink when closing, workspaces slide with a fade, borders change colour smoothly.
@ 73-81 | Rules
Small tools (volume, network, Bluetooth, calculator) float and centre at a fixed size. Picture-in-picture videos float and stay on every workspace (`pin`). kitty is slightly see-through, focused or not (`opacity` takes active and inactive values).
:::

Use it with `require("look")` in `hyprland.lua` (after copying it to `~/.config/hypr/look.lua`). Hyprland reloads on save; errors appear at the top of the screen and in `hyprctl configerrors`.

## The classic version

@include desktop/hypr/look.conf

The same settings in `hyprland.conf` syntax: sections in braces, `bezier = name, x1, y1, x2, y2`, `animation = leaf, on, speed, curve, style`, and window rules as one line each (`windowrule = rule, match`). Add `source = ~/.config/hypr/look.conf` to your `hyprland.conf`.

## Layer rules for your shell

Your Quickshell bar and panels are **layers**, not windows, so they get **layer rules**: `blur` and `ignore_alpha` (don't blur fully transparent pixels around rounded panels). Every shell in this book sets a namespace on its windows for this; see [[ch:ly12-assemble]] for a full set.

## Tuning tips

- Bigger gaps feel airy, small gaps feel dense; match the bar's margin to `gaps_out` so everything lines up.
- Keep `rounding` close to your shell's large radius token.
- If animations feel slow, lower the speed numbers; if windows "jump", use an `easeOut` curve rather than linear.
- Blur costs the most GPU: on a laptop, `passes = 2` and `size = 6` are nearly as nice.

::: exercise warm | Find your numbers
Change gaps, rounding and border size live with `hyprctl keyword decoration:rounding 16` (classic) until you like them, then write them down.
:::

::: exercise practice | Special-workspace slide
Give the special workspace (the scratchpad) its own vertical slide: `animation = specialWorkspace, 1, 4, easeOut, slidevert`.
:::
