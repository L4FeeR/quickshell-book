# Putting It Together: One Shell, Many Rices

You now have every part of a shell, each with several styles. This last guide connects them into **one shell that can become many rices**: a `Rice` profile picks the theme and the layout of every component, a `dynamic` theme follows your wallpaper, and one command switches the whole desktop live.

## The final folder

```text
~/.config/quickshell/myshell/
├── shell.qml                      ← this guide
├── services/
│   ├── Theme.qml                  ← r0 (+ "dynamic" preset, this guide)
│   ├── Rice.qml                   ← this guide: per-component layout choices + profiles
│   ├── GlobalStates.qml  Audio.qml  Brightness.qml  Battery.qml  Media.qml
│   ├── Notifs.qml  Network.qml  Apps.qml  Wallpaper.qml  SystemUsage.qml  Colors.qml
├── widgets/   TIcon.qml  TText.qml  TSurface.qml  TButton.qml
└── rice/
    ├── bar/            r1        ├── controlcenter/  r5
    ├── lock/           r2        ├── osd/  power/    r6
    ├── launcher/       r3        ├── dock/           r7
    ├── notifications/  r4        └── desktop/        r8
```

## Step 1: The Rice singleton

`Theme` decides colors, shapes and fonts. `Rice` decides **which variant of each component** you use. A *profile* sets both at once.

```qml file="services/Rice.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ---- one choice per component (each guide's "layout"/"style" property) ----
    property alias launcher: s.launcher          // "spotlight" | "grid" | "strip"
    property alias notifications: s.notifications // "stack" | "banner" | "toast"
    property alias controlCenter: s.controlCenter // "sidebar" | "dropdown" | "dashboard"
    property alias osd: s.osd                    // "pill" | "side" | "island"
    property alias power: s.power                // "row" | "grid" | "list"
    property alias dock: s.dock                  // "floating" | "shelf" | "side" | "off"
    property alias lock: s.lock                  // "centered" | "editorial" | "minimal"
    property alias clock: s.clock                // desktop clock: "thin" | "stacked" | "words" | "off"
    property alias wallTransition: s.wallTransition // "grow" | "fade" | "slide" | "none"
    property alias profile: s.profile

    // ---- complete rices: theme + every component ----
    readonly property var profiles: ({
        soft:     { theme: "catppuccin", launcher: "spotlight", notifications: "stack",  controlCenter: "sidebar",   osd: "pill",
                    power: "row",  dock: "floating", lock: "centered",  clock: "thin",    wallTransition: "grow" },
        material: { theme: "material",   launcher: "grid",      notifications: "stack",  controlCenter: "dropdown",  osd: "pill",
                    power: "grid", dock: "off",      lock: "editorial", clock: "stacked", wallTransition: "fade" },
        glass:    { theme: "glass",      launcher: "spotlight", notifications: "banner", controlCenter: "dashboard", osd: "island",
                    power: "row",  dock: "floating", lock: "centered",  clock: "thin",    wallTransition: "grow" },
        cyber:    { theme: "neon",       launcher: "strip",     notifications: "toast",  controlCenter: "sidebar",   osd: "side",
                    power: "list", dock: "side",     lock: "minimal",   clock: "words",   wallTransition: "slide" },
        nordic:   { theme: "nord",       launcher: "spotlight", notifications: "stack",  controlCenter: "dropdown",  osd: "pill",
                    power: "row",  dock: "shelf",    lock: "minimal",   clock: "off",     wallTransition: "fade" },
        retro:    { theme: "gruvbox",    launcher: "grid",      notifications: "toast",  controlCenter: "dashboard", osd: "side",
                    power: "grid", dock: "floating", lock: "editorial", clock: "stacked", wallTransition: "none" }
    })

    function apply(name: string): void {
        const p = profiles[name]
        if (!p) return
        Theme.style = p.theme
        for (const k of Object.keys(p)) if (k !== "theme") s[k] = p[k]
        s.profile = name
    }

    FileView {
        path: Quickshell.statePath("rice.json")
        printErrors: false
        watchChanges: true
        onFileChanged: reload()                 // edit rice.json by hand and the shell follows
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: s
            property string profile: "soft"
            property string launcher: "spotlight"
            property string notifications: "stack"
            property string controlCenter: "sidebar"
            property string osd: "pill"
            property string power: "row"
            property string dock: "floating"
            property string lock: "centered"
            property string clock: "thin"
            property string wallTransition: "grow"
        }
    }

    IpcHandler {
        target: "rice"
        function profile(name: string): void { root.apply(name) }
        function next(): void { const k = Object.keys(root.profiles); root.apply(k[(k.indexOf(s.profile) + 1) % k.length]) }
        function set(key: string, value: string): void { if (key in s) s[key] = value }
        function get(): string { return JSON.stringify({ theme: Theme.style, profile: s.profile, launcher: s.launcher, dock: s.dock }) }
        function list(): string { return Object.keys(root.profiles).join(" ") }
    }
}
```

```bash
qs -c myshell ipc call rice profile cyber          # the whole desktop becomes the cyber rice
qs -c myshell ipc call rice next                   # cycle through complete rices
qs -c myshell ipc call rice set launcher grid      # change one component only
qs -c myshell ipc call theme set nord              # change only the colors/shape, keep the layouts
```

> [!NOTE] Mix and match
> A profile is just a starting point. After `rice profile glass` you can still `rice set dock off`, and the choice is saved in `rice.json`.

<!-- ex:## Step 1 -->
::: exercise warm | Your own profile
Add a profile named after yourself that mixes components from different rices, and switch to it with IPC.
:::


## Step 2: A dynamic theme from your wallpaper

Add a seventh preset, `dynamic`, built from matugen's `Colors` ([[ch:44-theming]]) or, without matugen, from `WallpaperAccent` ([[ch:r8-desktop]]). Shapes and fonts come from a base preset you choose.

Change these lines in `services/Theme.qml`:

```qml file="services/Theme.qml (changes)"
    property string style: "catppuccin"
    property string dynamicBase: "material"            // shape/fonts/layout for the dynamic preset

    // colors from matugen's Colors singleton, shape from the base preset
    readonly property var dynamicPreset: Object.assign({}, presets[dynamicBase], {
        bg: Colors.surface, surface: Colors.surfaceContainerHigh, surfaceHi: Colors.surfaceContainerHighest,
        fg: Colors.onSurface, fgDim: Colors.onSurfaceVariant,
        accent: Colors.primary, accent2: Colors.tertiary, onAccent: Colors.onPrimary,
        bad: Colors.error, borderColor: Colors.outlineVariant
    })
    // without matugen, use the quantized wallpaper accent instead:
    //   accent: WallpaperAccent.accent, onAccent: "#1e1e2e"

    readonly property var p: style === "dynamic" ? dynamicPreset : (presets[style] ?? presets.catppuccin)
```

Also allow `"dynamic"` in the IPC `set` function (`if (root.presets[name] || name === "dynamic")`) and add a profile for it:

```qml
        wallpaper: { theme: "dynamic", launcher: "spotlight", notifications: "banner", controlCenter: "sidebar", osd: "island",
                     power: "row", dock: "floating", lock: "editorial", clock: "thin", wallTransition: "grow" }
```

Now changing the wallpaper re-runs matugen, `Colors` reloads, and every bar, card and button recolors itself, because they all read `Theme.*`.

<!-- ex:## Step 2 -->
::: exercise practice | Dynamic base
Switch `dynamicBase` from `material` to `neon` and compare: same wallpaper colors, completely different shapes.
:::


## Step 3: Smooth switching

Bindings update instantly, so a theme switch "snaps". Add color animations to the four primitives from [[ch:r0-theme-system]] and the whole shell crossfades:

```qml file="widgets/TSurface.qml (add)"
    Behavior on color { ColorAnimation { duration: Theme.slow } }
    Behavior on radius { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: Theme.slow } }
```

```qml file="widgets/TText.qml (add)"
    Behavior on color { ColorAnimation { duration: Theme.slow } }
```

> [!TIP] Don't animate everything
> Hover colors already have their own fast `Behavior`. Only add the slow ones on the base `color` of primitives, otherwise hovering will feel sluggish. If a component overrides `color` with its own Behavior, the most specific one wins.

<!-- ex:## Step 3 -->
::: exercise practice | Find the snaps
Switch themes and watch for anything that still changes instantly instead of fading. Add a `Behavior` to it, or make it use a primitive.
:::


## Step 4: shell.qml

```qml file="shell.qml"
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell
import QtQuick
import qs.services
import qs.rice.bar
import qs.rice.lock
import qs.rice.launcher
import qs.rice.notifications
import qs.rice.controlcenter
import qs.rice.osd
import qs.rice.power
import qs.rice.dock
import qs.rice.desktop

ShellRoot {
    // ---- desktop layers (r8) ----
    WallpaperLayer { transition: Rice.wallTransition }
    ScreenCorners {}
    LazyLoader {
        active: Rice.clock !== "off"
        DeskClock { screen: Quickshell.screens[0]; style: Rice.clock }
    }
    DeskStats { screen: Quickshell.screens[0] }
    DeskMedia { screen: Quickshell.screens[0] }

    // ---- always-visible chrome ----
    BarWindow {}                                                       // r1: follows Theme.layout itself
    LazyLoader { active: Rice.dock !== "off"; DockWindow { layout: Rice.dock } }   // r7

    // ---- on-demand surfaces ----
    LauncherWindow { layout: Rice.launcher }                           // r3
    NotifPopups { style: Rice.notifications }                          // r4
    ControlCenter { layout: Rice.controlCenter }                       // r5
    OsdWindow { layout: Rice.osd }                                     // r6
    PowerMenu { layout: Rice.power }                                   // r6
    Lock { layout: Rice.lock }                                         // r2

    Component.onCompleted: Notifs.init()                               // start the notification server at login
}
```

Each guide's component exposes one `layout` or `style` property, so `shell.qml` just passes the `Rice` choice through. Switching a profile changes those properties, and every component rebuilds itself with the new arrangement.

<!-- ex:## Step 4 -->
::: exercise practice | Per-monitor dock
Show the dock only on your main monitor: wrap `DockWindow`'s model to `Quickshell.screens.filter(s => s.name === "DP-1")`.
:::


## Step 5: Compositor glue (Hyprland)

The shell does its part. The compositor needs a few lines too: blur behind translucent surfaces and keybinds that call IPC.

```ini file="~/.config/hypr/hyprland.conf"
# blur behind shell surfaces (needed for the glass preset)
layerrule = blur, quickshell:.*
layerrule = ignorealpha 0.3, quickshell:.*
# no blur/animation for the click-through ones
layerrule = noanim, quickshell:(osd|corners|wallpaper)

# keybinds → IPC
bind = SUPER, Space,  exec, qs -c myshell ipc call shell toggle launcher
bind = SUPER, N,      exec, qs -c myshell ipc call shell toggle controlCenter
bind = SUPER, Escape, exec, qs -c myshell ipc call shell toggle session
bind = SUPER, L,      exec, qs -c myshell ipc call lock lock
bind = SUPER, T,      exec, qs -c myshell ipc call rice next
bind = SUPER SHIFT, T, exec, qs -c myshell ipc call theme next

# the shell owns these surfaces' gaps
general { gaps_out = 8 }
```

> [!WARNING] Rule syntax changes
> Hyprland has changed its rule syntax more than once (and newer versions can be configured in Lua, see [[ch:40-compositors]]). If a `layerrule` line errors, check the wiki for your version. The namespaces (`quickshell:bar`, `quickshell:osd`…) come from each window's `WlrLayershell.namespace`, so the rules stay valid whatever the syntax.

The `shell` IPC target comes from `GlobalStates` ([[ch:46-state]]): `toggle <panel>` flips `<panel>Open`. The `lock` target comes from the [[ch:r2-lockscreen]] guide; `rice` and `theme` come from this part.

## The six rices

<div class="preview"><svg width="680" height="380" viewBox="0 0 680 380"><g font-size="10"><g transform="translate(5 5)"><rect width="215" height="160" rx="8" fill="#302d41"/><rect x="8" y="6" width="199" height="16" rx="8" fill="#1e1e2e"/><circle cx="20" cy="14" r="4" fill="#cba6f7"/><rect x="90" y="9" width="36" height="10" rx="5" fill="#313244"/><rect x="55" y="40" width="105" height="64" rx="12" fill="#1e1e2e"/><rect x="63" y="48" width="89" height="12" rx="6" fill="#313244"/><rect x="63" y="66" width="89" height="10" rx="4" fill="#45365e"/><rect x="65" y="136" width="85" height="18" rx="9" fill="#1e1e2e"/><text x="107" y="178" fill="#cdd6f4" text-anchor="middle" font-weight="700">soft</text></g><g transform="translate(232 5)"><rect width="215" height="160" rx="8" fill="#1d1b20"/><rect width="215" height="20" fill="#211f26"/><rect x="8" y="5" width="24" height="10" rx="5" fill="#d0bcff"/><rect x="120" y="24" width="90" height="80" rx="16" fill="#211f26"/><rect x="128" y="32" width="36" height="18" rx="9" fill="#d0bcff"/><rect x="168" y="32" width="36" height="18" rx="9" fill="#2b2930"/><text x="16" y="70" font-size="26" font-weight="900" fill="#d0bcff">10</text><text x="16" y="94" font-size="26" font-weight="900" fill="#e6e0e9">42</text><text x="107" y="178" fill="#cdd6f4" text-anchor="middle" font-weight="700">material</text></g><g transform="translate(459 5)"><rect width="215" height="160" rx="8" fill="#3a5a8c"/><rect x="8" y="6" width="199" height="16" rx="8" fill="#ffffff22" stroke="#ffffff44"/><rect x="72" y="26" width="70" height="20" rx="10" fill="#000"/><rect x="40" y="58" width="135" height="60" rx="14" fill="#ffffff1a" stroke="#ffffff40"/><rect x="65" y="136" width="85" height="18" rx="9" fill="#ffffff22" stroke="#ffffff44"/><text x="107" y="178" fill="#cdd6f4" text-anchor="middle" font-weight="700">glass</text></g><g transform="translate(5 195)"><rect width="215" height="160" rx="8" fill="#0a0a12"/><rect width="215" height="18" fill="#14142a" stroke="#00f0ff66"/><text x="8" y="13" fill="#00f0ff" font-family="monospace">[1] 2 3</text><rect width="215" height="18" y="20" fill="#14142a"/><rect x="4" y="23" width="40" height="12" fill="#00f0ff"/><rect x="6" y="50" width="20" height="90" fill="#14142a" stroke="#00f0ff66"/><text x="50" y="90" font-family="monospace" font-size="14" fill="#00f0ff">it's ten</text><text x="50" y="108" font-family="monospace" font-size="14" fill="#ff2bd6">forty-two</text><text x="107" y="178" fill="#cdd6f4" text-anchor="middle" font-weight="700">cyber</text></g><g transform="translate(232 195)"><rect width="215" height="160" rx="8" fill="#4c566a"/><rect width="215" height="18" fill="#2e3440"/><rect x="8" y="5" width="30" height="8" rx="3" fill="#88c0d0"/><rect x="65" y="30" width="85" height="50" rx="6" fill="#2e3440"/><rect x="0" y="138" width="215" height="22" fill="#2e3440"/><g fill="#3b4252"><rect x="70" y="142" width="14" height="14" rx="3"/><rect x="88" y="142" width="14" height="14" rx="3"/><rect x="106" y="142" width="14" height="14" rx="3"/><rect x="124" y="142" width="14" height="14" rx="3"/></g><text x="107" y="178" fill="#cdd6f4" text-anchor="middle" font-weight="700">nordic</text></g><g transform="translate(459 195)"><rect width="215" height="160" rx="8" fill="#504945"/><rect x="6" y="6" width="40" height="16" rx="6" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="88" y="6" width="40" height="16" rx="6" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="168" y="6" width="40" height="16" rx="6" fill="#282828" stroke="#504945" stroke-width="2"/><text x="14" y="70" font-size="26" font-weight="900" fill="#fe8019">10</text><text x="14" y="94" font-size="26" font-weight="900" fill="#ebdbb2">42</text><rect x="110" y="40" width="96" height="70" rx="10" fill="#282828"/><text x="107" y="178" fill="#cdd6f4" text-anchor="middle" font-weight="700">retro</text></g></g></svg></div>

| Profile | Theme | Launcher | Notifications | Control center | OSD | Dock | Lock | Desktop clock |
|---|---|---|---|---|---|---|---|---|
| soft | catppuccin (floating bar) | spotlight | stack | sidebar | pill | floating | centered | thin |
| material | material (full bar) | grid | stack | dropdown | pill | off | editorial | stacked |
| glass | glass (floating bar) | spotlight | banner | dashboard | island | floating | centered | thin |
| cyber | neon (full bar) | strip | toast | sidebar | side | side | minimal | words |
| nordic | nord (full bar) | spotlight | stack | dropdown | pill | shelf | minimal | off |
| retro | gruvbox (islands) | grid | toast | dashboard | side | floating | editorial | stacked |

## Step 6: Make your own rice

1. **Start from a mood**, not from code: collect 3 screenshots you love and note the colors, corner radius, density and fonts.
2. **Add a theme preset** to `Theme.presets`: 11 colors, 2 radii, border, opacity, gap, 3 fonts, glow, bar layout. Test it with `ipc call theme set <name>`.
3. **Pick one variant per component** with `ipc call rice set …` until it feels right.
4. **Save it as a profile** in `Rice.profiles`.
5. **Change one module** if no variant fits. Each guide's modules are small files; copy one, rename it, and change it.
6. **Polish:** walk through every guide's checklist with your new rice.
7. **Screenshot it** with the bar, an open launcher, a notification and the control center visible; that's what r/unixporn wants to see.

<!-- ex:## Step 6 -->
::: exercise project | Ship your rice
Make your own complete rice with this part's system, then share it: README with screenshots of every component, an install script ([[ch:71-sharing]]), and your profile as the default in `rice.json`.
:::


## Final checklist: a complete rice

- [ ] One source of truth for colors/shape/fonts (`Theme`), one for layouts (`Rice`). No hard-coded colors in components.
- [ ] Every surface has a namespace, so the compositor can blur or animate it.
- [ ] Keyboard access everywhere: launcher, power menu, lock screen, control center (Esc closes).
- [ ] Multi-monitor: bars and wallpapers per screen; popups on the focused screen.
- [ ] Nothing flashes at startup (OSD guard, `LazyLoader` for heavy windows).
- [ ] The lock screen is safe: it never unlocks on a crash, and IPC can only lock, not unlock.
- [ ] Switching profiles and themes is live and smooth; choices survive restarts.
- [ ] Performance: idle CPU near zero (no constant animations when hidden, [[ch:67-performance]]).

> [!NOTE] Code status
> The QML in this part follows the APIs documented in the reference section. Your compositor, Qt version and installed services can differ, so if something errors, check the reference page for that type and [[ch:66-debugging]].
