# Desktop Ricing 9: GRUB Ricing

The boot menu is the first thing your machine shows, and on most installs it's a grey text list. GRUB can draw a full graphical menu with a background, icons for each system, a rounded highlight bar and a countdown bar. This chapter builds a complete theme, **generates all its pictures and fonts with a script**, and, most usefully, **previews it in a virtual machine** so you never have to reboot to see a change.

<div class="preview"><svg width="640" height="360" viewBox="0 0 640 360"><defs><radialGradient id="gb" cx="50%" cy="50%" r="70%"><stop offset="0" stop-color="#24283b"/><stop offset="1" stop-color="#16161e"/></radialGradient></defs><rect width="640" height="360" fill="url(#gb)"/><g fill="none" stroke="#292e42" stroke-width="1.5"><path d="M0 260 C160 233 320 293 640 253"/><path d="M0 277 C173 247 333 313 640 270"/><path d="M0 293 C187 263 347 330 640 287"/></g><circle cx="320" cy="72" r="18" fill="#7aa2f7"/><text x="320" y="78" fill="#1a1b26" font-size="16" text-anchor="middle" font-weight="700">A</text><text x="320" y="110" fill="#c0caf5" font-size="13" text-anchor="middle" font-weight="700">Choose a system</text><rect x="200" y="124" width="240" height="120" rx="10" fill="#1a1b26" opacity=".9"/><rect x="208" y="132" width="224" height="22" rx="6" fill="#7aa2f7"/><rect x="214" y="136" width="14" height="14" rx="4" fill="#1a1b26" opacity=".25"/><text x="236" y="147" fill="#1a1b26" font-size="10" font-weight="700">Arch Linux</text><rect x="214" y="164" width="14" height="14" rx="4" fill="#7aa2f7"/><text x="236" y="175" fill="#a9b1d6" font-size="10">Arch Linux (fallback initramfs)</text><rect x="214" y="190" width="14" height="14" rx="4" fill="#bb9af7"/><text x="236" y="201" fill="#a9b1d6" font-size="10">Windows Boot Manager</text><rect x="214" y="216" width="14" height="14" rx="4" fill="#292e42"/><text x="236" y="227" fill="#a9b1d6" font-size="10">UEFI Firmware Settings</text><rect x="200" y="272" width="240" height="14" rx="7" fill="#24283b"/><rect x="200" y="272" width="110" height="14" rx="7" fill="#bb9af7"/><text x="325" y="282" fill="#c0caf5" font-size="8">17s remaining</text><text x="320" y="342" fill="#545c7e" font-size="8" text-anchor="middle">Press enter to boot the selected OS, 'e' to edit the commands before booting or 'c' for a command-line.</text></svg></div>

*This is what the theme looks like booted in QEMU by `preview.sh` (redrawn here to keep the page light).*

## How GRUB themes work

A GRUB theme is a folder:

```text
tokyo/
├── theme.txt              the layout: what goes where, fonts, colours
├── background.png         the picture behind everything
├── logo.png               any extra picture you place
├── menu_*.png             nine pieces of the menu's panel
├── select_*.png           nine pieces of the highlight bar
├── progress_bar_*.png     nine pieces of the countdown's track …
├── progress_highlight_*.png   … and its fill
├── icons/arch.png …       one icon per menu entry "class"
└── *.pf2                  fonts, converted to GRUB's own format
```

GRUB is tiny and runs before your system, so it has strict rules. Knowing them saves hours:

| Rule | Why it matters |
|---|---|
| **PNGs must be plain 8-bit RGB or RGBA.** | Palette or 1-bit PNGs (what image tools write for small single-colour pictures) are silently ignored: the piece just doesn't appear. |
| **Fonts must be `.pf2` files**, made with `grub-mkfont`. | A font is referred to as "Family Style Size", which must match the name inside the file. |
| **Boxes are drawn from nine pieces** (`*_nw`, `_n`, `_ne`, `_w`, `_c`, `_e`, `_sw`, `_s`, `_se`). | Corners stay as they are, edges and the centre stretch. That's how a rounded box scales to any size. |
| **The highlight is drawn around the entry**, its corner pieces outside the entry's box. | Leave enough spacing between entries, or the bar overlaps the next one. |
| **Icons come from the entry's class**: `menuentry "Arch Linux" --class arch` uses `icons/arch.png`. | `grub-mkconfig` gives Arch entries the classes `arch`, `gnu-linux`, `os`; os-prober gives Windows `windows`. |

## The layout: theme.txt

@include desktop/grub/tokyo/theme.txt

**Global settings** (lines with a colon) apply to the whole screen: `title-text` (empty, because we draw our own title), `desktop-image` and `desktop-color`, and `terminal-font`/`terminal-box` for the command line you get by pressing `c`.

**Components** start with `+` and are placed with `left`, `top`, `width`, `height`. Values can be pixels (`720`), percentages of the screen (`32%`) or both (`50%-360`, which centres a 720-pixel box). That's how one theme works on any resolution.

| Component | Used here for | Key properties |
|---|---|---|
| `+ image` | the logo | `file` |
| `+ label` | the title, the key help | `text`, `font`, `color`, `align`; the text `@KEYMAP_MIDDLE@` becomes GRUB's key help |
| `+ boot_menu` | the list of systems | `item_font`, `item_color`, `selected_item_*`, `menu_pixmap_style`, `selected_item_pixmap_style`, icon size, heights and spacing |
| `+ progress_bar` | the countdown | `id = "__timeout__"` makes it count down the timeout; `bar_style` and `highlight_style` are its two nine-piece pictures; `@TIMEOUT_NOTIFICATION_MIDDLE@` becomes "17s remaining" |

Other components exist: `+ circular_progress` (a countdown ring made of tick pictures), `+ hbox`/`+ vbox` (rows and columns of components) and `+ canvas`.

The numbers here (an entry height of 40, spacing of 30) came from previewing: the first version with taller entries and less spacing made the highlight bar touch the next entry.

## Generating the pictures and fonts

Drawing 36 tiny pictures by hand would be tedious, so a script makes them all from the palette:

@include desktop/grub/make-assets.sh

- **Background**: ImageMagick draws a radial gradient from the surface colour to the darkest colour, then three soft wave lines. `PNG24:` forces plain 8-bit RGB.
- **`slice`**: draws one rounded square the size of two corners plus a two-pixel middle, then cuts it into the nine pieces GRUB expects. The `PNG32:` prefix on every piece is essential: without it, ImageMagick saves single-colour pieces as palette images, which GRUB ignores. (This was the bug in the first preview: the panel and highlight were simply missing.)
- **Four boxes**: the menu panel (slightly see-through, `e6` = 90% alpha), the highlight bar (smaller corners, because they're drawn outside the entry), and the countdown's track and fill.
- **Icons**: a rounded square in a palette colour with a Nerd Font glyph (Arch, CachyOS, Tux, Windows, a gear for firmware settings). Add more for your systems: `icon fedora "#7aa2f7" $''`.
- **Fonts**: `grub-mkfont -n Tokyo -s 18` converts a TTF into a 18-pixel PF2 named "Tokyo Regular 18"; `-b` makes the bold one ("Tokyo Bold 18"). Every size used in `theme.txt` needs its own file.

```bash
cd examples/desktop/grub
./make-assets.sh          # writes everything into tokyo/
```

## Previewing without rebooting

@include desktop/grub/preview.sh

This builds a tiny bootable image (with `grub-mkrescue`) containing your theme and four **fake** menu entries with the right classes, boots it in QEMU **without a window**, waits for GRUB to draw, and asks QEMU's monitor for a screenshot. Nothing on your machine is touched; the image is deleted afterwards.

```bash
sudo pacman -S --needed qemu-desktop xorriso mtools
./preview.sh tokyo grub-preview.png 1920x1080
```

Change `theme.txt` or the colours in `make-assets.sh`, run both scripts again, and look at the new screenshot: a theme loop of a few seconds instead of a reboot. If the picture is blank, GRUB hadn't finished drawing: raise the wait with `PREVIEW_WAIT=20 ./preview.sh`.

## Installing

@include desktop/grub/install.sh

It asks before doing anything, copies the theme to `/boot/grub/themes/`, **backs up** `/etc/default/grub`, sets `GRUB_THEME` and `GRUB_GFXMODE` (the screen mode: `auto`, or your monitor's resolution if the picture looks stretched), comments out `GRUB_TERMINAL_OUTPUT` (a text console setting there disables themes), and regenerates `grub.cfg`. `grub-mkconfig` also loads every `.pf2` in the theme folder for you.

```bash
./install.sh tokyo 1920x1080
```

> [!WARNING] Before you install
> Keep a live USB at hand. If GRUB shows a plain menu after installing, the theme failed to load (usually a wrong path or font name): it still boots normally. To undo, restore the backup (`sudo cp /etc/default/grub.bak-… /etc/default/grub`) and run `sudo grub-mkconfig -o /boot/grub/grub.cfg`. On systems using systemd-boot instead of GRUB (some CachyOS and EndeavourOS installs), there are no themes: `bootctl status` tells you which you have.

## Ready-made themes

Popular themes follow the same layout, so you can read and change them: catppuccin/grub, vinceliuice/grub2-themes (Tela, Vimix, Stylish), Jacksaur/CRT-Amber-GRUB-Theme. Most ship an install script; `preview.sh` works with any of them (`./preview.sh /path/to/theme`).

::: exercise warm | Your colours
Change the five colours at the top of `make-assets.sh` to your palette, rebuild and preview.
:::

::: exercise practice | Your wallpaper
Use your desktop wallpaper as the background: resize it to your screen (`magick wall.jpg -resize 1920x1080^ -gravity center -extent 1920x1080 -depth 8 PNG24:tokyo/background.png`) and darken it a little so the menu stays readable.
:::

::: exercise practice | A countdown ring
Replace the progress bar with `+ circular_progress { id = "__timeout__"; tick_bitmap = "tick.png"; center_bitmap = "ring.png"; num_ticks = 30; … }` and generate the two pictures in the script.
:::
