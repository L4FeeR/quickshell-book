# Linux Survival Kit for Ricers

Ricing means living in config files and the terminal. This chapter teaches exactly the Linux you need, nothing more. If you already know `cd`, `~/.config`, `chmod +x` and environment variables, skim the headings and move on.

## The terminal in five minutes

The terminal runs a **terminal shell** (bash, zsh or fish), a program that reads commands you type. A command is a program name followed by **arguments**:

```bash
ls -la ~/.config
# ^   ^    ^
# |   |    └── argument: which folder
# |   └─────── option (flag): -l long format, -a show hidden files
# └─────────── program: list files
```

Commands you'll use constantly:

| Command | Does | Example |
|---|---|---|
| `pwd` | Print the folder you're in | `pwd` |
| `cd DIR` | Change folder (`cd` alone = home, `cd -` = back) | `cd ~/.config/quickshell` |
| `ls` | List files (`-a` hidden, `-l` details) | `ls -la` |
| `mkdir -p DIR` | Make a folder (and its parents) | `mkdir -p ~/.config/quickshell/bar` |
| `cp SRC DST` | Copy (`-r` for folders) | `cp -r myshell myshell.bak` |
| `mv SRC DST` | Move or rename | `mv old.qml New.qml` |
| `rm FILE` | Delete (`-r` folders). There's **no trash**! | `rm test.qml` |
| `cat FILE` | Print a file | `cat /sys/class/power_supply/BAT0/capacity` |
| `less FILE` | Scroll through a file (<kbd>q</kbd> quits) | `less ~/.config/hypr/hyprland.conf` |
| `nano FILE` | Simple terminal editor (<kbd>Ctrl</kbd>+<kbd>O</kbd> save, <kbd>Ctrl</kbd>+<kbd>X</kbd> exit) | `nano shell.qml` |
| `grep TEXT FILE` | Find lines containing text (`-r` recursive) | `grep -r "PanelWindow" ~/.config/quickshell` |
| `which CMD` | Where is a program? Is it installed? | `which matugen` |
| `man CMD` | Manual page | `man brightnessctl` |
| `CMD --help` | Short help | `qs --help` |

Handy keys: <kbd>Tab</kbd> autocompletes names, <kbd>↑</kbd> recalls previous commands, <kbd>Ctrl</kbd>+<kbd>C</kbd> stops the running command, <kbd>Ctrl</kbd>+<kbd>R</kbd> searches history.

## Paths: where things live

A **path** is an address of a file. `/` is the root of everything. `~` is shorthand for your home folder (`/home/yourname`).

- **Absolute path** starts with `/`: `/usr/share/icons`
- **Relative path** starts from where you are: `modules/bar/Bar.qml`
- `.` means "this folder", `..` means "parent folder"
- Files starting with `.` are **hidden** (`~/.config` is hidden; use `ls -a`)

The folders that matter for ricing:

| Path | What's there |
|---|---|
| `~/.config/` | Per-user configuration. **Your rice lives here.** |
| `~/.config/quickshell/` | Quickshell configs |
| `~/.config/hypr/` | Hyprland config (`hyprland.conf` or Lua config) |
| `~/.local/share/` | Per-user data (fonts in `fonts/`, icons in `icons/`, app files) |
| `~/.local/state/` | Per-user state (history, last-used things) |
| `~/.cache/` | Throwaway cache (generated colors, thumbnails) |
| `/usr/share/applications/` | `.desktop` files: the list of installed apps |
| `/usr/share/icons/` | Icon themes |
| `/usr/share/fonts/` | System fonts |
| `/sys/class/backlight/` | Screen brightness (read/write numbers) |
| `/sys/class/power_supply/` | Battery and charger info |
| `/proc/` | Live kernel info: `/proc/meminfo` (RAM), `/proc/stat` (CPU) |
| `/etc/` | System-wide config (needs root to edit) |
| `/run/user/1000/` (`$XDG_RUNTIME_DIR`) | Sockets for your session (Hyprland's IPC lives here) |

> [!TIP] The XDG folders
> `~/.config`, `~/.local/share`, `~/.local/state` and `~/.cache` are the **XDG base directories**. Quickshell gives you helpers to build paths inside them for your shell: [[Quickshell.dataPath()]], [[Quickshell.statePath()]], [[Quickshell.cachePath()]].

## Files, permissions and scripts

Every file has an owner and permissions: **r**ead, **w**rite, e**x**ecute. To run a script you wrote, it must be executable:

```bash
nano ~/.config/quickshell/myshell/scripts/hello.sh   # write the script
chmod +x ~/.config/quickshell/myshell/scripts/hello.sh  # make it executable
~/.config/quickshell/myshell/scripts/hello.sh           # run it
```

A shell script starts with a **shebang** line that says which interpreter runs it:

```bash file="scripts/hello.sh"
#!/usr/bin/env bash
echo "Hello from a script. You passed: $1"
```

`sudo` runs a command as root (administrator). You need it to install packages or edit files in `/etc`, and almost **never** for ricing your own config. If you find yourself writing `sudo` inside your Quickshell config, stop and rethink.

## Packages

On Arch-based systems (Arch, CachyOS, EndeavourOS, Garuda):

```bash
sudo pacman -Syu                 # update everything
sudo pacman -S brightnessctl     # install a package from the official repos
pacman -Ss matugen               # search
pacman -Qi quickshell            # info about an installed package
paru -S quickshell-git           # install from the AUR (needs an AUR helper: paru or yay)
```

Other distros: `apt` (Debian/Ubuntu), `dnf` (Fedora), `zypper` (openSUSE), `nix` (NixOS). The package names in this book are Arch names; search your distro if one differs.

## Processes

A **process** is a running program. Your Quickshell config runs as a process, and it can start other processes (that's what [[Process]] does).

```bash
pgrep -a qs              # is Quickshell running? shows PID + command
pkill qs                 # stop it (sends SIGTERM)
kill -9 12345            # force-kill PID 12345 (last resort)
top                      # live CPU/RAM per process (q to quit); htop/btop are nicer
```

Every process has:

- **arguments** (the command line),
- **standard output** (*stdout*), where it prints normal text,
- **standard error** (*stderr*), where it prints errors,
- **standard input** (*stdin*), where it can read text,
- an **exit code**: `0` means success, anything else means failure.

When Quickshell runs a command for your bar, it reads its stdout. That's how you'll get CPU usage, Wi-Fi names and more.

### Pipes
The `|` symbol sends one command's output into another's input:

```bash
cat /proc/meminfo | grep MemAvailable      # just the line we want
nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes'   # the connected Wi-Fi network
```

Pipes are a feature of the terminal shell, not of programs. To use them from Quickshell you must run them through `sh -c "…"` (covered in [[ch:37-processes]]).

## Environment variables

Variables that every process inherits, used for settings:

```bash
echo $HOME                       # /home/you
echo $XDG_RUNTIME_DIR            # /run/user/1000
echo $HYPRLAND_INSTANCE_SIGNATURE   # set when running under Hyprland
echo $WAYLAND_DISPLAY            # wayland-1
env | less                       # all of them
MYVAR=hello qs                   # run qs with an extra variable
```

In QML you read them with [[Quickshell.env()]]: `Quickshell.env("HOME")`.

## D-Bus, briefly

You'll rarely use D-Bus directly (Quickshell's services hide it), but knowing it exists helps with debugging:

```bash
busctl --user list | grep -i mpris        # which media players are running?
playerctl -l                              # same, friendlier (MPRIS)
busctl --user tree org.freedesktop.Notifications   # who owns the notification name?
```

There are two buses: the **session bus** (your user's programs: media players, notifications, tray) and the **system bus** (system services: UPower, NetworkManager, BlueZ).

## systemd user services

Many desktop pieces run as **systemd user services**. Useful commands:

```bash
systemctl --user status pipewire wireplumber    # audio stack OK?
systemctl status upower NetworkManager bluetooth # system services OK?
systemctl --user restart wireplumber            # fix weird audio states
journalctl --user -b -u pipewire                # logs of a user service this boot
```

You can even run Quickshell itself as a user service, covered in [[ch:71-sharing]].

## Your compositor's config

You'll edit your compositor's config to start Quickshell and add keybinds. Locations:

| Compositor | Config file | Reload |
|---|---|---|
| Hyprland | `~/.config/hypr/hyprland.conf` (newer versions also accept a Lua config) | auto on save, or `hyprctl reload` |
| Sway | `~/.config/sway/config` | `swaymsg reload` |
| niri | `~/.config/niri/config.kdl` | auto on save |
| river | `~/.config/river/init` | restart |

Each has a command-line tool for querying and controlling it: `hyprctl`, `swaymsg`, `niri msg`, `riverctl`. Try `hyprctl monitors` or `niri msg outputs` to see your screens.

## Fonts and icons

Text and icons are a huge part of a rice.

```bash
fc-list | grep -i "jetbrains"        # is a font installed? what is its exact family name?
fc-list : family | sort -u | less    # all font family names
fc-cache -fv                         # refresh after copying fonts into ~/.local/share/fonts
```

The **family name** printed by `fc-list` is exactly what you write in QML's `font.family`. Icons come from **icon themes** (Papirus, Adwaita, Tela…) in `/usr/share/icons` or `~/.local/share/icons`, and from **icon fonts** like Material Symbols or Nerd Fonts. [[ch:27-fonts-icons]] covers both.

## Backups and git

Before big changes, copy your config:

```bash
cp -r ~/.config/quickshell/myshell ~/.config/quickshell/myshell.bak-$(date +%F)
```

Better: put it under **git**, so every working state is saved and you can always go back:

```bash
cd ~/.config/quickshell/myshell
git init
git add -A && git commit -m "bar works"
# … later, after breaking something:
git diff            # what changed?
git checkout -- .   # throw away uncommitted changes
```

## Practice

::: exercise warm | Find your config folder
In a terminal, go to your home folder, list hidden files, and check whether `~/.config/quickshell` exists.
--- solution
```bash
cd ~
ls -a
ls ~/.config/quickshell 2>/dev/null || echo "not created yet"
```
:::

::: exercise practice | Make the folder tree
Create `~/.config/quickshell/playground/` with a `widgets` subfolder and an empty `shell.qml`, in **one** `mkdir` and one `touch` command.
--- hint
`mkdir -p` creates parent folders as needed.
--- solution
```bash
mkdir -p ~/.config/quickshell/playground/widgets
touch ~/.config/quickshell/playground/shell.qml
```
:::

::: exercise practice | Read command output
Find out three things with commands: your CPU model, how much RAM is free, and your battery percentage (if you have one).
--- solution
```bash
grep -m1 "model name" /proc/cpuinfo
free -h
cat /sys/class/power_supply/BAT*/capacity
```
These are exactly the kinds of files and commands a shell widget reads later (see [[ch:37-processes]]).
:::

::: exercise challenge | Pipes
Print the names of your 5 most memory-hungry processes, one per line, without the header.
--- hint
`ps -eo comm --sort=-%mem` sorts by memory; `head` and `tail` trim lines.
--- solution
```bash
ps -eo comm --sort=-%mem | tail -n +2 | head -5
```
:::
