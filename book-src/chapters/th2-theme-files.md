# Theming 2: Theme Files and the 19 Built-in Themes

In this kit, a theme is **a JSON file**. To add a theme you add a file; no QML changes. This chapter explains the format line by line, using Catppuccin Mocha, then shows all 19 built-in themes with their palettes and role mappings.

```text
~/.config/quickshell/theming/themes/     built-in themes (shipped with the kit)
~/.config/theming/themes/                your own themes (same format; same id = replaces a built-in)
```

## Anatomy of a theme file

@include theming/themes/catppuccin-mocha.json

::: walk
@ 2 | id
A unique, lowercase, dash-separated name. It must match nothing else (or deliberately match a built-in to replace it). The switcher saves and finds themes by this id, so it's also what you type in `qs -c theming ipc call theme set catppuccin-mocha`.
@ 3 | name
What people see in the picker and the bar.
@ 4 | family
Themes from the same project share a family ("Catppuccin"). The picker sorts by family, and the light/dark toggle looks for a twin in the same family.
@ 5 | variant
`"dark"` or `"light"`. Used by the picker's filter, the light/dark toggle, and the GTK `color-scheme` export.
@ 6-7 | author and url
Credit for the theme's creators. Shown in the book's theme table; keep them when you share themes.
@ 8-35 | palette
The theme's **own** colours with the theme's **own** names, copied from the official source. You can include as many as you like; only the ones referenced in `roles` are used by the shell, but keeping the full palette makes the file a faithful copy and lets you remap roles later.
@ 36-54 | roles
The mapping from the 17 roles to palette names. `"background": "base"` means "the background role uses the palette colour called base". A role can also be a literal colour (`"textMuted": "#bfbfbf"`) when the palette has nothing suitable. If a role points to a name that doesn't exist, the shell shows bright pink (`#ff00ff`) so the mistake is obvious.
:::

That's the whole format. Optional extras:

- `"terminal": ["#…", … 16 colours]`: exact terminal colours, used instead of the ones derived from roles when exporting to kitty ([[ch:th7-beyond-the-shell]]).

## How each family was mapped

Mapping is the creative part of porting a theme. These are the choices made for the built-in themes, following each project's own guidance where it exists:

| Family | background / surface / raised | text / muted / faint | primary, secondary |
|---|---|---|---|
| **Catppuccin** | base / mantle / surface0 | text / subtext0 / overlay0 | mauve, blue (Catppuccin's suggested accent) |
| **Tokyo Night** | bg / bg_dark / bg_highlight | fg / fg_dark / comment | blue, magenta |
| **Gruvbox** | bg0 / bg0_h / bg1 | fg / fg4 / gray | orange, yellow |
| **Nord** | nord0 / nord1 / nord2 | nord6 / nord4 / nord3 | nord8 (frost), nord9 |
| **Dracula** | background / darker / current line | foreground / grey / comment | purple, pink |
| **Rosé Pine** | base / surface / overlay | text / subtle / muted | iris, rose |
| **Everforest** | bg0 / bg1 / bg2 | fg / grey1 / grey0 | green, aqua |
| **Kanagawa** | sumiInk3 / sumiInk2 / sumiInk4 | fujiWhite / oldWhite / fujiGray | crystalBlue, oniViolet |
| **One Dark** | bg / bg-dark / selection | fg / grey / comment | blue, purple |
| **Solarized** | base03 (base3 light) / slightly darker / base02 (base2) | base1 (base01) / base0 (base00) / base01 (base1) | blue, cyan |

> [!NOTE] Solarized's trick
> Solarized uses the **same 16 colours** for both variants and just swaps which "base" tones play background and text. You can see it in the two files: identical palettes, different roles. That's the palette/role idea at its clearest.

## All built-in themes

Each card below is generated from the theme file when the book is built: the header uses the theme's background, text and primary colours, the swatches are its complete palette, and "Role mapping" shows which palette colour plays each role.

{{THEME_TABLE}}

### Catppuccin: four flavours

Catppuccin has one light flavour (**Latte**) and three dark ones, from lightest to darkest: **Frappé**, **Macchiato**, **Mocha**. All four use the same 26 colour names with different values, so their files differ only in hex codes. Pick Mocha for maximum contrast, Frappé for a softer dark, Latte for daytime.

### Tokyo Night: four styles

**Night** (the classic, darkest), **Storm** (a slightly lighter blue-grey background), **Moon** (softer, more saturated accents), and **Day** (light). In the original Neovim theme, Night and Storm share their accent colours; Moon and Day have their own.

## Practice

::: exercise warm | Find the mauve
Open `catppuccin-latte.json`. What hex value does `primary` resolve to, and why is it so much darker than Mocha's?
--- solution
`primary` is `mauve`, which is `#8839ef` in Latte (Mocha: `#cba6f7`). On a light background, an accent needs to be darker to keep enough contrast for text and small details.
:::

::: exercise practice | Remap a theme
Make Catppuccin Mocha use **peach** as its primary accent instead of mauve. Copy the file to `~/.config/theming/themes/catppuccin-mocha.json` (same id replaces the built-in), change one line, and reload with `qs -c theming ipc call theme reload`.
--- solution
Change `"primary": "mauve"` to `"primary": "peach"`. Nothing else is needed: every widget uses the role, not the palette name.
:::

::: exercise practice | Spot the literal
Some built-in themes use a literal hex colour for a role instead of a palette name. Find them.
--- hint
`grep -l '"#' ~/.config/quickshell/theming/themes/*.json` lists files with hex values everywhere (the palettes); look inside each `roles` object instead.
--- solution
Dracula (`"textMuted": "#bfbfbf"`) and One Dark (`"textMuted": "#8b929e"`) have no suitable mid-grey in their palettes. Solarized also uses literal colours for `surface`, a slightly darker background tone than the official palette provides.
:::
