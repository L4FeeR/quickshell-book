# Example shells from The Quickshell Book

| Folder | What it is | Chapters |
|---|---|---|
| `cae/` | A rebuild of the **Caelestia** shell: one frame per monitor with a vertical bar and drawers that slide out of the frame edges | `ch/cae1-overview.html` … `ch/cae9-assemble.html` |
| `galleryshell/` | Every **Widget Gallery** widget as its own file (about 100), plus `shell.qml`, which assembles them into a complete shell: bar, notifications, launcher, dock, lock screen, idle, polkit, wallpaper, OSDs and pickers | `ch/g1-bar-modules.html` … `ch/g10-full-shell.html` |
| `impulse/` | A rebuild of **end-4's illogical-impulse**: grouped top bar, sidebars, overview with live previews | `ch/ii1-overview.html` … `ch/ii9-assemble.html` |

`cae/` and `impulse/` are original code written for the book, following the architecture and design of the originals (both GPL-3.0: caelestia-dots/shell and end-4/dots-hyprland).

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
