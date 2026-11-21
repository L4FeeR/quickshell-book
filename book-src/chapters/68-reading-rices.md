# Reading Other People's Rices

The fastest way to grow after this book is to read real shells. This chapter is a field guide: how to approach a large config, where things usually live, and what to look for in the popular ones.

## How to read a big config

1. **Run it in isolation.** Clone into `~/.config/quickshell/<name>` and run `qs -c <name>`. Many shells have dependencies (fonts, CLI tools, a C++ plugin); check their README.
2. **Start at `shell.qml`.** It lists the top-level modules, the table of contents.
3. **Find the services folder.** Singletons there show how they talk to the system.
4. **Find the design tokens.** `Appearance.qml`, `Config.qml`, `Colours.qml`, `Theme.qml`.
5. **Pick one feature you like** (a workspace indicator, a notification animation) and trace it: find the file (`grep -rn "Workspaces" .`), read its imports, follow the services it uses.
6. **Re-implement it in your own structure**, using your own tokens. Don't paste whole files; you'll understand nothing and inherit their dependencies.

```bash
grep -rn "PanelWindow" --include=*.qml . | head          # where are the windows?
grep -rln "pragma Singleton" --include=*.qml .            # list all singletons
grep -rn "IpcHandler" -A2 --include=*.qml .               # which IPC targets exist?
grep -rn "GlobalShortcut" -A2 --include=*.qml .           # which keybinds?
```

## end-4 / dots-hyprland (illogical-impulse)

| You want | Look for |
|---|---|
| Entry and panel wiring | `shell.qml`, `GlobalStates.qml` |
| Config system (hundreds of options) | `modules/common/Config.qml` (FileView + JsonAdapter) |
| Colors and sizes | `modules/common/Appearance.qml` |
| Styled widget library | `modules/common/widgets/` |
| System services | `services/` (audio, battery, network, brightness, notifications, AI, booru, Hyprland data…) |
| Bar | `modules/bar/` |
| Overview with live previews | `modules/overview/` |
| Sidebars | `modules/sidebarLeft/`, `modules/sidebarRight/` |
| Wallpaper → colors | `scripts/colors/` (matugen + Python) |

Techniques worth studying: centralized `Config`, the sliding/stretching workspace indicator, the overview's window positioning math, search with `fuzzysort`, Material 3 shape morphing.

## Caelestia shell

| You want | Look for |
|---|---|
| Drawer architecture | `modules/drawers/` (window, backgrounds, interactions, panels) |
| Config | `config/` (one file per area) |
| Colors | `services/Colours.qml` + the `caelestia` CLI's scheme files |
| Components | `components/` (styled primitives, animations) |
| Services | `services/` |
| Native helpers | `plugin/` (C++ QML plugin: audio visualizer, beat detection, image tools) |

Techniques: the one-window-per-screen drawer layout with masks, shape backgrounds with concave joints, expressive motion tokens, and a CLI that drives the shell over IPC.

## Noctalia and DankMaterialShell

Both are designed to be **installed by other people**, so they show:

- settings GUIs bound to JSON config (FileView + JsonAdapter),
- feature toggles and per-monitor settings,
- compositor abstraction layers (Hyprland, niri, Sway),
- plugin and widget systems.

Noctalia ships its own Quickshell fork (**noctalia-qs**) with extra modules like `Quickshell.Niri` and `Quickshell.DWL`; if you build on those modules, your shell requires that fork.

## JaKooLit Hyprland-Dots

A large classic setup (Waybar, rofi, swaync, many scripts) that adopted Quickshell for selected components. It's useful to see how Quickshell coexists with other tools: separate small configs started with `qs -c …`, toggled by keybinds calling `qs ipc call`.

## Upstream examples and docs

- The Quickshell repository and the official docs at quickshell.org (type reference and guides; this book's API reference is generated from the same source comments).
- The `examples` in the docs: small focused configs for one feature each.

## Etiquette

- Respect licenses. Most rices are GPL or MIT; keep notices if you copy code.
- Credit ideas you borrow in your README.
- Report bugs upstream with minimal reproductions; don't open issues for your own modifications.

> [!TRY] Exercises
> 1. Clone one of the shells above, run it as a named config, and list all its IPC targets with `qs ipc show`.
> 2. Pick one widget from it and rebuild it from scratch in your shell using your own design tokens.
