# Rebuilding Famous Rices: How This Part Works

Two Quickshell configs inspire most of the rices you see online: **Caelestia** (caelestia-dots/shell) and **end-4's illogical-impulse** (end-4/dots-hyprland). This part takes both apart and rebuilds them **from an empty folder, module by module**. By the end you'll understand every important piece of each, and you'll have two complete, working shells you can run, change and make your own.

<div class="preview"><svg width="680" height="210" viewBox="0 0 680 210"><g font-size="11"><g transform="translate(10 10)"><rect width="310" height="170" rx="10" fill="#5b4a8a"/><path d="M0 0h310v170H0z M40 8h262v154H40z" fill="#141218" fill-rule="evenodd"/><rect x="40" y="8" width="262" height="154" rx="16" fill="none"/><rect x="6" y="14" width="28" height="140" rx="14" fill="#211f26"/><circle cx="20" cy="28" r="6" fill="#d0bcff"/><rect x="14" y="44" width="12" height="40" rx="6" fill="#36343b"/><rect x="14" y="44" width="12" height="14" rx="6" fill="#d0bcff"/><path d="M110 8 q0 0 0 0 h100 v0 a16 16 0 0 0 0 0 z" fill="#141218"/><rect x="100" y="8" width="120" height="44" rx="14" fill="#141218"/><rect x="100" y="0" width="120" height="20" fill="#141218"/><text x="160" y="36" fill="#e6e0e9" text-anchor="middle">dashboard</text><rect x="268" y="60" width="34" height="60" rx="12" fill="#141218"/><rect x="290" y="60" width="20" height="60" fill="#141218"/><text x="155" y="195" fill="#a6adc8" text-anchor="middle">Caelestia: a frame with drawers</text></g><g transform="translate(360 10)"><rect width="310" height="170" rx="10" fill="#3a5a8c"/><rect width="310" height="22" fill="#141218"/><path d="M0 22h14a14 14 0 0 0-14 14z" fill="#141218"/><path d="M310 22h-14a14 14 0 0 1 14 14z" fill="#141218"/><rect x="100" y="4" width="110" height="14" rx="7" fill="#1d1b20"/><g fill="#d0bcff"><circle cx="112" cy="11" r="4"/></g><rect x="120" y="7" width="40" height="8" rx="4" fill="#4a4458"/><rect x="226" y="30" width="80" height="130" rx="14" fill="#141218" stroke="#49454f"/><rect x="234" y="40" width="64" height="18" rx="9" fill="#d0bcff"/><rect x="234" y="64" width="64" height="8" rx="4" fill="#4a4458"/><rect x="234" y="80" width="64" height="70" rx="10" fill="#211f26"/><text x="155" y="195" fill="#a6adc8" text-anchor="middle">end-4: bar, sidebars and overview</text></g></g></svg></div>

## What you get

| | Caelestia rebuild ("cae") | end-4 rebuild ("impulse") |
|---|---|---|
| Look | one continuous frame around the screen; a vertical bar on the left; panels slide out of the frame edges and melt into it | a top bar of rounded groups that melts into the screen corners; full-height sidebars; a workspace overview with live previews |
| Size | ~3,400 lines in 50 files | ~2,700 lines in 45 files |
| Chapters | [[ch:cae1-overview]] → [[ch:cae9-assemble]] | [[ch:ii1-overview]] → [[ch:ii9-assemble]] |
| Download | [cae.zip](../examples/cae.zip) · [browse](../examples/cae/) | [impulse.zip](../examples/impulse.zip) · [browse](../examples/impulse/) |

Every code block in these chapters **is a file from the download**. The book inserts the files directly, so what you read is exactly what runs.

## Rebuild, not copy

The original projects are big: Caelestia is about 40,000 lines of QML plus a C++ plugin, and illogical-impulse about 57,000 lines with many extra features (an AI chat, an on-screen keyboard, a settings app, a second "Windows-like" panel family…). Copying them line by line wouldn't teach much, and both are GPL-3.0 licensed works of their authors.

So each rebuild is **new code written for this book** that follows the same architecture, the same ideas and the same look:

- the same folder layout and module names, so you can open the original next to the rebuild and find your way;
- the same techniques: Caelestia's single fullscreen "drawers" window with an input mask and edge-hover zones; end-4's layered Material colours, trailing workspace indicator and Lua-aware Hyprland commands;
- the same design tokens: the rounding, spacing and Material 3 "expressive" motion curves have the same values as the originals;
- simpler where the original needs heavy machinery. For example, Caelestia merges its panels with a GPU "blob" shader from its C++ plugin; the rebuild draws the same melted look with plain QML shapes.

Each chapter has an **"In the original"** box that points to the real files and says what they do differently, so you can go deeper.

> [!NOTE] Licence
> Caelestia and illogical-impulse are GPL-3.0. The rebuilds here are original code written for this book. If you publish a shell that *copies* code from the originals, it must be GPL-3.0 too and credit them.

## How to use the rebuilds

1. **Install the dependencies** (Arch names; adapt for your distro):
   ```bash
   sudo pacman -S quickshell matugen brightnessctl grim slurp wl-clipboard libqalculate ttf-material-symbols-variable-git
   ```
   Fonts used: *Rubik* (UI), *JetBrains Mono* and *Material Symbols Rounded* (icons). end-4's rebuild also uses *Gabarito* for titles; translate-shell, cliphist and hyprpicker are optional.

2. **Unpack** a rebuild into your Quickshell config folder:
   ```bash
   mkdir -p ~/.config/quickshell && cd ~/.config/quickshell
   unzip ~/Downloads/cae.zip          # creates ~/.config/quickshell/cae
   unzip ~/Downloads/impulse.zip      # creates ~/.config/quickshell/impulse
   ```

3. **Run** one of them (stop your current shell first):
   ```bash
   qs -c cae
   qs -c impulse
   ```

4. **Add the keybinds** from `extras/hyprland.conf` to your Hyprland config, and the matugen template from `extras/` so colours follow your wallpaper.

5. **Read along.** Each chapter explains a group of files. Change something, save, and Quickshell reloads it live.

> [!TIP] Build it yourself instead
> For the deepest understanding, start from an empty `~/.config/quickshell/mycae/`, then type (or paste) each file as you read its chapter. Each chapter ends with the shell in a runnable state.

## A method for reading any rice

The same five questions work for any config you find on GitHub. This part answers them for two famous ones.

1. **What windows exist?** Look at `shell.qml` and search for `PanelWindow`, `PopupWindow` and `WlSessionLock`. Caelestia has very few windows (one frame per monitor does almost everything); end-4 has one window per panel.
2. **Where is state kept?** Find the singletons (`pragma Singleton`): which panels are open, the current colours, the config.
3. **Where do colours, sizes and motion come from?** Find the design system (Caelestia: `Tokens` + `Colours`; end-4: `Appearance`).
4. **How does input reach things?** Look for `mask:`, `HyprlandFocusGrab`, `GlobalShortcut` and `IpcHandler`.
5. **How do the panels animate?** Look for `Behavior on` and the animation presets.

Keep these questions in mind; [[ch:68-reading-rices]] covers the general skill.

## Practice

::: exercise warm | Install the originals side by side
Clone both originals to read along (you don't have to run them):
```bash
git clone --depth 1 https://github.com/caelestia-dots/shell ~/src/caelestia-shell
git clone --depth 1 https://github.com/end-4/dots-hyprland ~/src/dots-hyprland
```
Find `shell.qml` in each. How many top-level modules does each one load?
--- solution
Caelestia's `shell.qml` loads a handful of modules (background, drawers, area picker, lock) plus daemons; most of the UI lives inside **Drawers**. end-4's `shell.qml` loads a *panel family*, and the `ii` family (`panelFamilies/IllogicalImpulseFamily.qml`) lists about 20 separate panels: bar, background, dock, lock, OSD, overview, sidebars, and more.
:::

::: exercise practice | Answer the five questions
Pick a third config you like (noctalia, DankMaterialShell, or a friend's dots) and write one sentence for each of the five questions above.
:::
