# Project Layout of a Real Shell

You know the building blocks. Now let's organize them the way end-4, Caelestia, Noctalia and DankMaterialShell do, so your config can grow to dozens of components without becoming spaghetti. Every project in Part VI drops into this structure.

## The layout

```text
~/.config/quickshell/myshell/
├── shell.qml                  ← entry point: lists modules, starts services
├── .qmlls.ini                 ← empty; editor support (git-ignore it)
│
├── services/                  ← SINGLETONS that wrap the system (no UI!)
│   ├── GlobalStates.qml       ← which panels are open
│   ├── Config.qml             ← user options (FileView + JsonAdapter)
│   ├── Colors.qml             ← color palette (from matugen JSON)
│   ├── Appearance.qml         ← sizes, rounding, fonts, animation tokens
│   ├── Audio.qml   Media.qml   Battery.qml   Brightness.qml
│   ├── Network.qml Bluetooth.qml Notifs.qml  Time.qml
│   └── Workspaces.qml         ← compositor abstraction
│
├── widgets/                   ← REUSABLE STYLED PRIMITIVES
│   ├── StyledText.qml   MaterialIcon.qml   StyledRect.qml
│   ├── IconButton.qml   StyledSlider.qml   StyledSwitch.qml
│   ├── Tooltip.qml      Anim.qml           ColorAnim.qml
│
├── modules/                   ← FEATURES: one folder each
│   ├── bar/            Bar.qml  Workspaces.qml  Clock.qml  Tray.qml  StatusIcons.qml
│   ├── notifications/  NotificationPopups.qml  NotificationCard.qml
│   ├── launcher/       Launcher.qml  AppItem.qml
│   ├── osd/            Osd.qml
│   ├── controlcenter/  ControlCenter.qml  QuickToggle.qml  SliderRow.qml
│   ├── session/        Session.qml
│   ├── lock/           Lock.qml  LockSurface.qml
│   ├── overview/       Overview.qml
│   ├── dock/           Dock.qml
│   ├── wallpaper/      Wallpaper.qml  WallpaperPicker.qml
│   └── decorations/    ScreenCorners.qml  DesktopClock.qml
│
├── assets/                    ← images, bundled fonts, icons
└── scripts/                   ← shell helpers (wallpaper.sh …)
```

## The three layers

<div class="diagram"><svg viewBox="0 0 780 250" role="img" aria-label="three layers">
<rect class="a" x="20" y="20" width="740" height="56" rx="10"/><text x="40" y="45">modules/  (features)</text><text class="sm" x="40" y="64">Bar, Launcher, ControlCenter… compose widgets, read services</text>
<rect class="g" x="20" y="96" width="740" height="56" rx="10"/><text x="40" y="121">widgets/  (design system)</text><text class="sm" x="40" y="140">StyledText, IconButton, StyledSlider… read Colors + Appearance only</text>
<rect class="n" x="20" y="172" width="740" height="56" rx="10"/><text x="40" y="197">services/  (system + state)</text><text class="sm" x="40" y="216">Audio, Battery, Config, Colors, GlobalStates… talk to Quickshell modules, Process, FileView</text>
</svg></div>

**The golden rules:**

1. **Services know nothing about UI.** No colors, no Items: properties and functions only.
2. **Widgets know nothing about the system.** A `StyledSlider` doesn't know it's controlling volume.
3. **Modules glue them together**: `StyledSlider { value: Audio.volume; onMoved: Audio.setVolume(value) }`.
4. **Only services import `Quickshell.Services.*`**, `Quickshell.Io` (mostly) and compositor modules.

That gives you:

- **Reuse**: the bar, OSD and control center all use `Audio`.
- **Swappability**: move from `nmcli` to `Quickshell.Networking` by editing one file.
- **Consistency**: change `Appearance.rounding.normal` and every widget follows.
- **Testability**: you can fake a service's values to test UI.

## shell.qml: the table of contents

```qml file="shell.qml"
//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import QtQuick
import qs.services
import qs.modules.bar
import qs.modules.notifications
import qs.modules.launcher
import qs.modules.osd
import qs.modules.controlcenter
import qs.modules.session
import qs.modules.lock
import qs.modules.overview
import qs.modules.dock
import qs.modules.wallpaper
import qs.modules.decorations

ShellRoot {
    Wallpaper {}
    ScreenCorners {}
    Bar {}
    Dock {}
    NotificationPopups {}
    Launcher {}
    Osd {}
    ControlCenter {}
    Session {}
    Lock {}
    Overview {}

    // singletons are lazy; start the ones that must run from login
    Component.onCompleted: {
        Notifs.init()
        BatteryWarning.init()
    }
}
```

To disable a feature, comment out one line. To make features optional per user, wrap them: `LazyLoader { active: Config.modules.dock; Dock {} }`.

## Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Component files | PascalCase | `NotificationCard.qml` |
| Folders imported with `qs.` | lowercase, no dashes | `controlcenter` |
| ids | camelCase, root is `root` | `id: clockText` |
| Properties | camelCase, booleans read like questions | `isOpen`, `hasBattery`, `showSeconds` |
| Signals | past tense or event names | `clicked`, `dismissed`, `requestClose` |
| Layer namespaces | `<shell>:<module>` | `myshell:bar` |
| IPC targets | short nouns | `launcher`, `session`, `wallpaper` |

## Module folder structure

Each module folder has:

- one **entry component** with the folder's name (`Bar.qml`, `Launcher.qml`). It's usually a `Scope` containing the window(s), often inside `Variants` or `LazyLoader`.
- **subcomponents** used only by that module (`Workspaces.qml`, `AppItem.qml`).
- optionally its own **IpcHandler** and **GlobalShortcut**s, so the module is self-contained.

```qml file="modules/launcher/Launcher.qml"
import Quickshell
import Quickshell.Io
import qs.services

Scope {
    IpcHandler { target: "launcher"; function toggle(): void { GlobalStates.toggle("launcher") } }
    LazyLoader { active: GlobalStates.launcherOpen; LauncherWindow {} }
}
```

## Version control and sharing

```bash
cd ~/.config/quickshell/myshell
git init
printf '.qmlls.ini\n' > .gitignore
git add -A && git commit -m "initial shell"
```

Keep your shell in a dotfiles repo and symlink it into place:

```bash
ln -s ~/dotfiles/quickshell/myshell ~/.config/quickshell/myshell
```

## Growing pains to avoid

| Smell | Fix |
|---|---|
| A 600-line `Bar.qml` | split into subcomponents in `modules/bar/` |
| Colors hard-coded everywhere | `Colors` singleton ([[ch:44-theming]]) |
| `Process` calls scattered in UI files | move them into services |
| `../../../widgets` imports | `import qs.widgets` |
| Copy-pasted button code | `widgets/IconButton.qml` |
| Panels fighting over the screen | central `GlobalStates.toggle()` ([[ch:46-state]]) |

## Practice

::: exercise practice | Reorganize
Create the folder structure from this chapter, move your bar into `modules/bar/Bar.qml`, write `services/GlobalStates.qml`, and make `shell.qml` a short `ShellRoot` listing modules. Confirm everything still works.
--- hint
Every folder becomes a module: `modules/bar/` → `import qs.modules.bar`. Restart `qs` after creating `.qmlls.ini` so the editor sees the new modules.
:::

::: exercise challenge | Optional modules
Make the dock optional with a `Config.modules.dock` switch: `LazyLoader { active: Config.modules.dock; Dock {} }`. Flip it in `config.json` and watch the dock appear and disappear.
:::
