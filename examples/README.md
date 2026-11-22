# Example shells from The Quickshell Book

| Folder | What it is | Chapters |
|---|---|---|
| `cae/` | A rebuild of the **Caelestia** shell: one frame per monitor with a vertical bar and drawers that slide out of the frame edges | `ch/cae1-overview.html` … `ch/cae9-assemble.html` |
| `galleryshell/` | Every **Widget Gallery** widget as its own file (about 100), plus `shell.qml`, which assembles them into a complete shell: bar, notifications, launcher, dock, lock screen, idle, polkit, wallpaper, OSDs and pickers | `ch/g1-bar-modules.html` … `ch/g10-full-shell.html` |
| `lyne/` | A rebuild of **lyne-dots**: state.json settings, theme files with a colour fade, a bar with four styles, panels that grow out of it, launcher modes, notifications, OSD, lock, power menu, screenshots, wallpapers and a Settings app | `ch/ly1-overview.html` … `ch/ly13-rice-it.html` |
| `desktop/` | Configs for the rest of the rice in one palette: kitty, zsh, starship, fastfetch, btop, cava, Neovim, GTK/Qt, Hyprland (Lua and classic), a GRUB theme with an asset generator and a QEMU preview script, two SDDM themes in QML (a single-file one and a full multi-file one with a preview harness), Firefox, spicetify, Vencord, and a Stow installer | `ch/d0-overview.html` … `ch/d8-dotfiles.html` |
| `eyecandy/` | A Quickshell config with a cava audio visualizer (bars, wave, ring), synced lyrics from LRCLIB, album-art colours, a now-playing card, a music desktop, floating lyrics, a video wallpaper and a weather card | `ch/e0-overview.html` … `ch/e5-more.html` |
| `ripples/` | Reusable effects: click ripples clipped to any shape, typing ripples from the caret with a failure shockwave, squash-and-stretch presses, a stretchy pill, and particle snow, with a demo of every use | `ch/a6-ripples-snow.html` |
| `impulse/` | A rebuild of **end-4's illogical-impulse**: grouped top bar, sidebars, overview with live previews | `ch/ii1-overview.html` … `ch/ii9-assemble.html` |

`cae/`, `impulse/` and `lyne/` are original code written for the book, following the architecture and design of the originals (all GPL-3.0: caelestia-dots/shell, end-4/dots-hyprland and caioax/lyne-dots).

## Run

```bash
cp -r cae impulse ~/.config/quickshell/
qs -c cae        # or: qs -c impulse
```

Then add the keybinds from `extras/hyprland.conf` and the matugen template from `extras/`.

The gallery shell:

```bash
cp -r galleryshell ~/.config/quickshell/
qs -c galleryshell
```

and `source = ~/.config/quickshell/galleryshell/hyprland.conf` in your Hyprland config.

The book's chapters include these files directly, so editing a file here changes the book on the next build.
