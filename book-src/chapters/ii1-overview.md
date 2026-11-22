# end-4 1: What illogical-impulse Is and How It's Built

**illogical-impulse** ("ii") is the Quickshell config inside end-4's popular *dots-hyprland*. Its look: a top bar made of rounded **groups** that melts into rounded screen corners, a **right sidebar** with quick toggles, sliders, notifications and a calendar, a **left sidebar** with tools (an AI chat, a translator), and an **overview** that shows your workspaces with live window previews and doubles as a launcher. Everything is Material You, coloured from your wallpaper.

<div class="preview"><svg width="640" height="380" viewBox="0 0 640 380"><defs><linearGradient id="iw" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2f5d73"/><stop offset="1" stop-color="#5b4a8a"/></linearGradient></defs><rect width="640" height="380" fill="url(#iw)"/><rect width="640" height="34" fill="#141218"/><path d="M0 34h22a22 22 0 0 0-22 22z" fill="#141218"/><path d="M640 34h-22a22 22 0 0 1 22 22z" fill="#141218"/><circle cx="18" cy="17" r="11" fill="#211f26"/><text x="18" y="21" fill="#e6e0e9" font-size="11" text-anchor="middle">✦</text><text x="38" y="14" fill="#938f99" font-size="8">kitty</text><text x="38" y="26" fill="#e6e0e9" font-size="10">~/rice — nvim</text><g transform="translate(160 5)"><rect width="90" height="24" rx="10" fill="#1d1b20"/><circle cx="14" cy="12" r="8" fill="none" stroke="#4a4458" stroke-width="2.5"/><circle cx="36" cy="12" r="8" fill="none" stroke="#4a4458" stroke-width="2.5"/><text x="50" y="16" fill="#cac4d0" font-size="9">Song • Artist</text><rect x="94" width="200" height="24" rx="10" fill="#1d1b20"/><rect x="98" y="2" width="76" height="20" rx="10" fill="#4a4458" opacity=".7"/><rect x="100" y="4" width="20" height="16" rx="8" fill="#d0bcff"/><g fill="#e8def8" font-size="9" text-anchor="middle"><text x="132" y="16">◉</text><text x="152" y="16">◉</text></g><g fill="#938f99" font-size="9" text-anchor="middle"><text x="188" y="16">4</text><text x="208" y="16">5</text><text x="228" y="16">6</text><text x="248" y="16">7</text><text x="268" y="16">8</text></g><rect x="298" width="140" height="24" rx="10" fill="#1d1b20"/><text x="312" y="16" fill="#cac4d0" font-size="10">14:32 • Sat, 21/11</text></g><rect x="566" y="5" width="66" height="24" rx="12" fill="#211f26"/><text x="599" y="21" fill="#e6e0e9" font-size="10" text-anchor="middle">🔔 ◉ ᛒ</text><g transform="translate(440 46)"><rect width="190" height="320" rx="20" fill="#141218" stroke="#49454f"/><text x="14" y="24" fill="#e6e0e9" font-size="11">Up 3h, 12m</text><rect x="12" y="36" width="166" height="44" rx="14" fill="#1d1b20"/><rect x="20" y="44" width="28" height="28" rx="9" fill="#d0bcff"/><rect x="54" y="44" width="28" height="28" rx="14" fill="#211f26"/><rect x="88" y="44" width="28" height="28" rx="9" fill="#d0bcff"/><rect x="122" y="44" width="28" height="28" rx="14" fill="#211f26"/><rect x="12" y="92" width="166" height="10" rx="5" fill="#4a4458"/><rect x="12" y="92" width="110" height="10" rx="5" fill="#d0bcff"/><rect x="12" y="112" width="166" height="110" rx="14" fill="#1d1b20"/><rect x="20" y="120" width="150" height="34" rx="10" fill="#211f26"/><rect x="20" y="160" width="150" height="34" rx="10" fill="#211f26"/><rect x="12" y="232" width="166" height="78" rx="14" fill="#1d1b20"/><text x="24" y="250" fill="#cac4d0" font-size="10">November 2026</text></g><g fill="#fff" font-size="11"><text x="160" y="52">grouped bar that melts into the corners ↑</text><text x="250" y="200">right sidebar →</text></g></svg></div>

## The pieces

| Panel | Where | What it does |
|---|---|---|
| **Bar** | top (or bottom) | left: sidebar button + active window; centre: resources+media · workspaces · clock+utilities+battery; right: indicators + tray |
| **Workspaces** | in the bar | merged occupied backgrounds, a trailing active pill, app icons (hold Super for numbers) |
| **Right sidebar** | right, full height | system buttons, quick toggles, sliders, notifications, calendar / to-do / timers |
| **Left sidebar** | left, full height | AI chat, translator, anime image browser |
| **Overview** | centre | search (apps, maths, commands, web, emoji, clipboard) + a grid of workspaces with live window previews; drag windows between workspaces |
| **OSD** | under the bar | volume and brightness pills |
| **Notification popups** | top-right | popups |
| **Session screen** | fullscreen | lock, sleep, logout, shutdown, reboot… |
| **Lock screen** | fullscreen | clock, password with shaped characters |
| **Screen corners, background, dock, cheatsheet, media controls, on-screen keyboard, region selector, wallpaper selector…** | | |

## How the original is organised

```text
dots-hyprland/dots/.config/quickshell/ii/
├── shell.qml               loads a "panel family" (ii or waffle)
├── GlobalStates.qml        which panels are open
├── panelFamilies/          IllogicalImpulseFamily.qml: the list of ~20 panels
├── services/               ~50 singletons: Audio, Notifications, Ai, AppSearch, LauncherSearch,
│                           HyprlandData, MaterialThemeLoader, ResourceUsage, Weather, Todo…
├── modules/
│   ├── common/             Appearance.qml, Config.qml, Directories.qml, functions/, widgets/ (90+)
│   ├── ii/                 bar/ background/ dock/ lock/ overview/ sidebarLeft/ sidebarRight/
│   │                       onScreenDisplay/ notificationPopup/ sessionScreen/ screenCorners/ …
│   ├── waffle/             a second, Windows-11-like family
│   └── settings/           a full settings application
├── scripts/                colour generation, AI helpers, etc.
└── defaults/               default config.json, AI prompts
```

Key differences from Caelestia:

1. **One window per panel.** The bar, each sidebar, the overview, the OSD and the popups are separate `PanelWindow`s, each shown when its `GlobalStates` flag is true. Simpler to understand; each panel can be studied alone.
2. **A layered colour system.** `Appearance.qml` turns the Material palette into **layers**: `colLayer0` (the bar and panel backgrounds), `colLayer1` (groups and cards on them), `colLayer2` (buttons in cards), each with hover and active variants and optional transparency computed from your wallpaper's vibrancy.
3. **Config as nested JSON.** `Config.qml` exposes `~/.config/illogical-impulse/config.json` as `Config.options.bar.autoHide.enable`, and the settings app edits it.
4. **Lua-ready Hyprland commands.** Since Hyprland's Lua configs arrived, ii dispatches commands in Lua form (`hl.dsp.focus({ workspace = 3 })`), and its own Hyprland config is written in Lua.

> [!NOTE] In the original
> Read `shell.qml`, then `panelFamilies/IllogicalImpulseFamily.qml` (the panel list), then `GlobalStates.qml` and `modules/common/Appearance.qml`. After that, any panel folder in `modules/ii/` can be read on its own.

## What the rebuild keeps and simplifies

| Original | Rebuild ("impulse") |
|---|---|
| two panel families, settings app, welcome app | one family, edit `config.json` by hand (or via IPC) |
| ~90 common widgets | the essentials: StyledText, MaterialSymbol, RippleButton, RoundCorner, CircularProgress, NotificationItem |
| colour layers with automatic transparency from wallpaper vibrancy | the same layers with a fixed transparency option |
| left sidebar: AI chat (several providers), translator, anime/booru | the same tabbed sidebar with a translator and clipboard history (no API keys needed) |
| overview: search, emoji, clipboard; scaled live window previews; drag-and-drop | search (apps, maths, commands, web) and live previews with drag-and-drop |
| dock, cheatsheet, media controls, on-screen keyboard, region selector, screen translator, wallpaper selector | left out (each is a good exercise; Part R and the gallery have similar modules) |

## The rebuild's file tree

```text
~/.config/quickshell/impulse/
├── shell.qml
├── services/   GlobalStates  MaterialThemeLoader  Hypr  HyprlandData  Audio  Brightness  MprisController
│               Notifications  ResourceUsage  DateTime  LauncherSearch  Wallpaper
├── modules/
│   ├── common/           Appearance  Config  functions/ColorUtils
│   │   └── widgets/      StyledText  MaterialSymbol  RippleButton  RoundCorner  CircularProgress  NotificationItem
│   ├── bar/              Bar  BarContent  BarGroup  Workspaces  ActiveWindow  Resources  Media
│   │                     ClockWidget  UtilButtons  BatteryIndicator  SysTray
│   ├── sidebarRight/     SidebarRight  SidebarRightContent  MonthGrid
│   ├── sidebarLeft/      SidebarLeft  Translator  ClipboardHistory
│   ├── overview/         Overview  OverviewGrid  AppIconImage
│   ├── onScreenDisplay/  OnScreenDisplay
│   ├── notificationPopup/ NotificationPopup
│   ├── sessionScreen/    SessionScreen
│   ├── lock/             Lock  LockSurface
│   ├── background/       Background
│   └── screenCorners/    ScreenCorners
└── extras/   hyprland.conf  matugen-config.toml  colors.json.template
```

The folders mirror the original's (`modules/common`, `modules/ii/bar` → `modules/bar`), so `import qs.modules.common` means the same thing in both.

## The plan

| Chapter | You build |
|---|---|
| [[ch:ii2-foundations]] | Appearance (colour layers, rounding, fonts, animation presets), Config, global state, theme loading, common widgets |
| [[ch:ii3-bar]] | the bar window with corner decorations and auto-hide, and its modules |
| [[ch:ii4-workspaces]] | the workspace indicator |
| [[ch:ii5-sidebars]] | the right and left sidebars |
| [[ch:ii6-overview]] | the overview with search and live previews |
| [[ch:ii7-popups]] | OSD, notification popups, screen corners |
| [[ch:ii8-lock-session]] | lock screen, session screen, background |
| [[ch:ii9-assemble]] | `shell.qml`, keybinds, colours, customising |

## Practice

::: exercise warm | The panel list
Open `panelFamilies/IllogicalImpulseFamily.qml` in the original. Which panels depend on a config option to exist at all?
--- solution
The horizontal `Bar` exists only when `bar.vertical` is false and `VerticalBar` only when it's true; the `Dock` only when `dock.enable` is true. Every other panel always exists and shows itself through its `GlobalStates` flag.
:::

::: exercise practice | Follow one flag
Pick `GlobalStates.sidebarRightOpen` in the original and find every file that reads or writes it. What opens the sidebar, and what closes it?
--- hint
`grep -rn sidebarRightOpen` in the `ii` folder.
:::
