# Sharing and Maintaining Your Rice

Your shell works. Now make it easy to keep running, to restore on a new machine, and to share with others.

## Run it reliably

### From the compositor (simplest)
```ini file="hyprland.conf"
exec-once = qs -c myshell
```

### As a systemd user service (auto-restart on crash)
```ini file="~/.config/systemd/user/myshell.service"
[Unit]
Description=My Quickshell shell
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=/usr/bin/qs -c myshell
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now myshell.service
journalctl --user -u myshell -f          # logs
```

This requires your compositor to start `graphical-session.target` (UWSM does; with plain Hyprland add `exec-once = systemctl --user start graphical-session.target` or use `uwsm`).

## Version control

```bash
cd ~/.config/quickshell/myshell
git init
cat > .gitignore <<'EOF'
.qmlls.ini
*.qsb
EOF
git add -A && git commit -m "my shell"
```

Commit small, working steps. When something breaks, `git diff` shows what changed and `git stash` gets you back to a working state instantly.

## Dotfiles layout

```text
~/dotfiles/
├── quickshell/myshell/      → ~/.config/quickshell/myshell
├── hypr/                    → ~/.config/hypr
├── matugen/                 → ~/.config/matugen
├── kitty/                   → ~/.config/kitty
└── install.sh
```

Use symlinks (`ln -s`) or GNU Stow (`stow -t ~ quickshell`) to put them in place.

## Make it work on other machines

- **No hard-coded paths or names.** Use `Quickshell.env("HOME")`, `Quickshell.shellPath()`, `Quickshell.statePath()`, and read monitor names, wallpaper folders and the terminal from Config.
- **Defaults for everything** in JsonAdapter, so a fresh install runs without a config file.
- **Graceful degradation:** hide modules whose service isn't available (`Battery.available`, `Networking.backend`, `Bluetooth.defaultAdapter !== null`, `Brightness.available`).
- **Check for helper programs** before showing features that need them:

```qml
Process {
    command: ["sh", "-c", "command -v cliphist"]
    running: true
    onExited: code => GlobalStates.hasCliphist = code === 0
}
```

- **Compositor abstraction** (`services/Workspaces.qml`) if you want to support more than one compositor.

## A good README

1. Screenshot or short video first.
2. Features list.
3. Dependencies: Quickshell version (or fork), Qt modules, fonts, CLI tools, with install commands per distro.
4. Install steps (clone, symlink, autostart line, keybinds).
5. Configuration: where the JSON lives and its options.
6. IPC targets and keybinds table (`qs ipc show` output).
7. Credits and license.

## Licensing

Pick a license (MIT, GPL-3.0…) and add a `LICENSE` file. If you borrowed code from another rice, keep its license notice and credit it.

## Keeping up with Quickshell

- Read release notes before updating: occasionally properties are renamed or deprecated (the reference marks deprecated members, e.g. `PopupWindow.parentWindow` → `anchor.window`).
- Use `Quickshell.hasVersion()` to support old and new versions during transitions.
- After a Qt update, rebuild any C++ plugins.
- Test new versions in a separate config (`qs -c myshell-next`) before switching.

## Final words

You've gone from "what is a property?" to building every major component of a desktop shell. The rest is imagination:

- Sketch the desktop you want on paper.
- Break it into windows (which layer, which edges, which screens), services (what data) and widgets (what shapes and motion).
- Build one piece at a time, using the API reference as your dictionary.

There's no layout Quickshell can't draw. Go rice something nobody has seen before.
