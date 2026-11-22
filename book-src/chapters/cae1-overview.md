# Caelestia 1: What It Is and How It's Built

Caelestia is a Material 3 shell from the caelestia-dots project. Its look is unmistakable: a thin **frame** runs around the whole screen, a narrow **vertical bar** sits inside the frame's left side, and every panel (dashboard, launcher, notifications, session menu, OSD…) **slides out of the frame** and melts into it with smooth inner curves. Nothing floats; everything is part of one surface.

<div class="preview"><svg width="640" height="380" viewBox="0 0 640 380"><defs><linearGradient id="cw" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6d5a9e"/><stop offset="1" stop-color="#2f5d73"/></linearGradient></defs><rect width="640" height="380" fill="url(#cw)"/><path d="M0 0H640V380H0Z M52 10H604Q630 10 630 36V344Q630 370 604 370H78Q52 370 52 344Z" fill="#141218" fill-rule="evenodd"/><g><rect x="8" y="16" width="36" height="348" rx="18" fill="#141218"/><circle cx="26" cy="34" r="9" fill="#d0bcff"/><rect x="11" y="54" width="30" height="104" rx="15" fill="#211f26"/><rect x="15" y="58" width="22" height="22" rx="11" fill="#d0bcff"/><rect x="15" y="84" width="22" height="30" rx="11" fill="#36343b"/><text x="26" y="73" fill="#381e72" font-size="9" text-anchor="middle">1</text><text x="26" y="102" fill="#e6e0e9" font-size="9" text-anchor="middle">2</text><text x="26" y="132" fill="#938f99" font-size="9" text-anchor="middle">3</text><text x="26" y="150" fill="#938f99" font-size="9" text-anchor="middle">4</text><text x="26" y="215" fill="#ccc2dc" font-size="9" transform="rotate(90 26 215)" text-anchor="middle">firefox — Quickshell</text><rect x="11" y="262" width="30" height="40" rx="15" fill="#211f26"/><text x="26" y="282" fill="#efb8c8" font-size="10" text-anchor="middle">14</text><text x="26" y="295" fill="#efb8c8" font-size="10" text-anchor="middle">32</text><rect x="11" y="308" width="30" height="34" rx="15" fill="#211f26"/><circle cx="26" cy="352" r="8" fill="none" stroke="#f2b8b5" stroke-width="2"/></g><path d="M200 10 Q226 10 226 36 V96 Q226 122 252 122 H408 Q434 122 434 96 V36 Q434 10 460 10 Z" fill="#141218"/><text x="330" y="50" fill="#d0bcff" font-size="12" text-anchor="middle">Dashboard · Media · Performance</text><rect x="246" y="62" width="70" height="46" rx="10" fill="#211f26"/><rect x="322" y="62" width="44" height="46" rx="10" fill="#211f26"/><rect x="372" y="62" width="44" height="46" rx="10" fill="#211f26"/><path d="M604 120 Q604 146 578 146 H566 Q540 146 540 172 V236 Q540 262 566 262 H578 Q604 262 604 288 Z" fill="#141218"/><rect x="556" y="160" width="16" height="84" rx="8" fill="#2b2930"/><rect x="556" y="200" width="16" height="44" rx="8" fill="#d0bcff"/><rect x="578" y="160" width="16" height="84" rx="8" fill="#2b2930"/><rect x="578" y="190" width="16" height="54" rx="8" fill="#d0bcff"/><path d="M230 370 Q256 370 256 344 V316 Q256 290 282 290 H378 Q404 290 404 316 V344 Q404 370 430 370 Z" fill="#141218"/><rect x="270" y="334" width="120" height="22" rx="11" fill="#211f26"/><text x="285" y="349" fill="#938f99" font-size="10">⌕ Type "&gt;" for…</text><g fill="#fff" font-size="10"><text x="70" y="30">frame</text><text x="470" y="30">dashboard (top edge)</text><text x="470" y="210">OSD (right edge)</text><text x="440" y="330">launcher (bottom edge)</text><text x="60" y="230">vertical bar</text></g></svg></div>

## The pieces

| Part | Where it appears | What it does |
|---|---|---|
| **Frame** (border) | all four screen edges | the surface everything else grows out of |
| **Bar** | left edge, inside the frame | logo, workspaces, active window (vertical text), tray, clock, status icons, power |
| **Bar popouts** | next to the bar | hover a status icon: audio, network, Bluetooth, battery details |
| **Dashboard** | top edge | tabs: dashboard (user, clock, calendar, media, resources), media, performance |
| **Launcher** | bottom edge | apps, `>` actions, calculator, wallpaper picker, colour schemes |
| **Notifications** | top-right | popups |
| **Sidebar** | right edge | notification centre |
| **Session** | right edge | logout, shutdown, sleep, reboot |
| **OSD** | right edge | volume and brightness sliders |
| **Utilities** | bottom-right corner | quick toggles, screen recording, toasts |
| **Lock** | everything | blurred screen, clock, password, media, weather |
| **Background** | behind windows | wallpaper, desktop clock, audio visualiser |

Most panels open when you **move the pointer to the frame edge** (the dashboard opens when you touch the top edge in the middle, the OSD when you touch the right edge), and all of them have keybinds.

## How the original is organised

```text
caelestia-dots/shell
├── shell.qml                 loads Background, Drawers, AreaPicker, Lock + daemons
├── config/  (C++ plugin)     Caelestia.Config: shell.json, tokens, per-monitor overrides
├── services/                 Colours, Audio, Brightness, Players, Notifs, Hypr, Wallpapers, Weather…
├── utils/                    Paths, Icons, Searcher, SysInfo…
├── components/               Anim, CAnim, StyledRect, StyledText, MaterialIcon, StateLayer, controls…
├── daemons/                  Shortcuts, BatteryMonitor, GameMode, IdleInhibit, IdleMonitors
├── modules/
│   ├── drawers/              ★ the frame window: ContentWindow, Panels, Interactions, Regions, Exclusions
│   ├── bar/                  Bar, BarWrapper, components/ (workspaces, status…), popouts/
│   ├── dashboard/ launcher/ notifications/ sidebar/ session/ osd/ utilities/
│   ├── lock/ background/ areapicker/ windowinfo/ nexus/ (settings app)
└── plugin/src/Caelestia/     C++: Blobs (shape merging shader), Config, Models, Services, Images…
```

Three things make it different from most shells:

1. **One window does almost everything.** `modules/drawers/ContentWindow.qml` is a transparent fullscreen window on each monitor. It draws the frame, contains the bar and every panel, and uses an **input mask** so clicks only land where something is drawn. Panels aren't separate windows; they're items inside this one window. That's what lets them melt into the frame. [[ch:cae3-frame]] builds it.
2. **A C++ plugin.** Caelestia ships its own Quickshell plugin. `Caelestia.Config` reads `~/.config/caelestia/shell.json` (with per-monitor settings), `Caelestia.Blobs` draws the merged frame-and-panel surface as signed-distance-field "blobs" on the GPU (that's why panels stretch and wobble slightly as they move), and other parts provide models, a calculator, image analysis and more.
3. **A companion CLI.** The `caelestia` command sets wallpapers and colour schemes (`caelestia scheme set`, `caelestia wallpaper -f …`), writes the scheme file the shell watches, and wraps IPC (`caelestia shell drawers toggle launcher`).

> [!NOTE] In the original
> Start reading at `shell.qml`, then `modules/drawers/Drawers.qml` → `ContentWindow.qml` → `Panels.qml`. Those four files show the whole architecture in about 600 lines.

## What the rebuild keeps and simplifies

| Original | Rebuild |
|---|---|
| frame + panels merged by a GPU blob shader (C++) | the same melted look drawn with `Shape` paths: a frame with a hole and panels with concave "ears" ([[ch:cae3-frame]]) |
| `Caelestia.Config` C++ config with per-monitor overrides | a QML `Config` singleton reading `~/.config/cae/shell.json` with `JsonAdapter` |
| `caelestia` CLI writes the colour scheme | matugen writes the same `scheme.json` format; the real CLI also works |
| drag gestures, touch support, window previews, recording, weather, visualiser, Nexus settings app | left out (each chapter says where to find them) |
| Google Sans Flex font | Rubik (change one token to switch) |

Everything visible in the screenshot above is in the rebuild: frame, vertical bar with merged workspace backgrounds and a trailing indicator, popouts, dashboard with three tabs, launcher with actions/calculator/wallpapers, notifications, notification centre, session drawer, OSD sliders, quick toggles, lock screen and wallpaper.

## The rebuild's file tree

```text
~/.config/quickshell/cae/
├── shell.qml
├── config/       Tokens.qml  Config.qml
├── components/   Anim  CAnim  StyledRect  StyledText  MaterialIcon  StateLayer  IconButton
│                 ScreenState  DrawerWrapper  VerticalSlider
├── services/     Colours  Visibilities  Hypr  Audio  Brightness  Players  Notifs  SysInfo  Time  Wallpapers  Apps
├── daemons/      Shortcuts
├── modules/
│   ├── drawers/      Drawers  ContentWindow  Exclusions  Panels  Interactions  Border  PanelBg
│   ├── bar/          BarWrapper  Bar  OsIcon  Workspaces  ActiveWindow  Tray  Clock  StatusIcons  Power
│   ├── popouts/      Wrapper  AudioPopout  NetworkPopout  BluetoothPopout  BatteryPopout
│   ├── dashboard/    Content  Card  Dash  Calendar  Media  Performance
│   ├── launcher/     Content  IconImageWrapper  WallpaperGrid
│   ├── notifications/ Content  NotificationCard
│   ├── sidebar/  session/  osd/  utilities/   Content
│   ├── lock/         Lock  LockSurface
│   └── background/   Background
└── extras/       hyprland.conf  matugen-config.toml  scheme.json.template
```

The `qs.*` imports follow the folders: `import qs.services` gives you `Colours`, `Audio`…; `import qs.modules.bar` gives you `BarWrapper`.

## The plan

| Chapter | You build |
|---|---|
| [[ch:cae2-foundations]] | tokens, config, colours, animation components, state per screen |
| [[ch:cae3-frame]] | the frame window, input mask, space reservation, drawer slots, edge hover |
| [[ch:cae4-bar]] | the vertical bar and its popouts |
| [[ch:cae5-dashboard]] | the dashboard and its three tabs |
| [[ch:cae6-launcher]] | the launcher with actions, calculator and wallpaper picker |
| [[ch:cae7-right-drawers]] | notifications, notification centre, session, OSD, quick toggles |
| [[ch:cae8-lock-background]] | lock screen, wallpaper, global shortcuts |
| [[ch:cae9-assemble]] | `shell.qml`, keybinds, theming from your wallpaper, customising |

## Practice

::: exercise warm | Find the drawers
In the original repo, open `modules/drawers/Panels.qml`. Which edge does each panel attach to? Write a list like "dashboard → top".
--- solution
dashboard → top centre; launcher → bottom centre; notifications → top-right; session, OSD and sidebar → right edge (the OSD shifts left when the session menu is open); utilities → bottom-right; bar popouts → left, next to the bar.
:::

::: exercise practice | Count the windows
In the original, search the `modules/` folder for `PanelWindow` and `StyledWindow`. Which modules create their own windows, and which live inside the drawers window?
--- hint
`grep -rln "StyledWindow\|PanelWindow" modules/`
--- solution
Only a few create windows: the drawers' `ContentWindow` and its `Exclusions`, the background, the area picker, and a couple of utility windows. The bar, dashboard, launcher, notifications, sidebar, session, OSD and utilities are all items inside `ContentWindow`.
:::
