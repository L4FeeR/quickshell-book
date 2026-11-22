# lyne-dots 1: What It Is and How It's Built

**lyne-dots** (github.com/caioax/lyne-dots) is a complete Hyprland desktop for Arch Linux. Its shell is written in Quickshell, and almost everything about it is set from its own **Settings app** instead of config files. One theme colours the bar, the terminal, the editor, GTK and Qt apps, Hyprland's borders and even the browser.

This part teaches you to rice it **from nothing**. You'll rebuild its shell file by file, with every line explained, and by the last chapter you'll be able to install the real lyne-dots, change anything in it, and build your own version without looking anything up.

<div class="preview"><svg width="640" height="380" viewBox="0 0 640 380"><defs><linearGradient id="lyw" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#24283b"/><stop offset="1" stop-color="#16161e"/></linearGradient></defs><rect width="640" height="380" fill="url(#lyw)"/><g stroke="#414868" stroke-width="1.2" fill="none" opacity=".5"><path d="M0 300 Q160 240 320 290 T640 260"/><path d="M0 320 Q160 260 320 310 T640 280"/><path d="M0 340 Q160 280 320 330 T640 300"/></g><rect width="640" height="30" fill="#1a1b26" opacity=".95"/><path d="M0 30h15a15 15 0 0 0-15 15z" fill="#1a1b26" opacity=".95"/><path d="M640 30h-15a15 15 0 0 1 15 15z" fill="#1a1b26" opacity=".95"/><path d="M14 8v9q0 5 5 5h9" stroke="#5673b3" stroke-width="3" fill="none" stroke-linecap="round"/><circle cx="26" cy="12" r="3.5" fill="#7aa2f7"/><rect x="42" y="9" width="24" height="12" rx="6" fill="#7aa2f7"/><g fill="#414868"><rect x="70" y="9" width="12" height="12" rx="6"/><rect x="86" y="9" width="12" height="12" rx="6" fill="#565f89"/><rect x="102" y="9" width="12" height="12" rx="6"/><rect x="118" y="9" width="12" height="12" rx="6"/></g><text x="142" y="19" fill="#a9b1d6" font-size="10">kitty — ~/src/lyne</text><text x="290" y="19" fill="#a9b1d6" font-size="10">Sun 22 Nov</text><text x="342" y="19" fill="#c0caf5" font-size="11" font-weight="700">14:58</text><text x="540" y="19" fill="#c0caf5" font-size="11">‹  ◉ ᛒ 🔊 ▮ 70%</text><text x="620" y="19" fill="#c0caf5" font-size="11">🔔</text><path d="M440 30 h180 v170 a14 14 0 0 1 -14 14 h-152 a14 14 0 0 1 -14 -14 z" fill="#1a1b26" opacity=".95"/><path d="M426 30 h14 v14 a14 14 0 0 0 -14 -14z" fill="#1a1b26" opacity=".95"/><path d="M620 30 h14 a14 14 0 0 0 -14 14z" fill="#1a1b26" opacity=".95"/><text x="456" y="56" fill="#c0caf5" font-size="11" font-weight="700">l4feer</text><text x="560" y="56" fill="#c0caf5" font-size="11">🎨 ⚙ <tspan fill="#f7768e">⏻</tspan></text><rect x="452" y="66" width="76" height="34" rx="8" fill="#7aa2f7"/><text x="462" y="81" fill="#1a1b26" font-size="9" font-weight="700">Wi-Fi</text><text x="462" y="93" fill="#1a1b26" font-size="8">HomeNet</text><rect x="534" y="66" width="76" height="34" rx="8" fill="#24283b"/><text x="544" y="81" fill="#c0caf5" font-size="9" font-weight="700">Bluetooth</text><text x="544" y="93" fill="#a9b1d6" font-size="8">Off</text><rect x="452" y="106" width="76" height="34" rx="8" fill="#24283b"/><text x="462" y="126" fill="#c0caf5" font-size="9">DND</text><rect x="534" y="106" width="76" height="34" rx="8" fill="#24283b"/><text x="544" y="126" fill="#c0caf5" font-size="9">Caffeine</text><rect x="452" y="148" width="158" height="18" rx="9" fill="#292e42"/><rect x="452" y="148" width="104" height="18" rx="9" fill="#7aa2f7"/><rect x="452" y="172" width="158" height="18" rx="9" fill="#292e42"/><rect x="452" y="172" width="44" height="18" rx="9" fill="#7aa2f7"/><rect x="180" y="110" width="250" height="150" rx="14" fill="#1a1b26" opacity=".95" stroke="#292e42"/><rect x="190" y="120" width="230" height="28" rx="8" fill="#24283b"/><text x="200" y="138" fill="#7aa2f7" font-size="11">▦</text><text x="216" y="138" fill="#545c7e" font-size="10">Search apps…  (&gt; actions, = calc)</text><rect x="190" y="154" width="230" height="30" rx="8" fill="#292e42"/><circle cx="206" cy="169" r="8" fill="#fab387"/><text x="222" y="173" fill="#c0caf5" font-size="10" font-weight="700">Firefox</text><circle cx="206" cy="201" r="8" fill="#7dcfff"/><text x="222" y="205" fill="#c0caf5" font-size="10">Files</text><circle cx="206" cy="233" r="8" fill="#9ece6a"/><text x="222" y="237" fill="#c0caf5" font-size="10">kitty</text><g font-size="10" fill="#c0caf5"><text x="40" y="200">bar: docked with corners</text><text x="300" y="300" fill="#7aa2f7">launcher (tap Super)</text><text x="470" y="236" fill="#7aa2f7">Quick Settings, attached to the bar</text></g></svg></div>

*The rebuild in Tokyo Night: the bar flows into the screen with curved corners, Quick Settings slides out of it, and the launcher opens when you tap Super.*

## What you'll learn

Rebuilding lyne teaches nearly every technique a modern rice uses, in a codebase that's clean and well commented:

- **One settings file** (`state.json`) that every widget reads by key path, with defaults, live reloads and a settings app that writes to it ([[ch:ly2-state]], [[ch:ly11-settings]]).
- **Design tokens** and **theme files** that recolour the shell *and* the rest of the desktop, with a smooth colour fade between themes ([[ch:ly3-config-theme]]).
- A **bar with four layouts** and panels that **grow out of it** with curved joints ([[ch:ly5-bar]], [[ch:ly6-panels]]).
- A **launcher with modes** (apps, actions, calculator, clipboard) and fuzzy search ([[ch:ly7-launcher]]).
- A **notification daemon**, an **OSD**, a **secure lock screen**, a **power menu**, **idle handling**, **screenshots** and a **wallpaper picker** ([[ch:ly8-notifications-osd]] to [[ch:ly10-screenshot-wallpaper]]).
- **Hyprland in Lua**, the way lyne configures it ([[ch:ly12-assemble]]).
- And then: **ricing the real thing** with its installer, Settings app and `lyne` command ([[ch:ly13-rice-it]]).

## The original, in one picture

lyne-dots is a **dotfiles repository**: a folder of config files that its installer links into your home folder with GNU Stow. Each top-level folder is one "package":

```text
lyne-dots/
├── quickshell/   → ~/.config/quickshell/     the shell (313 QML files)
├── hyprland/     → ~/.config/hypr/           Hyprland, configured in Lua
├── kitty/ zsh/ tmux/ nvim/ fastfetch/        terminal, shell, editor…
├── theming/ kde/                             GTK, Qt and KDE colours
├── local/        → ~/.local/                 scripts, the `lyne` command, themes, wallpapers
├── .data/                                    default themes, wallpapers, state defaults, CLI, migrations
└── .install/  install.sh                     the guided installer
```

The shell itself is organised like this:

```text
quickshell/.config/quickshell/
├── shell.qml        loads everything and turns global shortcuts into actions
├── config/          Config.qml: every colour, size and duration, read from state.json
├── services/        67 singletons: State, Theme, Audio, Launcher, Notification, Lock, Power…
├── components/      reusable pieces: BarButton, AttachedPanel, ConcaveCorner, sliders…
│   ├── workspaces/  five workspace styles     ├── tray/   four tray styles
│   ├── osd/         four OSD styles           └── quickSettings/  four button styles
└── modules/         one folder per feature:
    bar  calendar  dashboard  launcher  lock  notifications  osd  power
    quickSettings  screenshot  settings  systemMonitor  wallpaper  welcome
```

## How the pieces talk

Everything in lyne follows one pattern. Learn it once and every file makes sense:

<div class="preview"><svg width="660" height="250" viewBox="0 0 660 250"><g font-size="11" text-anchor="middle"><rect x="10" y="20" width="120" height="50" rx="10" fill="#24283b"/><text x="70" y="42" fill="#c0caf5">state.json</text><text x="70" y="58" fill="#a9b1d6" font-size="9">+ defaults.json</text><rect x="170" y="20" width="120" height="50" rx="10" fill="#7aa2f7"/><text x="230" y="42" fill="#1a1b26">StateService</text><text x="230" y="58" fill="#1a1b26" font-size="9">get("bar.style")</text><rect x="330" y="20" width="120" height="50" rx="10" fill="#bb9af7"/><text x="390" y="42" fill="#1a1b26">Config</text><text x="390" y="58" fill="#1a1b26" font-size="9">tokens + palette</text><rect x="490" y="20" width="160" height="50" rx="10" fill="#24283b"/><text x="570" y="42" fill="#c0caf5">widgets</text><text x="570" y="58" fill="#a9b1d6" font-size="9">Config.accentColor, Config.radius</text><rect x="330" y="110" width="120" height="44" rx="10" fill="#9ece6a"/><text x="390" y="136" fill="#1a1b26">ThemeService</text><rect x="170" y="110" width="120" height="44" rx="10" fill="#24283b"/><text x="230" y="130" fill="#c0caf5">themes/*.json</text><text x="230" y="144" fill="#a9b1d6" font-size="9">~/.local/themes</text><rect x="10" y="190" width="200" height="44" rx="10" fill="#e0af68"/><text x="110" y="210" fill="#1a1b26">feature services</text><text x="110" y="224" fill="#1a1b26" font-size="9">LauncherService.visible, .entries…</text><rect x="250" y="190" width="200" height="44" rx="10" fill="#24283b"/><text x="350" y="210" fill="#c0caf5">modules (windows)</text><text x="350" y="224" fill="#a9b1d6" font-size="9">draw what the service says</text><rect x="490" y="190" width="160" height="44" rx="10" fill="#f7768e"/><text x="570" y="210" fill="#1a1b26">shell.qml + Hyprland</text><text x="570" y="224" fill="#1a1b26" font-size="9">shortcuts call services</text></g><g stroke="#a9b1d6" stroke-width="1.5" fill="none"><path d="M130 45h40"/><path d="M290 45h40"/><path d="M450 45h40"/><path d="M290 132h40"/><path d="M390 110v-40"/><path d="M450 212h40" /><path d="M210 212h40"/><path d="M570 190v-120" stroke-dasharray="4 3"/></g></svg></div>

1. **Settings** live in `state.json`. Only `StateService` touches the file.
2. **`Config`** turns settings and the theme into **tokens**: `Config.accentColor`, `Config.radius`, `Config.barHeight`. Widgets use tokens and never write a number or colour of their own.
3. Each **feature has a service** (a singleton) that holds its state and logic: is the launcher open, what's in the list, what does Enter do.
4. Each **module** is just the window that draws what its service says.
5. **`shell.qml`** loads the modules and turns Hyprland shortcuts into service calls.

Because of rule 3, keybinds, the bar, the Settings app and the terminal (`qs ipc call …`) all control the same feature the same way: they call its service.

## The rebuild

The original is about 56,000 lines and GPL-3.0 licensed, so copying it line by line would neither teach well nor be fair to its author. Like the other rebuilds in this book ([[ch:f0-famous-rices]]), this one is **new code that follows lyne's architecture and look**, in about 4,500 lines:

| lyne-dots | The rebuild ("lyne") |
|---|---|
| `state.json` + `defaults.json`, read by dot paths | the same, in `~/.config/lyne/state.json` |
| theme JSON files in `~/.local/themes` | **the same format and folder**: themes work in both |
| global shortcut names (`quickshell:app_launcher`…) | **the same names**: lyne's keybinds drive the rebuild |
| 4 bar styles, 5 workspace styles, 4 tray styles, 4 OSD styles | 4 bar styles, 3 workspace styles, the drawer tray, 2 OSD styles |
| 27 Settings pages, search, welcome screen, theme creator | 6 Settings pages with the same row types |
| wallpaper-based Material You themes, OKLCH theme creator | left out ([[ch:th7-beyond-the-shell]] shows matugen) |
| weather, lyrics, cava, GPU stats, monitor and GPU settings, per-monitor workspaces | left out (each chapter says where to find them in the original) |
| `lyne` CLI, installer, migrations | covered in [[ch:ly13-rice-it]] |

Every code block in these chapters is a file from `examples/lyne/`. The book inserts the files directly, so what you read is exactly what runs.

```text
examples/lyne/                 (copy to ~/.config/quickshell/lyne)
├── shell.qml  defaults.json
├── themes/      tokyonight  catppuccin-mocha  catppuccin-latte  nord  gruvbox  rose-pine
├── config/      Config  Icons
├── services/    StateService  ThemeService  color.js  WindowManagerService  Hypr
│                AudioService  BrightnessService  OsdService  NotificationService
│                LauncherService  LauncherActions  fuzzy.js  QuickSettingsService
│                DashboardService  LockService  PowerService  IdleService
│                WallpaperService  SettingsService
├── components/  StyledText  Glyph  ConcaveCorner  BarIsland  BarButton  BarDivider
│                LyneMark  Card  QsSlider  AttachedPanel  AttachedPopup
│                Workspaces  LauncherButton  ActiveWindow  TrayWidget
├── modules/
│   ├── bar/            Bar
│   ├── dashboard/      ClockButton  DashboardWindow
│   ├── quickSettings/  QuickSettingsButton  QuickSettingsWindow
│   ├── notifications/  NotificationButton  NotificationCard  NotificationOverlay  NotificationHistory
│   ├── launcher/       Launcher          ├── osd/        OsdOverlay
│   ├── lock/           LockScreen        ├── power/      PowerOverlay
│   ├── screenshot/     ScreenshotOverlay ├── wallpaper/  Background  WallpaperPicker
│   └── settings/       SettingsWindow  SettingRow  SwitchRow  ChoiceRow  SliderRow
└── extras/      lyne.lua (Hyprland, Lua)  hyprland.conf (classic)  kitty.conf
```

## Before you start

You need the basics from Parts 1–3 of this book: objects and properties, bindings, signals, singletons ([[ch:33-singletons]]), `PanelWindow` ([[ch:30-panel-windows]]) and `Process`/`FileView` ([[ch:37-processes]], [[ch:38-files-json]]). Each chapter links back when it uses something.

Install what the rebuild calls:

```bash
sudo pacman -S --needed quickshell ttf-cascadia-code-nerd libqalculate cliphist wl-clipboard grim brightnessctl libnotify
```

(`libqalculate` brings the `qalc` command the calculator uses. Any Nerd Font works; set it in Settings › Appearance or in `typography.font`.)

Then copy the rebuild and run it:

```bash
cp -r examples/lyne ~/.config/quickshell/lyne
```

```bash
qs -c lyne
```

> [!TIP] Trying it on another desktop
> On KDE or GNOME, start it with `LYNE_NO_EXPORT=1 qs -c lyne`. It then leaves kitty, GTK and Hyprland alone (theme exporting is explained in [[ch:ly3-config-theme]]). Hyprland-only parts, like workspaces and global shortcuts, just stay quiet there.

## How to read this part

Each chapter builds a layer and ends with exercises. Do them: the last chapter asks you to change the shell freely, and the exercises are the practice for that. Read the walkthroughs with the code beside you; every segment names its line numbers.

::: exercise warm | Find your way in the original
Clone lyne-dots (`git clone --depth 1 https://github.com/caioax/lyne-dots`) and open `quickshell/.config/quickshell/shell.qml`. Find the `Bar {}` line and the `GlobalShortcut` for the launcher. Then open `services/LauncherService.qml` and find the list of modes.
:::

::: exercise warm | Run the rebuild
Copy the rebuild, run `qs -c lyne`, and use `qs -c lyne ipc show` to list every IPC target it offers. Try `qs -c lyne ipc call theme next` a few times.
:::
