# Desktop Ricing 8: Keeping and Sharing Your Dotfiles

A rice is dozens of config files scattered over your home folder. Put them in **one git repository**, link them into place with **GNU Stow**, and you can rebuild your desktop on a new machine in a minute, roll back a bad change, and share it.

## The layout

Stow links folders into your home folder. Each **package** is a folder that mirrors the home folder's structure:

```text
~/dotfiles/
├── install.sh
├── README.md
├── kitty/.config/kitty/kitty.conf
├── kitty/.config/kitty/current-theme.conf
├── zsh/.zshrc
├── starship/.config/starship.toml
├── fastfetch/.config/fastfetch/config.jsonc
├── nvim/.config/nvim/init.lua
├── hypr/.config/hypr/hyprland.lua
├── quickshell/.config/quickshell/myshell/…
└── gtk/.config/gtk-4.0/gtk.css
```

`stow kitty` (run inside `~/dotfiles`) creates `~/.config/kitty/kitty.conf` as a **link** to `~/dotfiles/kitty/.config/kitty/kitty.conf`. Edit the file in either place; it's the same file, and git sees the change.

## An installer

@include desktop/dotfiles/install.sh

- `set -euo pipefail` stops on the first error.
- Without arguments, every folder is a package; with arguments, only those.
- Stow refuses to replace real files, so for each file in a package the script first **moves** an existing real file into a dated backup folder (never deletes it).
- `stow --restow` links the package (and fixes links after you add files).

```bash
git clone https://github.com/you/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh          # or ./install.sh kitty nvim
```

(It needs `stow`: `sudo pacman -S stow`. lyne-dots' installer is the same idea, grown up: package categories, a review screen and a progress bar, [[ch:ly13-rice-it]].)

## What not to commit

- **Secrets**: API keys, tokens, `.netrc`, SSH keys. Keep them in files the repository ignores (`.gitignore`) or in a password manager.
- **Machine-specific files**: monitor layouts, GPU settings. Put them in a `local/` file your config includes, and ignore it (lyne-dots does this with `~/.config/hypr/local/`).
- **Generated files**: caches, `state.json`-style runtime files, `current-theme.conf` if your shell writes it.

## Sharing: the screenshot and the README

r/unixporn and similar communities have simple rules: a screenshot, and the details in a comment. A good post:

1. **A clean screenshot**: a few windows that show the rice (terminal with fastfetch, editor, the launcher or a panel open), nothing personal on screen. `grim` takes it; `hyprshot -m output` too.
2. **The details**:

```text
[Hyprland] Tokyo nights
• WM: Hyprland (Lua config)        • Shell: Quickshell (my own, based on lyne-dots)
• Terminal: kitty                  • Prompt: starship
• Editor: Neovim (tokyonight)      • Fetch: fastfetch
• GTK: adw-gtk3 + custom gtk.css   • Icons: Papirus-Dark   • Cursor: Bibata
• Font: Inter, JetBrains Mono Nerd Font
• Wallpaper: [link]                • Dotfiles: github.com/you/dotfiles
```

3. **The README** of your repository: a screenshot at the top, the list above, what to install, `./install.sh`, keybinds, and credits for anything you based your work on (licences matter: the shells rebuilt in this book are GPL-3.0, so credit and keep the licence if you publish modified versions of their code).

::: exercise practice | Your repository
Create `~/dotfiles`, move three configs into packages, run the installer, and commit.
:::

::: exercise project | The full rice
Rice everything from this part in one palette: terminal, prompt, fetch, editor, GTK and Qt apps, cursor, Hyprland, one of the three apps, and the login screen. Put it all in your dotfiles repository with a README and a screenshot.
:::
