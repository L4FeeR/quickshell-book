# Ricing: The Process and a Switchable Theme System

Parts VI and the Widget Gallery show how to **build** components. This part is about **ricing** them: designing how each piece looks and feels, module by module, and making a whole desktop look like *one* coherent design. Every guide follows the same structure:

1. **Anatomy**: the pieces the component is made of.
2. **Module by module**: each piece as its own file, with code and explanation.
3. **Assembly**: putting the modules together.
4. **Style variants**: the same modules restyled into very different looks.
5. **Polish checklist**: the details that separate "works" from "riced".

Everything in this part reads its colors, shapes and fonts from one **switchable theme** defined on this page. Change one word and every component restyles itself.

## The ricing process

| Step | What you do | Output |
|---|---|---|
| 1. Moodboard | Collect 5–10 screenshots you love (r/unixporn, end-4, Caelestia, Dribbble) and note what you like: shapes, spacing, colors, motion | a list like "floating islands, big rounded corners, pastel, soft shadows" |
| 2. Palette | Pick a base palette or generate one from a wallpaper ([[ch:44-theming]]) | ~10 named colors |
| 3. Shape language | Decide corner radius, border use, spacing scale, density | radius 6 / 12 / 20, gaps 4 / 8 / 14 |
| 4. Type | One UI font, one mono font, one icon font; 4–5 sizes | Inter, JetBrains Mono, Material Symbols |
| 5. Motion | Durations and curves ([[ch:a0-overview]]) | fast 150 ms, normal 250 ms, OutCubic |
| 6. Components | Build each part with those tokens only | bar, lock, launcher… |
| 7. Consistency pass | Compare parts side by side; fix anything that doesn't match | a coherent rice |

> [!TIP] Constraints make rices look good
> The best rices use **few** values: one accent color, two or three radii, one spacing scale. When everything comes from the same small set of tokens, the result looks designed even if each piece is simple.

## The Theme singleton

Create this file once. All guides in this part use `Theme.*` for every color, radius, font and duration.

```qml file="services/Theme.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ---------------------------------------------------------------
    // Pick the active style here (or switch at runtime via IPC below)
    // ---------------------------------------------------------------
    property string style: "catppuccin"

    readonly property var presets: ({
        catppuccin: {                                   // soft pastel, floating, rounded
            bg: "#1e1e2e", surface: "#313244", surfaceHi: "#45475a", fg: "#cdd6f4", fgDim: "#a6adc8",
            accent: "#cba6f7", accent2: "#89b4fa", onAccent: "#1e1e2e", ok: "#a6e3a1", warn: "#f9e2af", bad: "#f38ba8",
            radius: 14, radiusSmall: 8, border: 0, borderColor: "#45475a", barOpacity: 0.92, gap: 8,
            font: "Inter", mono: "JetBrains Mono", icons: "Material Symbols Rounded", glow: false, layout: "floating"
        },
        material: {                                     // Material You: shape morphs, tonal surfaces
            bg: "#141218", surface: "#211f26", surfaceHi: "#2b2930", fg: "#e6e0e9", fgDim: "#cac4d0",
            accent: "#d0bcff", accent2: "#ccc2dc", onAccent: "#381e72", ok: "#b5ccb9", warn: "#efb8c8", bad: "#f2b8b5",
            radius: 20, radiusSmall: 12, border: 0, borderColor: "#49454f", barOpacity: 1.0, gap: 8,
            font: "Roboto Flex", mono: "JetBrains Mono", icons: "Material Symbols Rounded", glow: false, layout: "full"
        },
        glass: {                                        // translucent, blurred, thin light borders
            bg: "#1a1b26", surface: "#ffffff1a", surfaceHi: "#ffffff2e", fg: "#ffffff", fgDim: "#ffffffaa",
            accent: "#7aa2f7", accent2: "#bb9af7", onAccent: "#0b0d17", ok: "#9ece6a", warn: "#e0af68", bad: "#f7768e",
            radius: 18, radiusSmall: 10, border: 1, borderColor: "#ffffff30", barOpacity: 0.45, gap: 8,
            font: "Inter", mono: "JetBrains Mono", icons: "Material Symbols Rounded", glow: false, layout: "floating"
        },
        neon: {                                         // cyberpunk: dark, sharp, glowing accents
            bg: "#0a0a12", surface: "#14142a", surfaceHi: "#1f1f3d", fg: "#e0e0ff", fgDim: "#8888bb",
            accent: "#00f0ff", accent2: "#ff2bd6", onAccent: "#0a0a12", ok: "#39ff14", warn: "#ffe600", bad: "#ff2b55",
            radius: 2, radiusSmall: 0, border: 1, borderColor: "#00f0ff66", barOpacity: 0.95, gap: 6,
            font: "JetBrains Mono", mono: "JetBrains Mono", icons: "Material Symbols Sharp", glow: true, layout: "full"
        },
        nord: {                                         // calm, flat, minimal
            bg: "#2e3440", surface: "#3b4252", surfaceHi: "#434c5e", fg: "#eceff4", fgDim: "#d8dee9",
            accent: "#88c0d0", accent2: "#81a1c1", onAccent: "#2e3440", ok: "#a3be8c", warn: "#ebcb8b", bad: "#bf616a",
            radius: 6, radiusSmall: 4, border: 0, borderColor: "#4c566a", barOpacity: 1.0, gap: 6,
            font: "Inter", mono: "JetBrains Mono", icons: "Material Symbols Outlined", glow: false, layout: "full"
        },
        gruvbox: {                                      // warm retro, chunky islands
            bg: "#282828", surface: "#3c3836", surfaceHi: "#504945", fg: "#ebdbb2", fgDim: "#bdae93",
            accent: "#fe8019", accent2: "#fabd2f", onAccent: "#282828", ok: "#b8bb26", warn: "#fabd2f", bad: "#fb4934",
            radius: 10, radiusSmall: 6, border: 2, borderColor: "#504945", barOpacity: 1.0, gap: 8,
            font: "Iosevka", mono: "Iosevka", icons: "Material Symbols Rounded", glow: false, layout: "islands"
        }
    })
    readonly property var p: presets[style] ?? presets.catppuccin

    // ---- colors ----
    readonly property color bg: p.bg
    readonly property color surface: p.surface
    readonly property color surfaceHi: p.surfaceHi
    readonly property color fg: p.fg
    readonly property color fgDim: p.fgDim
    readonly property color accent: p.accent
    readonly property color accent2: p.accent2
    readonly property color onAccent: p.onAccent
    readonly property color ok: p.ok
    readonly property color warn: p.warn
    readonly property color bad: p.bad
    readonly property color borderColor: p.borderColor
    readonly property color barBg: Qt.rgba(bg.r, bg.g, bg.b, p.barOpacity)

    // ---- shape & layout ----
    readonly property int radius: p.radius
    readonly property int radiusSmall: p.radiusSmall
    readonly property int border: p.border
    readonly property int gap: p.gap
    readonly property string layout: p.layout          // "full" | "floating" | "islands"
    readonly property bool glow: p.glow
    readonly property int barHeight: 38

    // ---- type ----
    readonly property string font: p.font
    readonly property string mono: p.mono
    readonly property string icons: p.icons
    readonly property int textSmall: 11
    readonly property int text: 13
    readonly property int textLarge: 16
    readonly property int textHuge: 32

    // ---- motion ----
    readonly property int fast: 150
    readonly property int normal: 250
    readonly property int slow: 400

    // helper: same color, new alpha
    function alpha(c: color, a: real): color { return Qt.rgba(c.r, c.g, c.b, a) }

    // ---- remember the choice across restarts, switch via IPC ----
    FileView {
        path: Quickshell.statePath("theme.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()
        JsonAdapter { id: saved; property string style: "catppuccin" }
        onLoaded: root.style = saved.style
    }
    onStyleChanged: saved.style = style
    IpcHandler {
        target: "theme"
        function set(name: string): void { if (root.presets[name]) root.style = name }
        function next(): void { const k = Object.keys(root.presets); root.style = k[(k.indexOf(root.style) + 1) % k.length] }
        function get(): string { return root.style }
    }
}
```

```bash
qs -c myshell ipc call theme set neon      # switch the whole shell to the neon style
qs -c myshell ipc call theme next          # cycle through styles
```

> [!NOTE] Theme vs Colors
> In Part V the palette came from your wallpaper via matugen (`Colors`). The two combine well: keep `Theme` for shape, fonts and layout, and point its color values at `Colors.*` when a `"dynamic"` preset is selected. [[ch:r9-assemble]] shows how.

<!-- ex:## The Theme singleton -->
::: exercise warm | Your own preset
Add a seventh preset called `rosepine` (colors: bg `#191724`, surface `#1f1d2e`, surfaceHi `#26233a`, fg `#e0def4`, fgDim `#908caa`, accent `#c4a7e7`, accent2 `#9ccfd8`, onAccent `#191724`, ok `#31748f`, warn `#f6c177`, bad `#eb6f92`). Switch to it with IPC.
--- hint
Copy the `catppuccin` entry, rename the key and change the values. Shape fields (`radius`, `layout`…) are up to you.
--- solution
```qml
rosepine: {
    bg: "#191724", surface: "#1f1d2e", surfaceHi: "#26233a", fg: "#e0def4", fgDim: "#908caa",
    accent: "#c4a7e7", accent2: "#9ccfd8", onAccent: "#191724", ok: "#31748f", warn: "#f6c177", bad: "#eb6f92",
    radius: 12, radiusSmall: 8, border: 0, borderColor: "#26233a", barOpacity: 0.95, gap: 8,
    font: "Inter", mono: "JetBrains Mono", icons: "Material Symbols Rounded", glow: false, layout: "floating"
},
```
```bash
qs -c myshell ipc call theme set rosepine
```
:::

::: exercise practice | A derived color
Add `readonly property color accentSoft` to `Theme`: the accent at 18% opacity. Use it as the background of a selected item.
--- solution
```qml
readonly property color accentSoft: alpha(accent, 0.18)
```
Derived values belong in `Theme`, so every component computes them the same way.
:::


## Shared primitives

Four tiny components every guide uses. Put them in `widgets/`.

```qml file="widgets/TIcon.qml"
import QtQuick
import qs.services

// Material Symbols icon in the theme's icon font
Text {
    property string icon
    property real fill: 0
    property int size: 18
    text: icon
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill })
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    Behavior on fill { NumberAnimation { duration: Theme.fast } }
    Behavior on color { ColorAnimation { duration: Theme.normal } }
}
```

```qml file="widgets/TText.qml"
import QtQuick
import qs.services

Text {
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.text
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    Behavior on color { ColorAnimation { duration: Theme.normal } }
}
```

```qml file="widgets/TSurface.qml"
import QtQuick
import QtQuick.Effects
import qs.services

// A themed panel background: color, radius, optional border and glow
Rectangle {
    property bool raised: false
    color: Theme.surface
    radius: Theme.radius
    border.width: Theme.border
    border.color: Theme.borderColor
    Behavior on color { ColorAnimation { duration: Theme.normal } }
    layer.enabled: Theme.glow || raised
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.glow ? Theme.accent : "black"
        shadowOpacity: Theme.glow ? 0.5 : 0.35
        shadowBlur: Theme.glow ? 0.7 : 0.6
        shadowVerticalOffset: Theme.glow ? 0 : 4
        autoPaddingEnabled: true
    }
}
```

```qml file="widgets/TButton.qml"
import QtQuick
import qs.services

// Round icon button with hover layer and toggled shape morph
Rectangle {
    id: root
    property string icon
    property bool toggled: false
    property int size: 30
    signal clicked()
    signal rightClicked()
    implicitWidth: size; implicitHeight: size
    radius: toggled ? Theme.radiusSmall : size / 2
    color: toggled ? Theme.accent : hover.hovered ? Theme.surfaceHi : "transparent"
    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    TIcon { anchors.centerIn: parent; icon: root.icon; size: root.size * 0.6; fill: root.toggled ? 1 : 0
            color: root.toggled ? Theme.onAccent : Theme.fg }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: root.rightClicked() }
    scale: press.pressed ? 0.9 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    TapHandler { id: press }
}
```

<!-- ex:## Shared primitives -->
::: exercise practice | A TChip primitive
Write `widgets/TChip.qml`: an icon + text pill built from `TIcon` and `TText`, with a `toggled` state that fills it with the accent.
--- solution
```qml
import QtQuick
import qs.services
Rectangle {
    id: chip
    property string icon
    property string text
    property bool toggled: false
    signal clicked()
    implicitWidth: row.implicitWidth + 20; implicitHeight: 28
    radius: Theme.style === "neon" ? 0 : height / 2
    color: toggled ? Theme.accent : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Row { id: row; anchors.centerIn: parent; spacing: 6
        TIcon { icon: chip.icon; size: 16; color: chip.toggled ? Theme.onAccent : Theme.fg }
        TText { text: chip.text; color: chip.toggled ? Theme.onAccent : Theme.fg } }
    TapHandler { onTapped: chip.clicked() }
}
```
:::


## The six styles at a glance

<div class="preview"><svg width="660" height="260" viewBox="0 0 660 260"><g font-family="Inter" font-size="11"><g transform="translate(10 10)"><rect width="200" height="110" rx="12" fill="#313244" opacity=".4"/><rect x="10" y="10" width="180" height="24" rx="12" fill="#1e1e2e"/><circle cx="26" cy="22" r="4" fill="#cba6f7"/><circle cx="38" cy="22" r="3" fill="#585b70"/><rect x="80" y="16" width="40" height="12" rx="6" fill="#313244"/><rect x="140" y="16" width="40" height="12" rx="6" fill="#313244"/><rect x="40" y="48" width="120" height="44" rx="14" fill="#1e1e2e"/><rect x="52" y="60" width="50" height="20" rx="10" fill="#cba6f7"/><text x="100" y="105" fill="#cdd6f4" text-anchor="middle">catppuccin</text></g><g transform="translate(230 10)"><rect width="200" height="110" rx="12" fill="#211f26" opacity=".5"/><rect x="0" y="0" width="200" height="28" fill="#141218"/><rect x="10" y="7" width="34" height="14" rx="7" fill="#d0bcff"/><rect x="40" y="44" width="120" height="48" rx="20" fill="#211f26"/><rect x="52" y="56" width="56" height="24" rx="12" fill="#d0bcff"/><text x="100" y="105" fill="#e6e0e9" text-anchor="middle">material</text></g><g transform="translate(450 10)"><defs><linearGradient id="gl" x1="0" x2="1"><stop offset="0" stop-color="#7aa2f7"/><stop offset="1" stop-color="#bb9af7"/></linearGradient></defs><rect width="200" height="110" rx="12" fill="url(#gl)" opacity=".5"/><rect x="10" y="10" width="180" height="24" rx="12" fill="#ffffff" opacity=".18" stroke="#fff" stroke-opacity=".4"/><rect x="40" y="46" width="120" height="44" rx="18" fill="#fff" opacity=".18" stroke="#fff" stroke-opacity=".4"/><text x="100" y="105" fill="#fff" text-anchor="middle">glass</text></g><g transform="translate(10 140)"><rect width="200" height="110" fill="#0a0a12"/><rect x="0" y="0" width="200" height="26" fill="#0a0a12" stroke="#00f0ff" stroke-opacity=".6"/><rect x="8" y="8" width="24" height="10" fill="#00f0ff"/><rect x="40" y="46" width="120" height="44" fill="#14142a" stroke="#00f0ff"/><rect x="50" y="58" width="44" height="20" fill="#ff2bd6"/><text x="100" y="105" fill="#00f0ff" text-anchor="middle" font-family="monospace">neon</text></g><g transform="translate(230 140)"><rect width="200" height="110" rx="8" fill="#3b4252" opacity=".5"/><rect x="0" y="0" width="200" height="24" fill="#2e3440"/><rect x="10" y="7" width="20" height="10" rx="3" fill="#88c0d0"/><rect x="40" y="44" width="120" height="44" rx="6" fill="#3b4252"/><rect x="50" y="56" width="44" height="20" rx="4" fill="#88c0d0"/><text x="100" y="105" fill="#eceff4" text-anchor="middle">nord</text></g><g transform="translate(450 140)"><rect width="200" height="110" rx="8" fill="#3c3836" opacity=".5"/><rect x="10" y="8" width="44" height="22" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="78" y="8" width="44" height="22" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="146" y="8" width="44" height="22" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="40" y="44" width="120" height="44" rx="10" fill="#282828" stroke="#504945" stroke-width="2"/><rect x="50" y="56" width="44" height="20" rx="6" fill="#fe8019"/><text x="100" y="105" fill="#ebdbb2" text-anchor="middle">gruvbox</text></g></g></svg></div>

| Style | Mood | Signature details |
|---|---|---|
| **catppuccin** | soft, friendly | pastel accent, floating rounded bar, no borders |
| **material** | modern Google | full-width bar, tonal surfaces, big radii, shape morphs |
| **glass** | airy, premium | translucent surfaces, compositor blur, thin light borders |
| **neon** | cyberpunk | near-black, sharp corners, cyan/magenta glow, monospace |
| **nord** | calm, focused | flat, low contrast, small radii, outlined icons |
| **gruvbox** | warm retro | separate "island" modules, thick borders, orange accent |

> [!TRY] Make your own preset
> Copy one preset, rename it, and change five values: `accent`, `radius`, `border`, `font` and `layout`. You'll be surprised how different the result feels.

## Folder layout used in this part

```text
~/.config/quickshell/myshell/
├── shell.qml
├── services/   Theme.qml  (+ Audio, Battery, Media, Notifs… from earlier parts)
├── widgets/    TIcon.qml TText.qml TSurface.qml TButton.qml
└── rice/
    ├── bar/            BarWindow.qml  Logo.qml  Workspaces.qml  WindowTitle.qml  Clock.qml  …
    ├── lock/           Lock.qml  LockBackground.qml  LockClock.qml  LockInput.qml …
    ├── launcher/  notifications/  controlcenter/  osd/  power/  dock/  desktop/
```

Each guide's files go in their own `rice/<component>/` folder; `import qs.rice.bar` and so on.

<!-- ex:## Folder layout used in this part -->
## Practice

::: exercise challenge | Style switcher widget
Build a small window with one button per preset (a `Repeater` over `Object.keys(Theme.presets)`) that switches the style. Each button shows the preset's accent color as a dot.
--- solution
```qml
Row { spacing: 6
    Repeater { model: Object.keys(Theme.presets)
        TButton {
            required property string modelData
            icon: "palette"; toggled: Theme.style === modelData
            onClicked: Theme.style = modelData
            Rectangle { width: 8; height: 8; radius: 4; anchors { right: parent.right; top: parent.top }
                        color: Theme.presets[parent.modelData].accent } } } }
```
:::

