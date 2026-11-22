# Desktop Ricing 1: The Terminal

The terminal is in nearly every rice screenshot, so it's where most ricing starts. This chapter configures **kitty**: font, padding, a see-through background with blur, a cursor that leaves a trail, pill-shaped tabs, and a colour file that your shell can rewrite on every theme switch.

<div class="preview"><svg width="560" height="220" viewBox="0 0 560 220"><rect width="560" height="220" fill="#414868"/><rect x="40" y="20" width="480" height="180" rx="12" fill="#1a1b26" opacity=".88"/><rect x="52" y="30" width="100" height="22" rx="11" fill="#7aa2f7"/><text x="64" y="45" fill="#16161e" font-size="11" font-weight="700"> 1: nvim </text><rect x="158" y="30" width="90" height="22" rx="11" fill="#292e42"/><text x="168" y="45" fill="#545c7e" font-size="11"> 2: zsh </text><g font-family="monospace" font-size="12"><text x="60" y="80" fill="#7aa2f7"> ~/src</text><text x="120" y="80" fill="#bb9af7"> main</text><text x="60" y="100" fill="#9ece6a">❯</text><text x="76" y="100" fill="#c0caf5">ls</text><text x="60" y="120" fill="#7aa2f7"> config</text><text x="150" y="120" fill="#7dcfff"> README.md</text><text x="270" y="120" fill="#e0af68"> install.sh</text><text x="60" y="140" fill="#9ece6a">❯</text><rect x="76" y="129" width="2" height="14" fill="#c0caf5"/><rect x="80" y="134" width="30" height="4" rx="2" fill="#c0caf5" opacity=".25"/></g><text x="300" y="190" fill="#a9b1d6" font-size="10">padding 14 · opacity 0.88 + blur · beam cursor with trail · round tabs</text></svg></div>

## kitty.conf

@include desktop/kitty/kitty.conf

Section by section:

**Font.** A Nerd Font, so prompts and file listings can show icons. `bold_font auto` lets kitty find the matching bold. `disable_ligatures cursor` keeps ligatures (`->` drawn as an arrow) except on the word under the cursor, so you can still edit them. List your fonts with `kitty +list-fonts`.

**Window.** `window_padding_width 14` is the single biggest visual improvement: text that doesn't touch the edges looks designed. `background_opacity 0.88` plus `background_blur 1` gives the frosted look; on Hyprland, the compositor's blur ([[ch:d5-hyprland-look]]) does the real work, so keep `decoration:blur` on. `hide_window_decorations` drops the title bar (Hyprland has no title bars anyway). `initial_window_width 100c` sizes new floating windows in **c**olumns.

**Cursor.** A thin beam that blinks. `cursor_trail` (kitty 0.37+) draws a short smear when the cursor jumps, a subtle effect people ask about in every screenshot thread. `cursor_trail_decay` sets how fast it fades.

**Tabs.** At the top, `powerline` style with `round` ends gives pill-shaped tabs. `tab_title_template` shows the tab number and the first 24 characters of the title. The tab colours come from the theme file.

**Behaviour.** `copy_on_select` copies selected text like X11 did, `url_style curly` underlines links with a wave, and `shell_integration` lets kitty jump between prompts (Ctrl+Shift+Z/X) and open new windows in the current folder.

**Keys.** `map` binds keys to kitty actions: new windows and tabs in the current directory, font size for all windows.

**Colours.** One `include` line. Colours live in their own file so a theme switch only rewrites that file.

## The colour file

@include desktop/kitty/current-theme.conf

A kitty colour file sets the background and foreground, selection, cursor, tab and border colours, then the **16 ANSI colours**: `color0`–`color7` are black, red, green, yellow, blue, magenta, cyan and white, and `color8`–`color15` are their bright versions. Programs that print "red" (`ls`, `git`, compilers) use these, so a good set matters as much as the background.

Getting one:

- **Built-in**: `kitty +kitten themes` opens a picker with hundreds of themes and writes `current-theme.conf` for you.
- **From your shell**: the theme services in [[ch:th7-beyond-the-shell]] and [[ch:ly3-config-theme]] write this exact file and send kitty `SIGUSR1`, which reloads every open window.
- **By hand**: copy the official port of your theme (most themes publish a kitty file).

## Reloading

Press **Ctrl+Shift+F5** in kitty, or run `pkill -USR1 kitty`, to reload the config in every window. Check a config without opening a window:

```bash
kitty +runpy "from kitty.config import load_config; load_config('$HOME/.config/kitty/kitty.conf')"
```

Unknown options are reported; no output means the file is fine.

## Other terminals

The same ideas, other syntax:

| | kitty | foot | Alacritty | WezTerm |
|---|---|---|---|---|
| config | `kitty.conf` | `foot.ini` | `alacritty.toml` | `wezterm.lua` |
| padding | `window_padding_width 14` | `pad=14x14` | `[window] padding = {x=14,y=14}` | `window_padding = {left=14,…}` |
| opacity | `background_opacity 0.88` | `[colors] alpha=0.88` | `[window] opacity = 0.88` | `window_background_opacity = 0.88` |
| colours | `include current-theme.conf` | `include=…` | `import = [...]` | `color_scheme = "…"` |

foot is the lightest (Wayland-only, starts instantly), kitty the most featureful (images, tabs, the trail), WezTerm the most programmable.

::: exercise warm | Make it yours
Change the font, the padding and the opacity until it looks right to you. Reload with Ctrl+Shift+F5 after each change.
:::

::: exercise practice | A floating terminal
Bind Super+Shift+Enter to `kitty --class floating-term` and add a Hyprland rule that floats and centres that class at 900×560 ([[ch:d5-hyprland-look]] shows rules).
:::

::: exercise practice | Images in the terminal
kitty can show pictures: `kitty +kitten icat ~/Pictures/wall.jpg`. Use it in fastfetch's logo ([[ch:d2-shell]]).
:::
