# lyne-dots 13: Ricing lyne-dots, Start to Finish

You've built lyne's shell yourself, so you know how the real one works inside. This chapter is the practical part: installing the real lyne-dots, setting it up from its Settings app and its `lyne` command, making your own themes and wallpapers, changing Hyprland the way lyne expects, and changing the shell's code without losing your work on the next update. It ends with a full ricing walkthrough and a checklist.

## 1. Installing

lyne-dots is made for **Arch Linux** (or a close derivative like CachyOS or EndeavourOS), a user with `sudo`, and an internet connection. The one-line install downloads a short bootstrap script and runs it. Read it first; it's short and well commented:

```bash
curl -fsSL https://caioax.github.io/lyne-dots/install -o lyne-install.sh
less lyne-install.sh
bash lyne-install.sh
```

What happens:

1. The repository is cloned into **`~/.lyne-dots`**, at the latest release.
2. The installer asks **everything first**: which package categories (core, terminal, editor, apps, utils, fonts, quickshell, theming), your GPU driver (for NVIDIA), and whether to reboot.
3. A review screen lists every file of yours it will replace. Those go to **`~/.lyne-dots-backup/<date>/`**.
4. It installs unattended with a progress bar. The log is in `~/.cache/lyne/install-<date>.log`.

The shell (Quickshell), Hyprland and `~/.local/` files are always linked; leave out "terminal", "editor" or "theming" and your own kitty, Neovim or GTK configs stay untouched.

> [!TIP] Try it without changing anything
> `bash lyne-install.sh --dry-run` runs the whole installer against a throwaway home folder with stand-ins for `sudo` and `pacman`. Good for seeing every question before committing.

### Where things end up

lyne uses **GNU Stow**: each folder of the repository is a "package", linked into your home folder. The files in `~/.config/quickshell/` are **symlinks** into `~/.lyne-dots/quickshell/.config/quickshell/`.

| Path | What it is | Tracked by git? |
|---|---|---|
| `~/.lyne-dots/` | the repository | yes |
| `~/.config/quickshell/` | links to the shell's files | (links) |
| `~/.config/quickshell/state.json` | **your settings** | no |
| `~/.config/hypr/hyprland.lua`, `conf/` | links to the Hyprland config | (links) |
| `~/.config/hypr/local/*.lua` | **your machine's Hyprland settings** (written by Settings, plus any file you add) | no |
| `~/.local/themes/` | **your themes** (and the built-ins, copied) | no |
| `~/.local/wallpapers/` | **your wallpapers**, per-theme ones in `themes/<name>/` | no |

The rule that follows from this table: **settings, themes, wallpapers and `hypr/local/` are yours**; updates never touch them. Files inside `~/.lyne-dots` belong to the project; changes there need care (section 6).

## 2. The Settings app

Press **Super + I**. Everything you rebuilt in [[ch:ly11-settings]] exists here at full scale, 27 pages in four groups, each change applied live:

| Group | Pages |
|---|---|
| **Appearance** | Theme (presets, Material You from the wallpaper, light/dark, the theme creator) · Wallpaper (library, favourites, per-theme wallpapers, video) · Layout (gaps, borders, rounding, opacity, shadows) · Typography · Cursor · Icons |
| **Shell** | Bar (four templates with previews, position, auto-hide, centre buttons, workspace/tray/quick-settings styles) · Launcher (style, position, favourites) · Clipboard · Dashboard (tabs, weather location) · Power menu (templates) · Notifications · OSD (four styles) · Screenshot (folder, action, OCR languages) |
| **Hyprland** | Windows (tiling layouts: dwindle, master, scrolling) · Input (mouse, touchpad) · Keyboard (layouts, per-keyboard layouts) · Specials (special workspaces like WhatsApp and Music) · Monitors (drag on a map, keep-or-revert timer) · Graphics (GPU order on hybrid laptops) · Workspaces (per-monitor blocks) · Keybinds (change any key, add your own) |
| **System** | Lock screen (templates) · Idle · Brightness · Power profiles · Apps (default terminal, browser, file manager) · Autostart · Profile & region (name, avatar, language) · About (version, update channel, updates) |

Every page writes to `~/.config/quickshell/state.json` (Hyprland pages also write `~/.config/hypr/local/settings.lua`). A value that differs from the default gets a "restore default" button, like the ⟲ in the rebuild.

## 3. The `lyne` command

Everything in Settings is also scriptable. `lyne <command> --help` explains each one.

| Command | What it does |
|---|---|
| `lyne theme` | show the theme; `list`, `set <name>`, `auto` (Material You from the wallpaper), `scheme dark\|light` |
| `lyne state` | open `state.json`; `sync` (add new default keys), `rebuild` |
| `lyne reload` | restart Quickshell |
| `lyne update` | pull the channel's version, sync settings, run migrations, reload; `status`, `channel stable\|latest` |
| `lyne link` / `unlink` | link a package the install left out (yours go to the backup), or restore yours |
| `lyne monitors`, `workspaces`, `keyboard`, `autostart`, `gpu`, `nvidia` | the matching Settings pages, from the terminal |
| `lyne zen` | make Zen Browser profiles follow the theme |
| `lyne git` | run git inside the repository, wherever it is |
| `lyne welcome` | show the first-login welcome screen again |

And because the shell is Quickshell, its IPC works too: `qs ipc show` lists every target, like you saw in the rebuild.

## 4. Themes

A theme is **one JSON file** in `~/.local/themes/`, in exactly the format you met in [[ch:ly3-config-theme]]: `name`, `palette` (the shell's roles), `opacity`, `hyprland` (borders and shadow), `terminal` (kitty's colours), and optionally `wallpaper` (relative to `~/.local/wallpapers`).

Three ways to make one:

1. **In Settings › Theme › New theme**: start from a colour, a wallpaper or another theme. An OKLCH colour picker and a live mock-up of the desktop do the rest, and it renders a matching wallpaper.
2. **By hand**: copy a built-in (`cp ~/.local/themes/tokyonight.json ~/.local/themes/mine.json`), change `name` and colours, then `lyne theme set mine`. Check contrast with the rules from [[ch:th6-adding-themes]].
3. **From your wallpaper**: `lyne theme auto` generates a Material You palette from the current wallpaper with matugen.

To give your theme a wallpaper in its own colours, lyne's generator draws contour lines in any palette:

```bash
python3 ~/.lyne-dots/.data/wallpapers/generator/generate.py --theme-file ~/.local/themes/mine.json
```

A theme switch recolours: every panel (with a fade), Hyprland's borders and shadow (faded too), kitty, Neovim (the `lyne` colorscheme), GTK, Qt and KDE apps, Zen Browser (after `lyne zen enable`), and the wallpaper if the theme has one. Themes you make work in the rebuild too, and the other way round.

## 5. Hyprland, the lyne way

lyne's Hyprland config is **Lua** ([[ch:ly12-assemble]]):

```text
~/.config/hypr/
├── hyprland.lua          requires conf/*, then every local/*.lua
├── conf/                 variables, environment, autostart, appearance, input,
│                         workspaces, keybinds (+ binds.lua helper), specials, rules
└── local/                yours: settings.lua (from Settings), monitors.lua, gpus.lua, + your own
```

- **Most things are in Settings**, which writes `local/settings.lua`: gaps, borders, rounding, input, keyboard layouts, default apps, keybinds.
- **Anything else**: create your own file in `local/`, for example `local/mine.lua`. It's loaded after `conf/`, so it can override anything, and updates never touch it:

```lua
-- ~/.config/hypr/local/mine.lua
hl.config({ decoration = { rounding = 12, blur = { size = 10, passes = 3 } } })
hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty --class floating-term"))
hl.window_rule({ name = "float-term", match = { class = "floating-term" }, float = true, size = {900, 600} })
```

- **Keybinds**: binds in `conf/keybinds.lua` are declared with `bind(id, group, description, keys, dispatcher)`, so Settings › Keybinds can list them and change their keys. Changing a key there writes `lyne_rebind("id", "NEW + KEYS")` to `local/settings.lua`. Shell actions use global shortcuts named `quickshell:<name>`, the same names as in your rebuild's `shell.qml`.
- **After editing**, Hyprland reloads its config by itself on save. If something breaks, Settings shows Hyprland's error at the top of the Hyprland pages, and `hyprctl configerrors` prints it.

## 6. Changing the shell's code

Settings covers a lot, but you're a ricer now: you'll want to change the code. The shell is in `~/.lyne-dots/quickshell/.config/quickshell/`, organised exactly like your rebuild (`config/`, `services/`, `components/`, `modules/`, `shell.qml`). Quickshell reloads on save.

**Where things are**, now that you know the architecture:

| To change | Look in |
|---|---|
| a colour role or a size token | `config/Config.qml` (and the key in `.data/quickshell/defaults.json`) |
| what's in the bar | `modules/bar/Bar.qml` |
| a bar button | `components/` (`LauncherButton`, `Clock`, `TrayWidget`…) or the module's folder (`modules/quickSettings/QuickSettingsButton.qml`) |
| workspace / tray / OSD / quick-settings styles | `components/workspaces/`, `tray/`, `osd/`, `quickSettings/` |
| a feature's behaviour | its service in `services/` (`LauncherService`, `NotificationService`…) |
| a popup's look | its module in `modules/` |
| shortcuts | `shell.qml` (the `GlobalShortcut`s) and `hypr/conf/keybinds.lua` |
| a Settings page | `modules/settings/pages/` and `services/SettingsService.qml` (the page list) |

**Keeping your changes through updates.** `lyne update` pulls new versions with git. If you've edited files inside `~/.lyne-dots`, it lists them and asks whether to **stash** them (bring them back with `lyne git stash pop`), discard them, or cancel. For anything beyond small tweaks, use git properly:

```bash
lyne git checkout -b my-rice       # your own branch
# …edit, test…
lyne git commit -am "My bar layout"
```

Then update by merging: `lyne git fetch && lyne git merge origin/main`, and resolve any conflicts. Or **fork** the repository on GitHub and install from your fork (`LYNE_BOOTSTRAP_REPO=https://github.com/you/lyne-dots.git` before the bootstrap). Prefer changes that add files (a new component, a new page) over changes that rewrite existing ones: new files never conflict.

**Adding a setting** follows the four steps from [[ch:ly11-settings]]: a default in `.data/quickshell/defaults.json`, a token in `config/Config.qml` (`getState("bar.myThing", …)`), using it, and a row on a Settings page.

## 7. A full rice, step by step

Here's a complete session, from a fresh install to a desktop that's yours. Do it on the real lyne-dots or on your rebuild; every step works in both.

1. **Pick a base theme.** Settings › Theme, or `lyne theme set rose-pine`. Look at it for a while before changing anything.
2. **Make it yours.** Copy it to `~/.local/themes/mine.json`, set your accent, maybe deepen `background` a little. Apply it. Check text contrast (7:1 for `text` on `background`).
3. **Wallpaper.** Generate one in your theme's colours, or pick a photo whose colours match your accent. Add `"wallpaper"` to your theme file so they travel together.
4. **Shape.** Settings › Layout and Bar: corner radius, gaps, border size, bar style. Rounder and floating feels soft; square and docked feels technical. Keep the radii consistent: lyne's three tokens (small, normal, large) exist so everything matches.
5. **Type.** Settings › Typography: one Nerd Font for the whole shell. Try a few sizes; 13–14 is comfortable at 1080p, larger on HiDPI.
6. **Bar content.** Workspace style, tray style, centre buttons. Remove what you never look at.
7. **Motion.** Animation durations: shorter feels snappy, longer feels smooth. Keep the theme fade on: it's one of lyne's nicest touches.
8. **Keys.** Settings › Keybinds: move anything that doesn't suit your hands. Add binds for the dashboard tabs you use.
9. **Hyprland extras.** Your own `~/.config/hypr/local/mine.lua` for window rules, blur strength and anything Settings doesn't cover.
10. **One code change.** Pick one thing Settings can't do (a new bar button, a launcher action, a dashboard card) and build it, on your own branch.
11. **Screenshot.** Clean desktop, a terminal with `fastfetch`, an editor, your launcher open. That's your rice.

## What you can do now

By building the rebuild and ricing the original, you've practised every part of lyne-dots:

- [ ] Read any file in lyne's shell and say which layer it belongs to (state, config, service, component, module, entry point).
- [ ] Add a setting from `defaults.json` to a Settings row.
- [ ] Write a theme file by hand and know what each section colours.
- [ ] Explain how a theme switch fades every colour at once.
- [ ] Change the bar's layout and add a button to it.
- [ ] Build a panel that slides out of the bar with curved joints.
- [ ] Add a launcher mode or action.
- [ ] Understand the notification server, OSD, lock screen and power menu, and change them safely.
- [ ] Configure Hyprland in Lua, add binds and rules in `local/`, and wire a key to a shell shortcut.
- [ ] Keep your changes through updates with git.

## Practice

::: exercise practice | Port a feature back
Pick one exercise you solved in this part (seconds on hover, a web-search mode, the night-light tile…) and add it to the **real** lyne-dots on your own branch.
:::

::: exercise practice | A theme for both
Make a theme, use it in the real lyne-dots, then copy the file into your rebuild's `themes/` folder (or just keep it in `~/.local/themes`) and confirm both shells look the same.
:::

::: exercise challenge | A new bar template
lyne has four bar styles. Design a fifth (a vertical bar on the left, or a bar with a gap only at the top) in your rebuild first, then implement it in lyne: a new value for `bar.style`, its tokens in `Config.qml`, its layout in `Bar.qml`, and a preview in Settings › Bar.
:::

::: exercise project | Your rice, from scratch
Without looking at the chapters, start a new empty Quickshell config and build your own shell in lyne's architecture: a `StateService` with `defaults.json`, a `Config` with tokens, a theme service reading lyne-format themes, a bar with your own layout, one attached panel, a launcher, and notifications. Use the rebuild only to check yourself afterwards. When you can do this, you can rice anything.
:::
