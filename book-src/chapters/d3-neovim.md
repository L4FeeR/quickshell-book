# Desktop Ricing 3: Neovim

An editor is in half of all rice screenshots. This chapter builds a small, good-looking Neovim in one file: the Tokyo Night colour scheme with a **transparent background** (so the terminal's blur shows through), a statusline with rounded ends, a start screen, a fuzzy finder and indent guides.

<div class="preview"><svg width="560" height="240" viewBox="0 0 560 240"><rect width="560" height="240" rx="10" fill="#1a1b26" opacity=".9"/><g font-family="monospace" font-size="11"><text x="150" y="50" fill="#7aa2f7">┏┓╻┏━╸┏━┓╻ ╻╻┏┳┓</text><text x="150" y="64" fill="#7aa2f7">┃┗┫┣╸ ┃ ┃┃┏┛┃┃┃┃</text><text x="150" y="78" fill="#7aa2f7">╹ ╹┗━╸┗━┛┗┛ ╹╹ ╹</text><text x="170" y="112" fill="#c0caf5">  Find file          f</text><text x="170" y="130" fill="#c0caf5">  Recent             r</text><text x="170" y="148" fill="#c0caf5">  Config             c</text><text x="170" y="166" fill="#c0caf5">  Quit               q</text></g><path d="M10 212 h70 a9 9 0 0 1 0 18 h-70 a9 9 0 0 1 0 -18z" fill="#7aa2f7"/><text x="24" y="225" fill="#1a1b26" font-size="10" font-weight="700" font-family="monospace">NORMAL</text><rect x="90" y="212" width="380" height="18" fill="#24283b"/><text x="100" y="225" fill="#a9b1d6" font-size="10" font-family="monospace">init.lua   utf-8   lua</text><path d="M480 212 h60 a9 9 0 0 1 0 18 h-60z" fill="#7aa2f7"/><text x="490" y="225" fill="#1a1b26" font-size="10" font-family="monospace">12:4</text></svg></div>

@include desktop/nvim/init.lua

::: walk
@ 4-18 | Options
Space as the leader key, line numbers (relative, so `5j` is easy to read off), 24-bit colour (`termguicolors`, needed by every modern scheme), a highlighted cursor line, a sign column that never shifts the text, 8 lines of context when scrolling, 4-space indents, the system clipboard, one statusline for all splits, and no `~` on empty lines.
@ 20-26 | Installing lazy.nvim
lazy.nvim manages plugins. If it isn't there yet, clone it, then add it to the runtime path. On the first start it downloads every plugin below; after that, `:Lazy` shows and updates them.
@ 28-42 | The colour scheme
Tokyo Night, "night" style, with `transparent = true`: the editor draws no background, so the terminal's colour and blur show through, and the editor and terminal look like one surface. `priority = 1000` loads it before the other plugins, so they pick up its colours.
@ 44-60 | Statusline
lualine with the matching theme. The separators are Nerd Font half-circles, so the mode and position look like pills. `globalstatus` makes one statusline across splits.
@ 62-82 | Start screen
alpha-nvim's dashboard: an ASCII-art header (drawn with box characters) and four buttons with icons and keys.
@ 84-88 | Finder and guides
Telescope, the fuzzy finder (files, text, help…), and thin `│` indent guides.
@ 91-94 | Keys
Space f f finds files, Space f g searches text, Space e opens the file explorer.
:::

## Making it follow your shell's theme

A transparent background already ties the editor to the terminal's colours. To switch Neovim's scheme together with the shell:

- Write the scheme's name to a file on every theme switch (the exporter in [[ch:th7-beyond-the-shell]] writes `~/.config/nvim/lua/theme.lua` with a `vim.cmd.colorscheme(…)` line) and `require("theme")` at the end of `init.lua`.
- Running editors can be told to reload through their server socket: `nvim --server $sock --remote-send '<Cmd>colorscheme tokyonight<CR>'`. lyne-dots does this for every running Neovim (`ThemeService._applyNeovim`).

## A ready-made alternative

If you'd rather not build an editor config yourself, **LazyVim** (lazyvim.org) is a complete setup on top of lazy.nvim. Its colour scheme is set the same way (`{ "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } }`), and the transparency options above work there too.

## Checking a config safely

```bash
nvim -u ~/rice/nvim/init.lua      # try a config without replacing yours
nvim --headless "+Lazy! sync" +qa # install plugins without opening the UI
```

::: exercise warm | Your scheme
Swap Tokyo Night for your theme's Neovim port (catppuccin/nvim, rose-pine/neovim, ellisonleao/gruvbox.nvim…), keeping the transparent background.
:::

::: exercise practice | Your own header
Replace the dashboard header with your name in a figlet font (`figlet -f smslant yourname`).
:::
