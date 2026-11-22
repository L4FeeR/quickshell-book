# Desktop Ricing 0: The Whole Rice

A shell is the centrepiece of a rice, but people judge a screenshot by **everything** in it: the terminal, the prompt, the fetch output, the editor, the file manager's colours, the cursor, the login screen. A great bar next to a default white GTK app looks unfinished. This part rices the rest of the desktop, one piece per chapter, all in **one palette** (Tokyo Night) so you can see how consistency is built.

<div class="preview"><svg width="640" height="360" viewBox="0 0 640 360"><rect width="640" height="360" fill="#16161e"/><rect x="0" y="0" width="640" height="26" fill="#1a1b26"/><rect x="20" y="40" width="300" height="200" rx="12" fill="#1a1b26" opacity=".92" stroke="#7aa2f7" stroke-width="2"/><g font-family="monospace" font-size="10"><text x="34" y="64" fill="#7aa2f7">  /\</text><text x="34" y="78" fill="#7aa2f7"> /  \</text><text x="34" y="92" fill="#7dcfff">/_--_\</text><text x="90" y="64" fill="#7aa2f7">󰀄 user</text><text x="140" y="64" fill="#c0caf5">you@arch</text><text x="90" y="78" fill="#7aa2f7">  wm</text><text x="140" y="78" fill="#c0caf5">Hyprland</text><text x="90" y="92" fill="#7aa2f7">  term</text><text x="140" y="92" fill="#c0caf5">kitty</text><text x="34" y="130" fill="#414868">╭─</text><text x="50" y="130" fill="#7aa2f7"> ~/src/rice</text><text x="140" y="130" fill="#bb9af7"> main</text><text x="34" y="144" fill="#414868">╰─</text><text x="50" y="144" fill="#9ece6a">❯</text></g><rect x="335" y="40" width="285" height="200" rx="12" fill="#1a1b26" opacity=".92" stroke="#414868" stroke-width="2"/><rect x="335" y="222" width="285" height="18" fill="#7aa2f7" opacity=".9"/><text x="345" y="235" fill="#1a1b26" font-size="10" font-family="monospace">NORMAL  init.lua</text><g font-family="monospace" font-size="10"><text x="350" y="64" fill="#545c7e">1</text><text x="366" y="64" fill="#bb9af7">local</text><text x="400" y="64" fill="#c0caf5">o = vim.opt</text><text x="350" y="78" fill="#545c7e">2</text><text x="366" y="78" fill="#c0caf5">o.number = </text><text x="434" y="78" fill="#ff9e64">true</text></g><rect x="20" y="255" width="600" height="90" rx="12" fill="#1a1b26" opacity=".92" stroke="#414868" stroke-width="2"/><rect x="20" y="255" width="600" height="24" rx="12" fill="#24283b"/><text x="40" y="272" fill="#c0caf5" font-size="11">Files — Downloads</text><rect x="40" y="290" width="40" height="40" rx="8" fill="#7aa2f7"/><rect x="95" y="290" width="40" height="40" rx="8" fill="#9ece6a"/><rect x="150" y="290" width="40" height="40" rx="8" fill="#bb9af7"/><text x="300" y="320" fill="#a9b1d6" font-size="11">GTK app in the same palette</text></svg></div>

## The pieces, and where they're configured

| Piece | Program | Config | Chapter |
|---|---|---|---|
| terminal | kitty | `~/.config/kitty/kitty.conf` | [[ch:d1-terminal]] |
| shell, prompt | zsh, starship | `~/.zshrc`, `~/.config/starship.toml` | [[ch:d2-shell]] |
| fetch, TUIs | fastfetch, btop, cava | `~/.config/fastfetch/`, `btop/`, `cava/` | [[ch:d2-shell]] |
| editor | Neovim | `~/.config/nvim/init.lua` | [[ch:d3-neovim]] |
| app theme, icons, cursor, fonts | GTK, Qt, Papirus, Bibata | `gtk-3.0/`, `gtk-4.0/`, `qt6ct/`, gsettings | [[ch:d4-gtk-qt]] |
| windows | Hyprland | `hyprland.lua` or `hyprland.conf` | [[ch:d5-hyprland-look]] |
| boot, login | GRUB, Plymouth, SDDM | `/etc/default/grub`, `/usr/share/sddm/themes/` | [[ch:d6-boot-login]] |
| apps | Firefox, Spotify, Discord | `userChrome.css`, spicetify, Vencord | [[ch:d7-apps]] |
| keeping it all | git + GNU Stow | a dotfiles repository | [[ch:d8-dotfiles]] |

Every file is in `examples/desktop/` in the download, already tested: zsh and Lua files pass syntax checks, the fastfetch config runs, kitty loads its config with no errors, and the SDDM theme loads in QML.

## Rules for a consistent rice

1. **One palette everywhere.** Pick a theme that has official ports (Catppuccin, Tokyo Night, Gruvbox, Nord, Rosé Pine…) so every app can match. Keep its colour values handy: background `#1a1b26`, surface `#24283b`, text `#c0caf5`, muted `#545c7e`, accent `#7aa2f7`, magenta `#bb9af7`, cyan `#7dcfff`, green `#9ece6a`, yellow `#e0af68`, red `#f7768e`.
2. **One accent.** The same blue for the active workspace, the focused border, the prompt's path, the editor's mode, the selected tab. A second colour (magenta) for small highlights only.
3. **Two fonts at most.** A Nerd Font for terminals, editors and icons (JetBrains Mono, CaskaydiaCove), a clean sans for the UI (Inter). Same sizes across apps.
4. **The same shape.** If the bar's corners are 12 px, windows, panels and the terminal's tabs should be round too, with similar radii. Same for gaps and padding.
5. **Transparency in one place.** Blur behind the terminal and the shell's panels looks great; blur behind everything looks messy. Let Hyprland blur, and keep apps mostly solid.
6. **Test in a scratch home first.** `HOME=/tmp/test kitty --config …` or `nvim -u test.lua` lets you try a config without breaking the one you use.
7. **Let your shell export colours.** The theming part ([[ch:th7-beyond-the-shell]]) and the lyne rebuild ([[ch:ly3-config-theme]]) write kitty, GTK and Hyprland colours on every theme switch. The files in this part are the **targets** those exporters write to.

## Back up first

Before replacing any config, keep a copy:

```bash
mkdir -p ~/rice-backup && cp -r ~/.config/{kitty,nvim,gtk-3.0,gtk-4.0,fastfetch,hypr} ~/.zshrc ~/rice-backup/ 2>/dev/null
```

[[ch:d8-dotfiles]] turns this into a proper git repository with an installer.

::: exercise warm | Pick your palette
Choose a theme for your rice and write its ten colours (background, surface, text, muted, accent and five accents) in a note. Every chapter in this part asks for them.
:::
