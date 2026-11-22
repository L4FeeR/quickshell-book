# Desktop Ricing 4: GTK, Qt, Icons, Cursors and Fonts

Open Files, Settings or a dialog in a fresh install and you get bright default themes that break the rice. Linux apps use two toolkits, **GTK** (GNOME apps, Firefox's dialogs, most small tools) and **Qt** (KDE apps, VLC, OBS…), and each is themed differently. This chapter themes both, plus icons, the cursor and fonts.

## GTK: the theme

GTK 3 apps use a theme you pick; GTK 4 / libadwaita apps (most new GNOME apps) mostly ignore themes and use their own style with **named colours** you can override. The trick that themes both: **adw-gtk3** (a GTK 3 theme that looks like libadwaita) plus a `gtk.css` that redefines the named colours for both.

```bash
sudo pacman -S adw-gtk-theme papirus-icon-theme nwg-look
yay -S bibata-cursor-theme            # or any cursor theme
```

@include desktop/gtk/settings.ini

The theme, icons, cursor and font for GTK 3 (copy the same file to `gtk-4.0/`). `gtk-decoration-layout=:` hides the minimise/maximise/close buttons, which a tiling compositor doesn't need.

GTK 4 apps read their settings from **gsettings** instead, so set them there too:

```bash
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface font-name 'Inter 11'
```

(`nwg-look` is a small GUI that writes both the file and gsettings for you.)

@include desktop/gtk/gtk.css

`@define-color` overrides libadwaita's named colours: the accent, window and view backgrounds, header bars, sidebars, cards, popovers and the semantic colours. Put the file in `~/.config/gtk-4.0/` and, for adw-gtk3, in `~/.config/gtk-3.0/` too. Every GTK app now uses your palette. The theming kit's exporter writes this file on every theme switch ([[ch:th7-beyond-the-shell]]).

## Qt

```bash
sudo pacman -S qt6ct qt5ct kvantum
```

@include desktop/qt/qt6ct.conf

Qt apps follow **qt6ct** (and **qt5ct** for Qt 5) when the environment variable `QT_QPA_PLATFORMTHEME=qt6ct` is set (the Hyprland file in [[ch:d5-hyprland-look]] sets it). qt6ct picks the widget style, icon theme and fonts. For colours, use the **Kvantum** style: open `kvantummanager`, install a Kvantum theme matching your palette (most popular themes publish one, like `Kvantum-Tokyo-Night`), select it, and set `style=kvantum-dark` as above.

KDE apps can also read a colour scheme file (`~/.local/share/color-schemes/*.colors`), which lyne-dots generates from its palette.

## Icons

**Papirus** is the most complete icon theme and comes in dark and light. Its folders can be recoloured to match your accent:

```bash
yay -S papirus-folders
papirus-folders -C indigo --theme Papirus-Dark
```

## Cursors

A cursor theme must be set in three places, because different programs read different settings:

| Who | Where |
|---|---|
| Hyprland and its native apps (hyprcursor) | `HYPRCURSOR_THEME`, `HYPRCURSOR_SIZE` env |
| XWayland and older apps | `XCURSOR_THEME`, `XCURSOR_SIZE` env |
| GTK apps | `gtk-cursor-theme-name` and gsettings `cursor-theme` |

Set all three to the same name and size, or the cursor changes as it moves between windows. Change it live with `hyprctl setcursor Bibata-Modern-Classic 24`.

## Fonts

```bash
sudo pacman -S inter-font ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk
```

Inter for interfaces, JetBrains Mono Nerd Font for code and icons, Noto as the fallback for every script and emoji. Check what an app will get with `fc-match sans-serif` and `fc-match monospace`. To make Inter the system's default sans font, add a `~/.config/fontconfig/fonts.conf` with `<alias><family>sans-serif</family><prefer><family>Inter</family></prefer></alias>`.

::: exercise warm | Check your apps
Open a GTK app (Files, `gnome-calculator`) and a Qt app (`dolphin`, `vlc`) and compare them with your bar. Fix whichever doesn't match.
:::

::: exercise practice | Light twin
Write a light version of `gtk.css` with your theme's light variant, and switch with `gsettings set org.gnome.desktop.interface color-scheme prefer-light`.
:::
