# Ricing the Desktop: Wallpaper, Widgets, Corners

Your desktop is what you see when no window is open, and in every screenshot. This guide covers the layers *under* your windows: an animated wallpaper with transitions, desktop widgets (clock, stats, quote, now playing), rounded screen corners, and a wallpaper-reactive accent.

**Services:** `Wallpaper` ([[ch:60-proj-wallpaper]]) and `SystemUsage` ([[ch:62-proj-desktop]]).

## Anatomy: the layers

<div class="preview"><svg width="520" height="250" viewBox="0 0 520 250"><g transform="translate(40 20)"><rect x="40" y="120" width="360" height="100" rx="4" fill="#45365e" opacity=".9"/><text x="410" y="175" fill="#cdd6f4" font-size="10">Background: wallpaper</text><rect x="25" y="85" width="360" height="100" rx="4" fill="none" stroke="#cba6f7" stroke-dasharray="4 3"/><text x="60" y="120" fill="#cba6f7" font-size="11" font-weight="700">10:42</text><rect x="300" y="100" width="60" height="40" rx="6" fill="#1e1e2eaa"/><text x="395" y="140" fill="#cdd6f4" font-size="10">Bottom: widgets</text><rect x="10" y="50" width="360" height="100" rx="4" fill="#1e1e2e" opacity=".55"/><text x="380" y="100" fill="#cdd6f4" font-size="10">windows</text><rect x="-5" y="15" width="360" height="100" rx="4" fill="none" stroke="#a6adc8"/><path d="M-5 27 Q-5 15 7 15" stroke="#f38ba8" stroke-width="3" fill="none"/><path d="M343 15 Q355 15 355 27" stroke="#f38ba8" stroke-width="3" fill="none"/><text x="365" y="60" fill="#cdd6f4" font-size="10">Overlay: corners</text></g></svg></div>

| Layer | Wayland layer | Module(s) |
|---|---|---|
| Wallpaper | `Background` | `WallpaperLayer.qml`, `Transition*.qml` |
| Desktop widgets | `Bottom` | `DeskWidget.qml`, `DeskClock.qml`, `DeskStats.qml`, `DeskQuote.qml`, `DeskMedia.qml` |
| Screen corners | `Overlay` | `ScreenCorners.qml` |

## Module 1: Wallpaper with transitions

<div class="preview"><svg width="560" height="120" viewBox="0 0 560 120"><defs><clipPath id="wc"><circle cx="90" cy="55" r="0"><animate attributeName="r" values="0;110;110" keyTimes="0;.6;1" dur="3s" repeatCount="indefinite"/></circle></clipPath></defs><g font-size="10" text-anchor="middle"><rect x="20" y="10" width="140" height="90" rx="6" fill="#45365e"/><rect x="20" y="10" width="140" height="90" rx="6" fill="#2d6a4f" clip-path="url(#wc)"/><text x="90" y="115" fill="#a6adc8">grow (circle)</text><rect x="210" y="10" width="140" height="90" rx="6" fill="#45365e"/><rect x="210" y="10" width="140" height="90" rx="6" fill="#2d6a4f"><animate attributeName="opacity" values="0;1;1" keyTimes="0;.6;1" dur="3s" repeatCount="indefinite"/></rect><text x="280" y="115" fill="#a6adc8">fade</text><rect x="400" y="10" width="140" height="90" rx="6" fill="#45365e"/><rect y="10" width="140" height="90" rx="6" fill="#2d6a4f"><animate attributeName="x" values="540;400;400" keyTimes="0;.6;1" dur="3s" repeatCount="indefinite"/></rect><rect x="540" y="0" width="20" height="110" fill="var(--bg, #fff)" opacity="0"/><text x="470" y="115" fill="#a6adc8">slide</text></g></svg></div>

Two images stacked: the old one stays visible while the new one loads, then the new one is revealed with the chosen transition.

```qml file="rice/desktop/WallpaperLayer.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.services

Variants {
    id: root
    property string transition: "grow"       // "fade" | "grow" | "slide" | "none"
    property int duration: 900
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Theme.bg
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:wallpaper"

        // old = what's on screen now, next = the incoming image
        Image {
            id: old
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width, win.height)       // decode at screen size, not the full 6K file
            asynchronous: true
            cache: false
        }
        Item {
            id: reveal
            // the "grow" transition clips the new image with a growing circle
            readonly property real maxR: Math.hypot(win.width, win.height)
            property real r: 0
            property real p: 0                                // 0..1 progress for fade/slide
            anchors.fill: parent
            ClippingRectangle {
                visible: root.transition === "grow"
                x: win.width / 2 - reveal.r; y: win.height / 2 - reveal.r
                width: reveal.r * 2; height: reveal.r * 2
                radius: reveal.r
                color: "transparent"
                Image {
                    x: -parent.x; y: -parent.y
                    width: win.width; height: win.height
                    source: next.source; fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(win.width, win.height)
                }
            }
            Image {
                id: next
                visible: root.transition !== "grow"
                width: win.width; height: win.height
                x: root.transition === "slide" ? (1 - reveal.p) * win.width : 0
                opacity: root.transition === "fade" ? reveal.p : 1
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                cache: false
                onStatusChanged: if (status === Image.Ready) anim.restart()
            }
        }
        ParallelAnimation {
            id: anim
            NumberAnimation { target: reveal; property: "r"; from: 0; to: reveal.maxR / 2; duration: root.transition === "none" ? 0 : root.duration; easing.type: Easing.InOutCubic }
            NumberAnimation { target: reveal; property: "p"; from: 0; to: 1; duration: root.transition === "none" ? 0 : root.duration; easing.type: Easing.InOutCubic }
            onFinished: { old.source = next.source; reveal.r = 0; reveal.p = 0 }   // promote "next" to "old"
        }

        readonly property string target: Wallpaper.current ? "file://" + Wallpaper.current : ""
        onTargetChanged: if (target !== next.source.toString()) next.source = target
        Component.onCompleted: { old.source = target; next.source = target }
    }
}
```

> [!TIP] Parallax
> Shift the wallpaper a few pixels per workspace for a parallax effect: give `old` and `next` a `transform: Translate { x: -(Hyprland.focusedWorkspace?.id ?? 1) * 20 }` with a `Behavior` and make the window 200 px wider by using negative margins on the images.

<!-- ex:## Module 1 -->
::: exercise warm | Another transition
Add a `"wipe"` transition that reveals the new wallpaper from left to right using a clipping rectangle whose width animates.
:::


## Module 2: A reusable desktop widget

Every desktop widget shares the same behavior: it lives on the `Bottom` layer, can be dragged with Super held, and remembers its position. This is the `DesktopWidget` from [[ch:62-proj-desktop]], with `real` positions.

```qml file="rice/desktop/DeskWidget.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.services

PanelWindow {
    id: w
    property string widgetId
    property real defaultX: 100
    property real defaultY: 100
    default property alias content: holder.data

    anchors { top: true; left: true }
    margins { left: pos.x; top: pos.y }
    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell:desktop-" + widgetId

    FileView {
        id: file
        path: Quickshell.statePath("desk-" + w.widgetId + ".json")
        printErrors: false
        onAdapterUpdated: writeAdapter()
        JsonAdapter { id: pos; property real x: w.defaultX; property real y: w.defaultY }
    }

    Item { id: holder; anchors.fill: parent }

    // Super + drag to move. The delta is measured inside the window, which moves along with
    // the mouse, so the press point stays under the cursor.
    MouseArea {
        anchors.fill: parent
        property point start
        onPressed: m => { if (!(m.modifiers & Qt.MetaModifier)) { m.accepted = false; return } start = Qt.point(m.x, m.y) }
        onPositionChanged: m => {
            if (!pressed) return
            pos.x = Math.max(0, pos.x + m.x - start.x)
            pos.y = Math.max(0, pos.y + m.y - start.y)
        }
    }
}
```

<!-- ex:## Module 2 -->
::: exercise practice | Snap to grid
Snap widget positions to a 20 px grid when you release the drag.
--- solution
```qml
onReleased: { pos.x = Math.round(pos.x / 20) * 20; pos.y = Math.round(pos.y / 20) * 20 }
```
:::


## Module 3: Desktop clock (three styles)

<div class="preview"><svg width="600" height="150" viewBox="0 0 600 150"><g text-anchor="middle"><text x="100" y="80" font-size="52" font-weight="200" fill="#cdd6f4">10:42</text><text x="100" y="104" font-size="12" fill="#a6adc8">Saturday, 21 November</text><text x="100" y="140" font-size="10" fill="#6c7086">thin</text><text x="300" y="60" font-size="44" font-weight="900" fill="#cba6f7">10</text><text x="300" y="104" font-size="44" font-weight="900" fill="#cdd6f4">42</text><text x="300" y="140" font-size="10" fill="#6c7086">stacked</text><text x="500" y="70" font-size="18" fill="#cdd6f4" font-family="monospace">it's ten</text><text x="500" y="92" font-size="18" fill="#cba6f7" font-family="monospace">forty-two</text><text x="500" y="140" font-size="10" fill="#6c7086">words</text></g></svg></div>

```qml file="rice/desktop/DeskClock.qml"
import Quickshell
import QtQuick
import qs.services
import qs.widgets

DeskWidget {
    id: root
    property string style: "thin"          // "thin" | "stacked" | "words"
    widgetId: "clock"
    defaultX: 80; defaultY: 120
    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property var ones: ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve",
                                 "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
    function words(n) {
        if (n < 20) return ones[n]
        const t = ["", "", "twenty", "thirty", "forty", "fifty"][Math.floor(n / 10)]
        return n % 10 ? t + "-" + ones[n % 10] : t
    }

    Column {
        spacing: 4
        // ---- thin ----
        TText { visible: root.style === "thin"; text: Qt.formatTime(clock.date, "hh:mm"); font.pixelSize: 110; font.weight: Font.ExtraLight }
        TText { visible: root.style === "thin"; text: Qt.formatDate(clock.date, "dddd, d MMMM"); font.pixelSize: 20; color: Theme.fgDim; leftPadding: 8 }
        // ---- stacked ----
        TText { visible: root.style === "stacked"; text: Qt.formatTime(clock.date, "hh"); font.pixelSize: 120; font.weight: Font.Black; color: Theme.accent; lineHeight: 0.8 }
        TText { visible: root.style === "stacked"; text: Qt.formatTime(clock.date, "mm"); font.pixelSize: 120; font.weight: Font.Black; lineHeight: 0.8 }
        // ---- words ----
        TText { visible: root.style === "words"; text: "it's " + root.words(clock.hours % 12 || 12); font.family: Theme.mono; font.pixelSize: 40 }
        TText { visible: root.style === "words"; text: clock.minutes ? root.words(clock.minutes) : "o'clock"; font.family: Theme.mono; font.pixelSize: 40; color: Theme.accent }
    }
}
```

**Ricing choices:** a desktop clock reads best with a **shadow or no background at all**. Add `layer.enabled: true; layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.6 }` to the Column if your wallpaper is bright.

<!-- ex:## Module 3 -->
::: exercise practice | Fuzzy words
Make the `words` clock round to five minutes: "quarter past ten", "half past ten", "twenty to eleven".
:::


## Module 4: Stats card with rings

```qml file="rice/desktop/DeskStats.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.widgets

DeskWidget {
    widgetId: "stats"
    defaultX: 80; defaultY: 420

    component Ring: Item {
        id: ring
        property real value: 0
        property string label
        property string icon
        property color tint: Theme.accent
        implicitWidth: 86; implicitHeight: 86
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath { strokeColor: Theme.alpha(Theme.fg, 0.12); strokeWidth: 7; fillColor: "transparent"
                PathAngleArc { centerX: 43; centerY: 43; radiusX: 37; radiusY: 37; startAngle: 135; sweepAngle: 270 } }
            ShapePath { strokeColor: ring.tint; strokeWidth: 7; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: 43; centerY: 43; radiusX: 37; radiusY: 37; startAngle: 135; sweepAngle: 270 * Math.min(1, ring.value)
                               Behavior on sweepAngle { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } } } }
        }
        Column {
            anchors.centerIn: parent
            TIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: ring.icon; size: 18; color: ring.tint }
            TText { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(ring.value * 100) + "%"; font.bold: true }
        }
        TText { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -4 }
                text: ring.label; font.pixelSize: 10; color: Theme.fgDim }
    }

    TSurface {
        width: row.implicitWidth + 32; height: row.implicitHeight + 32
        color: Theme.alpha(Theme.bg, 0.6)
        radius: Theme.radius + 4
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 14
            Ring { value: SystemUsage.cpu; label: "CPU"; icon: "memory" }
            Ring { value: SystemUsage.ram; label: "RAM"; icon: "memory_alt"; tint: Theme.accent2 }
            Ring { visible: Battery.available; value: Battery.percent; label: "BAT"; icon: Battery.icon
                   tint: Battery.low ? Theme.bad : Theme.ok }
        }
    }
}
```

<!-- ex:## Module 4 -->
::: exercise practice | Disk ring
Add a disk-usage ring from `df --output=pcent / | tail -1`, refreshed every 5 minutes.
:::


## Module 5: Quote and now playing

```qml file="rice/desktop/DeskQuote.qml"
import Quickshell
import QtQuick
import qs.services
import qs.widgets

DeskWidget {
    id: dq
    widgetId: "quote"
    defaultX: 900; defaultY: 760
    readonly property var quotes: [
        ["Simplicity is prerequisite for reliability.", "Edsger W. Dijkstra"],
        ["Make it work, make it right, make it fast.", "Kent Beck"],
        ["The details are not the details. They make the design.", "Charles Eames"]
    ]
    property int i: 0
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: dq.i = (dq.i + 1) % dq.quotes.length }
    Column {
        width: 460; spacing: 6
        TText { width: parent.width; wrapMode: Text.Wrap; text: "“" + quotes[i][0] + "”"; font.pixelSize: 22; font.italic: true }
        TText { text: "— " + quotes[i][1]; color: Theme.accent }
    }
}
```

```qml file="rice/desktop/DeskMedia.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

DeskWidget {
    widgetId: "media"
    defaultX: 80; defaultY: 640
    visible: Media.active !== null
    TSurface {
        width: 340; height: 104
        color: Theme.alpha(Theme.bg, 0.6)
        RowLayout {
            anchors { fill: parent; margins: 12 }
            spacing: 12
            ClippingRectangle {
                implicitWidth: 80; implicitHeight: 80; radius: Theme.radiusSmall; color: Theme.surface
                Image { anchors.fill: parent; source: Media.active?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(160, 160)
                        // slow spin while playing, like a record
                        RotationAnimation on rotation { running: Media.active?.isPlaying ?? false; from: 0; to: 360; duration: 20000; loops: Animation.Infinite } }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                TText { Layout.fillWidth: true; text: Media.active?.trackTitle ?? ""; font.bold: true }
                TText { Layout.fillWidth: true; text: Media.active?.trackArtist ?? ""; color: Theme.fgDim }
                Row { spacing: 4
                    TButton { icon: "skip_previous"; onClicked: Media.active.previous() }
                    TButton { icon: Media.active?.isPlaying ? "pause" : "play_arrow"; toggled: true; onClicked: Media.active.togglePlaying() }
                    TButton { icon: "skip_next"; onClicked: Media.active.next() } }
            }
        }
    }
}
```

> [!NOTE] Rotating square art
> A spinning square looks odd. Set the `ClippingRectangle` radius to `width / 2` to turn the art into a "vinyl" disc for this style.

<!-- ex:## Module 5 -->
::: exercise practice | Quotes from a file
Load the quotes from `~/.config/quickshell/myshell/quotes.json` with a `FileView` instead of hard-coding them.
:::


## Module 6: Screen corners

<div class="preview"><svg width="300" height="160" viewBox="0 0 300 160"><rect x="20" y="10" width="260" height="140" fill="#45365e"/><rect x="20" y="10" width="260" height="22" fill="#1e1e2e"/><path d="M20 32 h18 a18 18 0 0 0 -18 18 z" fill="#1e1e2e"/><path d="M280 32 h-18 a18 18 0 0 1 18 18 z" fill="#1e1e2e"/><path d="M20 150 v-18 a18 18 0 0 0 18 18 z" fill="#000"/><path d="M280 150 v-18 a18 18 0 0 1 -18 18 z" fill="#000"/><text x="150" y="96" fill="#cdd6f4" font-size="10" text-anchor="middle">corners under the bar match the bar color;</text><text x="150" y="110" fill="#cdd6f4" font-size="10" text-anchor="middle">bottom corners are black like a bezel</text></svg></div>

Rounded corners make a flat monitor look like a phone screen. With a full-width bar, corners under the bar in the bar's color make the bar look like it "flows" into the screen edge, a popular end-4 touch.

```qml file="rice/desktop/ScreenCorners.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import qs.services

Variants {
    id: root
    property int size: Theme.radius + 6
    property bool underBar: Theme.layout === "full"      // top corners hang under the bar
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        margins.top: root.underBar ? Theme.barHeight : 0
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}                         // fully click-through
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:corners"

        // one corner: a square minus a quarter circle
        component Corner: Shape {
            property int corner: 0              // 0 TL, 1 TR, 2 BR, 3 BL
            property color tint: "black"
            width: root.size; height: root.size
            preferredRendererType: Shape.CurveRenderer
            rotation: corner * 90
            ShapePath {
                fillColor: tint; strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: root.size; y: 0 }
                PathArc { x: 0; y: root.size; radiusX: root.size; radiusY: root.size; direction: PathArc.Counterclockwise }
                PathLine { x: 0; y: 0 }
            }
        }
        Corner { corner: 0; anchors { top: parent.top; left: parent.left }; tint: root.underBar ? Theme.barBg : "black" }
        Corner { corner: 1; anchors { top: parent.top; right: parent.right }; tint: root.underBar ? Theme.barBg : "black" }
        Corner { corner: 2; anchors { bottom: parent.bottom; right: parent.right } }
        Corner { corner: 3; anchors { bottom: parent.bottom; left: parent.left } }
    }
}
```

> [!WARNING] Corners above fullscreen video
> `Overlay` sits above fullscreen windows too. If you don't want black corners over your movies, hide the window when the focused Hyprland window is fullscreen (`visible: !(Hyprland.focusedWorkspace?.hasFullscreen ?? false)`).

<!-- ex:## Module 6 -->
::: exercise practice | Hide over fullscreen
Hide the corners when the focused window is fullscreen (see the warning above).
:::


## Module 7: Accent from the wallpaper

If you aren't using matugen ([[ch:43-design-system]]), Quickshell can still pick colors from the wallpaper itself with [[ColorQuantizer]]. It splits the image's colors into 2ⁿ groups (`depth` n) and gives you their averages.

```qml file="rice/desktop/WallpaperAccent.qml"
pragma Singleton
import Quickshell
import QtQuick
import qs.services

Singleton {
    id: root
    // the most colorful of the quantized colors, boosted so dull wallpapers still give a usable accent
    readonly property color accent: {
        const cs = q.colors
        if (!cs.length) return Theme.accent
        let best = cs[0]
        for (const c of cs) if (c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5)) > best.hslSaturation * (1 - Math.abs(best.hslLightness - 0.5))) best = c
        return Qt.hsla(best.hslHue, Math.max(0.45, best.hslSaturation), Math.min(0.75, Math.max(0.6, best.hslLightness)), 1)
    }
    ColorQuantizer {
        id: q
        source: Wallpaper.current ? "file://" + Wallpaper.current : ""
        depth: 3            // 8 colors
        rescaleSize: 64     // work on a 64×64 copy: fast and accurate enough
    }
}
```

[[ch:r9-assemble]] shows how to plug this accent into the Theme.

<!-- ex:## Module 7 -->
::: exercise challenge | Live dynamic accent
Bind `Theme`'s accent to `WallpaperAccent.accent` for a `"wallpaper"` preset (see [[ch:r9-assemble]]) and watch the bar recolor when you change wallpaper.
:::


## Assembly

```qml file="rice/desktop/Desktop.qml"
import Quickshell
import QtQuick

Scope {
    WallpaperLayer { transition: "grow" }
    ScreenCorners {}
    DeskClock { screen: Quickshell.screens[0]; style: "thin" }
    DeskStats { screen: Quickshell.screens[0] }
    DeskMedia { screen: Quickshell.screens[0] }
    DeskQuote { screen: Quickshell.screens[0] }
}
```

<div class="preview"><svg width="660" height="190" viewBox="0 0 660 190"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="150" rx="8" fill="#3b2f5c"/><text x="16" y="55" font-size="34" font-weight="200" fill="#fff">10:42</text><text x="18" y="72" fill="#ffffffaa">Saturday</text><text x="105" y="170" fill="#a6adc8" text-anchor="middle">minimal: clock only</text></g><g transform="translate(225 5)"><rect width="210" height="150" rx="8" fill="#2d4a3e"/><rect width="210" height="16" rx="0" fill="#1e1e2e"/><text x="14" y="58" font-size="28" font-weight="900" fill="#a6e3a1">10</text><text x="14" y="84" font-size="28" font-weight="900" fill="#fff">42</text><rect x="110" y="30" width="86" height="40" rx="8" fill="#1e1e2e99"/><circle cx="130" cy="50" r="12" fill="none" stroke="#a6e3a1" stroke-width="4"/><circle cx="160" cy="50" r="12" fill="none" stroke="#89b4fa" stroke-width="4"/><rect x="110" y="80" width="86" height="34" rx="8" fill="#1e1e2e99"/><text x="105" y="170" fill="#a6adc8" text-anchor="middle">dashboard desktop</text></g><g transform="translate(445 5)"><rect width="210" height="150" rx="8" fill="#0a0a12"/><g stroke="#00f0ff33"><line x1="0" y1="40" x2="210" y2="40"/><line x1="0" y1="80" x2="210" y2="80"/><line x1="0" y1="120" x2="210" y2="120"/></g><text x="16" y="70" font-family="monospace" font-size="16" fill="#00f0ff">it's ten</text><text x="16" y="90" font-family="monospace" font-size="16" fill="#ff2bd6">forty-two</text><text x="105" y="170" fill="#a6adc8" text-anchor="middle">neon words</text></g></g></svg></div>

## Polish checklist

- [ ] Wallpaper decodes at screen size (`sourceSize`), never at full resolution.
- [ ] The old wallpaper stays visible until the new one has loaded; transitions are smooth.
- [ ] Widgets sit on the `Bottom` layer (under windows, over the wallpaper) and remember their positions.
- [ ] Text on the desktop stays readable on any wallpaper (shadow or translucent card).
- [ ] Corners are click-through and match the bar color under a full-width bar.
- [ ] Nothing animates constantly while hidden behind windows (the spinning art stops when paused).

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | A desktop scene
Compose a full desktop: wallpaper, one clock style, one card, and corners, all matching your theme. Take a screenshot with no windows open.
:::

