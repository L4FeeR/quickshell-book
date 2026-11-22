# Desktop Ricing 2: Shell, Prompt, Fetch and Terminal Apps

Inside the terminal: **zsh** with autosuggestions, syntax highlighting and fuzzy completion; a two-line **starship** prompt; **fastfetch** greeting you with a boxed system summary; and **btop** and **cava** dressed in the same colours.

<div class="preview"><svg width="560" height="200" viewBox="0 0 560 200"><rect width="560" height="200" rx="12" fill="#1a1b26"/><g font-family="monospace" font-size="12"><text x="20" y="34" fill="#414868">╭─</text><text x="40" y="34" fill="#7aa2f7"> ~/src/rice</text><text x="140" y="34" fill="#bb9af7"> main</text><text x="186" y="34" fill="#e0af68">!1</text><text x="440" y="34" fill="#e0af68"> 2.3s</text><text x="490" y="34" fill="#545c7e"> 14:58</text><text x="20" y="52" fill="#414868">╰─</text><text x="40" y="52" fill="#9ece6a">❯</text><text x="56" y="52" fill="#7dcfff">git</text><text x="84" y="52" fill="#c0caf5">commit -m "rice"</text><text x="216" y="52" fill="#545c7e"> --amend</text><text x="20" y="90" fill="#545c7e">autosuggestion in muted colour, valid commands in cyan, errors in red</text></g><g transform="translate(20 110)"><rect width="520" height="76" rx="8" fill="#16161e"/><g fill="#7aa2f7"><rect x="10" y="40" width="10" height="26" rx="2"/><rect x="24" y="26" width="10" height="40" rx="2" fill="#7dcfff"/><rect x="38" y="14" width="10" height="52" rx="2" fill="#bb9af7"/><rect x="52" y="30" width="10" height="36" rx="2"/><rect x="66" y="46" width="10" height="20" rx="2" fill="#7dcfff"/></g><text x="100" y="44" fill="#a9b1d6" font-size="11">cava and btop in the same gradient</text></g></svg></div>

## zsh

@include desktop/zsh/.zshrc

**History**: 50,000 lines, shared between open terminals, without duplicates. **Behaviour**: type a folder name to enter it; Emacs-style line editing.

**Completion**: `compinit` turns on zsh's completion system (`-C` skips a slow security check on every start). The `zstyle` lines give an arrow-key menu, case-insensitive matching and coloured file names.

**Plugins without a framework**: Oh My Zsh is popular but slow to start. The `plug` function clones a plugin from GitHub the first time and sources it every time after. Three plugins do most of the visible work:

| Plugin | What you see |
|---|---|
| zsh-autosuggestions | a faded suggestion from your history as you type; → accepts it |
| zsh-syntax-highlighting | commands turn cyan when valid, red when not, before you press Enter |
| fzf-tab | Tab completion in an fzf window you can type to filter |

**Modern tools**, each only if installed: `eza` (ls with icons and git status), `bat` (cat with colours), `zoxide` (`cd` that learns your folders: `cd rice` jumps to `~/src/rice`), `fzf` (Ctrl+R searches history, Ctrl+T finds files). `FZF_DEFAULT_OPTS` gives fzf the palette's colours and a rounded border.

**Prompt and greeting**: starship draws the prompt; fastfetch runs once when a terminal opens.

```bash
sudo pacman -S zsh starship fzf eza bat zoxide fastfetch
chsh -s /usr/bin/zsh
```

## The prompt: starship

@include desktop/starship/starship.toml

starship is one fast program that draws the prompt for any shell, configured in TOML.

- **`format`** lays out the whole prompt: a corner glyph, the OS icon, the folder, git branch and status, then `$fill` pushes the rest (command duration, language versions, time) to the right edge. The second line holds the `❯`.
- **`palette`** names colours once (`blue`, `muted`…) and every module refers to them: switching palettes recolours the whole prompt.
- **Modules**: `directory` shortens deep paths to the last three folders; `git_branch` and `git_status` show where you are; `cmd_duration` appears only for commands over 2 seconds; `python`/`nodejs`/`rust` appear only inside such projects; `character` turns the `❯` red after a failed command.
- **Symbols** are Nerd Font glyphs. Browse them at nerdfonts.com/cheat-sheet; `starship preset nerd-font-symbols -o ~/.config/starship.toml` writes a full set.

Test a change with `starship explain` (it lists every module in the current prompt and how long it took).

## fastfetch

@include desktop/fastfetch/config.jsonc

fastfetch prints system information next to a logo. This config:

- **`logo`**: a small Arch logo in blue and cyan with padding. Any built-in logo works (`fastfetch --print-logos`). For a picture, set `"type": "kitty"` and `"source": "~/Pictures/avatar.png"`; kitty draws the image (other terminals: `"type": "sixel"` or `"chafa"`).
- **`display`**: two spaces between key and value, keys in blue, all keys 12 characters wide so values line up.
- **`modules`**: what to show and in what order. The `custom` lines draw a box with Unicode corners (`\u001b[90m` is "grey" in ANSI escape codes). Each module gets a Nerd Font icon in its key. `colors` prints the palette as circles at the end.

Run `fastfetch -c ~/.config/fastfetch/config.jsonc` to test; `fastfetch --list-modules` shows the 80-odd modules (GPU, battery, packages, media, weather…).

## btop and cava

@include desktop/btop/themes/tokyonight.theme

btop themes are lists of `theme[name]="#colour"`. The `*_start`/`*_mid`/`*_end` triples are gradients for graphs. Put the file in `~/.config/btop/themes/`, then in `btop.conf` set `color_theme = "tokyonight"` and `theme_background = False` (so the terminal's transparency shows through).

@include desktop/cava/config

cava, the terminal audio visualizer: as many bars as fit, reading from PipeWire, with a four-colour vertical gradient and `monstercat` smoothing (gentle hills between bars). `sleep_timer` stops drawing after 3 seconds of silence. [[ch:e1-visualizer]] puts cava's data into your shell instead.

::: exercise warm | Your prompt
Change the starship palette to your theme's colours and add the `battery` module on the right.
:::

::: exercise practice | Fetch with a picture
Make fastfetch show your avatar (or a cropped wallpaper) in kitty, 18 lines tall.
--- hint
`"logo": { "type": "kitty", "source": "~/Pictures/me.png", "height": 18 }`
:::

::: exercise challenge | A prompt that follows the theme
Write starship's palette from your shell's theme service on every theme switch (one more exporter in [[ch:th7-beyond-the-shell]]'s style), then `exec zsh` in open terminals is not needed: starship reads its config on every prompt.
:::
