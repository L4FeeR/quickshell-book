# Installing Quickshell and Your Toolbox

## Installing Quickshell

| Distro | Command |
|---|---|
| Arch, CachyOS, EndeavourOS | `sudo pacman -S quickshell` (stable) or `paru -S quickshell-git` (newest) |
| Fedora | `sudo dnf copr enable errornointernet/quickshell` then `sudo dnf install quickshell` |
| NixOS | add `pkgs.quickshell` to `environment.systemPackages`, or use the upstream flake |
| Gentoo | GURU overlay, `gui-apps/quickshell` |
| Anything else | build from source with CMake and Qt ≥ 6.6 (see the repo's `BUILD.md`) |

Check it works:

```bash
qs --version
# quickshell 0.3.x …
```

`quickshell` and `qs` are the same program; this book writes `qs`.

> [!NOTE] Forks: noctalia-qs and others
> Some shells ship their own build of Quickshell. For example, **noctalia-qs** (used by the Noctalia shell) is a fork that adds extra modules such as `Quickshell.Niri` and `Quickshell.DWL`. A fork replaces the `qs` binary, so you can only have one installed at a time. Everything in this book works on upstream Quickshell. Types marked **"noctalia-qs fork only"** in the API reference need that fork. Check what you have with `pacman -Qo $(which qs)`.

## Fonts

Install at least one good UI font, one monospace font and one icon font:

```bash
# UI + mono fonts
sudo pacman -S inter-font ttf-jetbrains-mono-nerd ttf-roboto noto-fonts noto-fonts-emoji

# Material Symbols (the icon font end-4, Caelestia and most M3 rices use)
paru -S ttf-material-symbols-variable-git
fc-list | grep -i "material symbols"     # should list Rounded / Outlined / Sharp
```

## Icon theme

App icons in launchers, docks and trays come from an icon theme:

```bash
sudo pacman -S papirus-icon-theme
```

You'll tell Quickshell which theme to use with a pragma in [[ch:29-shell-structure]].

## Qt modules

Your distro's `quickshell` package pulls in what it needs, but rices commonly use a few extra Qt modules:

```bash
sudo pacman -S qt6-declarative qt6-svg qt6-imageformats qt6-multimedia qt6-5compat qt6-wayland
```

| Module | Why you might need it |
|---|---|
| `qt6-svg` | SVG icons and images |
| `qt6-imageformats` | WebP, TIFF and other wallpaper formats |
| `qt6-multimedia` | Video wallpapers, playing sounds |
| `qt6-5compat` | `Qt5Compat.GraphicalEffects`, used by older configs |

## Helper tools used in this book

None of these are required to learn, but the projects use them:

| Tool | Package (Arch) | Used for |
|---|---|---|
| `brightnessctl` | `brightnessctl` | Change screen brightness |
| `wpctl` | `wireplumber` | Change volume from keybinds |
| `playerctl` | `playerctl` | Media keys |
| `nmcli` | `networkmanager` | Wi-Fi (if you don't use the Networking module) |
| `bluez` | `bluez bluez-utils` | Bluetooth |
| `upower` | `upower` | Battery |
| `powerprofilesctl` | `power-profiles-daemon` | Power profiles |
| `cliphist`, `wl-copy` | `cliphist wl-clipboard` | Clipboard history |
| `grim`, `slurp` | `grim slurp` | Screenshots |
| `matugen` | `matugen` (AUR or extra) | Generate colors from your wallpaper |
| `qalc` | `libqalculate` | Calculator in the launcher |
| `hyprsunset` / `wlsunset` | `hyprsunset` | Night light |

```bash
sudo pacman -S brightnessctl wireplumber playerctl networkmanager bluez bluez-utils upower \
               power-profiles-daemon cliphist wl-clipboard grim slurp libqalculate
paru -S matugen-bin
```

## Make sure services are running

```bash
systemctl --user status pipewire wireplumber     # audio
systemctl status upower                          # battery
systemctl status NetworkManager                  # network
systemctl status bluetooth                       # bluetooth (enable: sudo systemctl enable --now bluetooth)
```

## Stop the things Quickshell will replace

Only one program can be the notification daemon, and two bars would overlap. While learning you can keep your old setup running and build in a separate config. When you switch over, remove these from your compositor's autostart:

```bash
pkill waybar; pkill dunst; pkill mako; pkill swaync
```

> [!TIP] Learn safely
> You can run Quickshell **next to** your existing bar. Your experiments live in `~/.config/quickshell/<name>/` and start with `qs -c <name>`. Nothing changes permanently until you edit your compositor's autostart.

## Practice

::: exercise warm | Check the install
Print Quickshell's version and list the configs it can see.
--- solution
```bash
qs --version
qs list --all
```
If `qs` isn't found, the package isn't installed or isn't on your `PATH`.
:::

::: exercise practice | Run a named config
Create a config called `hello` with a `shell.qml` that only contains `import Quickshell` and `ShellRoot {}`, then start it by name.
--- solution
```bash
mkdir -p ~/.config/quickshell/hello
printf 'import Quickshell\nShellRoot {}\n' > ~/.config/quickshell/hello/shell.qml
qs -c hello
```
Nothing appears (an empty shell), but no errors means everything works.
:::

::: exercise challenge | Fonts and icons
Install a Nerd Font or Material Symbols font, then confirm with `fc-list` that the system sees it.
--- solution
```bash
fc-list | grep -i "material symbols"
fc-list | grep -i "nerd"
```
If nothing prints, the font isn't installed in a folder fontconfig scans (`~/.local/share/fonts` works; run `fc-cache -f` afterwards).
:::
