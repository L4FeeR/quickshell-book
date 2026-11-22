# Animations: Loops, Loaders and Ambient Motion

Animations that **repeat**: loading indicators, pulses that signal "live", gentle ambient motion on desktop widgets.

> [!WARN] Loops cost power
> An infinite animation makes Quickshell redraw every frame. **Always** bind `running` to visibility or to the condition it represents (`running: recording && visible`). A forgotten loop can keep your GPU awake all day ([[ch:67-performance]]).

## Pulse

<div class="preview"><svg width="200" height="100" viewBox="0 0 200 100"><circle cx="100" cy="50" r="10" fill="#f38ba8"><animate attributeName="opacity" values="1;.25;1" dur="1.4s" repeatCount="indefinite"/></circle></svg></div>

**What it is.** Opacity fades down and up forever: the universal "this is live" signal.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    property bool active: true
    width: 14; height: 14; radius: 7; color: "#f38ba8"
    SequentialAnimation on opacity {
        running: parent.active && parent.visible
        loops: Animation.Infinite
        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) parent.opacity = 1         // reset when stopped
    }
}
```

**Use for:** recording indicator, mic-in-use dot, low-battery warning, urgent workspace.

## Radar Ping Rings

<div class="preview"><svg width="200" height="120" viewBox="0 0 200 120"><g fill="none" stroke="#a6e3a1" stroke-width="2"><circle cx="100" cy="60" r="8"><animate attributeName="r" values="8;48" dur="2s" repeatCount="indefinite"/><animate attributeName="opacity" values="1;0" dur="2s" repeatCount="indefinite"/></circle><circle cx="100" cy="60" r="8"><animate attributeName="r" values="8;48" dur="2s" begin="1s" repeatCount="indefinite"/><animate attributeName="opacity" values="1;0" dur="2s" begin="1s" repeatCount="indefinite"/></circle></g><circle cx="100" cy="60" r="8" fill="#a6e3a1"/></svg></div>

**What it is.** Rings expand outward from a dot and fade, offset in time so there's always one in flight, like a radar or sonar ping.

```qml file="Demo.qml"
import QtQuick

Item {
    id: root
    width: 120; height: 120
    property color tint: "#a6e3a1"
    Repeater {
        model: 2
        Rectangle {
            id: ring
            required property int index
            anchors.centerIn: parent
            width: 16; height: width; radius: width / 2
            color: "transparent"; border.color: root.tint; border.width: 2
            SequentialAnimation {
                running: root.visible; loops: Animation.Infinite
                PauseAnimation { duration: ring.index * 1000 }          // offset the second ring
                ParallelAnimation {
                    NumberAnimation { target: ring; property: "width"; from: 16; to: 110; duration: 2000; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring; property: "opacity"; from: 1; to: 0; duration: 2000 }
                }
            }
        }
    }
    Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: root.tint }
}
```

**Use for:** "searching" states (Bluetooth scan, Wi-Fi scan), a location or online indicator, an incoming call or alarm.

## Breathing Glow

<div class="preview"><svg width="240" height="110" viewBox="0 0 240 110"><defs><filter id="breath" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="0" dy="0" flood-color="#cba6f7"><animate attributeName="stdDeviation" values="2;10;2" dur="3.5s" repeatCount="indefinite"/></feDropShadow></filter></defs><rect x="70" y="30" width="100" height="50" rx="25" fill="#cba6f7" filter="url(#breath)"/></svg></div>

**What it is.** A slow glow that swells and fades, like breathing. It's calmer than a pulse and good for ambient "idle" states.

```qml file="Demo.qml"
import QtQuick
import QtQuick.Effects

Rectangle {
    id: orb
    width: 120; height: 50; radius: 25; color: "#cba6f7"
    property real glow: 0.2
    SequentialAnimation on glow {
        running: orb.visible; loops: Animation.Infinite
        NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.2; duration: 1800; easing.type: Easing.InOutSine }
    }
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true; shadowColor: "#cba6f7"
        shadowHorizontalOffset: 0; shadowVerticalOffset: 0
        shadowBlur: orb.glow; shadowOpacity: orb.glow
        autoPaddingEnabled: true
    }
}
```

**Use for:** the Dynamic Island while idle, a lock-screen password field waiting for input, an AI-assistant "thinking" orb.

## Arc Spinner

<div class="preview"><svg width="200" height="110" viewBox="0 0 200 110"><g transform="translate(100 55)"><circle r="24" fill="none" stroke="#313244" stroke-width="5"/><circle r="24" fill="none" stroke="#cba6f7" stroke-width="5" stroke-linecap="round" stroke-dasharray="40 151"><animateTransform attributeName="transform" type="rotate" from="0" to="360" dur="1s" repeatCount="indefinite"/><animate attributeName="stroke-dasharray" values="10 151;100 151;10 151" dur="1.6s" repeatCount="indefinite"/></circle></g></svg></div>

**What it is.** A Material-style circular spinner: an arc that rotates while its length grows and shrinks.

```qml file="Demo.qml"
import QtQuick
import QtQuick.Shapes

Item {
    id: spinner
    property bool running: true
    width: 48; height: 48
    property real sweep: 30
    SequentialAnimation on sweep {
        running: spinner.running && spinner.visible; loops: Animation.Infinite
        NumberAnimation { to: 270; duration: 700; easing.type: Easing.InOutCubic }
        NumberAnimation { to: 30; duration: 700; easing.type: Easing.InOutCubic }
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: spinner.running && spinner.visible }
        ShapePath {
            fillColor: "transparent"; strokeColor: "#cba6f7"; strokeWidth: 5; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 24; centerY: 24; radiusX: 20; radiusY: 20; startAngle: 0; sweepAngle: spinner.sweep }
        }
    }
}
```

**Use for:** Wi-Fi connecting, Bluetooth pairing, the lock screen while PAM checks, loading weather.

## Typing Dots

<div class="preview"><svg width="200" height="90" viewBox="0 0 200 90"><rect x="60" y="25" width="80" height="40" rx="20" fill="#313244"/><g fill="#cdd6f4"><circle cx="82" cy="45" r="5"><animate attributeName="cy" values="45;37;45;45" keyTimes="0;.2;.4;1" dur="1.2s" repeatCount="indefinite"/></circle><circle cx="100" cy="45" r="5"><animate attributeName="cy" values="45;45;37;45;45" keyTimes="0;.15;.35;.55;1" dur="1.2s" repeatCount="indefinite"/></circle><circle cx="118" cy="45" r="5"><animate attributeName="cy" values="45;45;37;45;45" keyTimes="0;.3;.5;.7;1" dur="1.2s" repeatCount="indefinite"/></circle></g></svg></div>

**What it is.** Three dots that hop in sequence, like a chat app showing that someone is typing.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: bubble
    width: 80; height: 40; radius: 20; color: "#313244"
    Row {
        anchors.centerIn: parent
        spacing: 8
        Repeater {
            model: 3
            Rectangle {
                id: dot
                required property int index
                width: 10; height: 10; radius: 5; color: "#cdd6f4"
                SequentialAnimation on y {
                    running: bubble.visible; loops: Animation.Infinite
                    PauseAnimation { duration: dot.index * 150 }
                    NumberAnimation { to: -8; duration: 250; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                    PauseAnimation { duration: (2 - dot.index) * 150 + 300 }   // keep all three in sync
                }
            }
        }
    }
}
```

**Use for:** an AI chat sidebar waiting for a reply (like end-4's), "processing…" states, a calculator thinking.

## Skeleton Shimmer

<div class="preview"><svg width="300" height="130" viewBox="0 0 300 130"><defs><linearGradient id="shim" x1="0" x2="1"><stop offset="0" stop-color="#313244"/><stop offset=".5" stop-color="#45475a"/><stop offset="1" stop-color="#313244"/><animate attributeName="x1" values="-1;1" dur="1.4s" repeatCount="indefinite"/><animate attributeName="x2" values="0;2" dur="1.4s" repeatCount="indefinite"/></linearGradient></defs><rect x="30" y="20" width="60" height="60" rx="12" fill="url(#shim)"/><rect x="104" y="26" width="160" height="14" rx="7" fill="url(#shim)"/><rect x="104" y="50" width="110" height="12" rx="6" fill="url(#shim)"/><rect x="30" y="96" width="234" height="12" rx="6" fill="url(#shim)"/></svg></div>

**What it is.** Gray placeholder blocks with a light band sweeping across, shown while real content loads. The page looks ready instead of empty.

```qml file="Demo.qml"
import QtQuick

Item {
    id: root
    width: 260; height: 100
    property bool loading: true
    component Bone: Rectangle {
        color: "#313244"; radius: 7; clip: true
        Rectangle {                                         // the moving highlight
            width: parent.width * 0.6; height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: "#22ffffff" }
                GradientStop { position: 1; color: "transparent" }
            }
            NumberAnimation on x { from: -width; to: parent.width; duration: 1300; loops: Animation.Infinite; running: root.loading && root.visible }
        }
    }
    visible: loading
    Bone { x: 0; y: 0; width: 64; height: 64; radius: 12 }
    Bone { x: 78; y: 6; width: 170; height: 14 }
    Bone { x: 78; y: 30; width: 110; height: 12 }
    Bone { x: 0; y: 80; width: 248; height: 12 }
}
```

**Use for:** weather card before data arrives, media card with no player yet, app grid while icons load, wallpaper thumbnails.

## Indeterminate Progress Bar

<div class="preview"><svg width="300" height="60" viewBox="0 0 300 60"><clipPath id="ipb"><rect x="30" y="26" width="240" height="8" rx="4"/></clipPath><rect x="30" y="26" width="240" height="8" rx="4" fill="#313244"/><g clip-path="url(#ipb)"><rect y="26" height="8" rx="4" fill="#89b4fa"><animate attributeName="x" values="-60;290" dur="1.4s" repeatCount="indefinite" calcMode="spline" keySplines=".4 0 .2 1"/><animate attributeName="width" values="40;120;40" dur="1.4s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** A bar segment that slides across repeatedly: "working, but I don't know how long".

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: track
    width: 260; height: 8; radius: 4; color: "#313244"; clip: true
    property bool busy: true
    Rectangle {
        id: seg
        height: parent.height; radius: 4; color: "#89b4fa"
        width: 80
        SequentialAnimation on x {
            running: track.busy && track.visible; loops: Animation.Infinite
            NumberAnimation { from: -seg.width; to: track.width; duration: 1200; easing.type: Easing.InOutCubic }
        }
    }
}
```

**Use for:** updates running, file copy, wallpaper theme generation (matugen), any background job.

## Marquee (Scrolling Text)

<div class="preview"><svg width="260" height="70" viewBox="0 0 260 70"><clipPath id="mq"><rect x="40" y="18" width="180" height="34" rx="17"/></clipPath><rect x="40" y="18" width="180" height="34" rx="17" fill="#313244"/><g clip-path="url(#mq)"><text y="40" fill="#cdd6f4" font-size="13">♪ Midnight City — M83 · Hurry Up, We're Dreaming<animate attributeName="x" values="220;-260" dur="6s" repeatCount="indefinite"/></text></g></svg></div>

**What it is.** Text too long for its space scrolls continuously, pausing at each end. It only scrolls when it actually overflows.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: box
    width: 200; height: 30; radius: 15; color: "#313244"; clip: true
    property string text: "♪ Midnight City — M83 · Hurry Up, We're Dreaming"
    Text {
        id: t
        anchors.verticalCenter: parent.verticalCenter
        x: 12
        text: box.text; color: "#cdd6f4"; font.pixelSize: 13
        readonly property real overflow: Math.max(0, implicitWidth - (box.width - 24))
        SequentialAnimation on x {
            running: t.overflow > 0 && box.visible; loops: Animation.Infinite
            PauseAnimation { duration: 1500 }
            NumberAnimation { from: 12; to: 12 - t.overflow; duration: t.overflow * 25 }   // 40 px per second
            PauseAnimation { duration: 1500 }
            NumberAnimation { from: 12 - t.overflow; to: 12; duration: 400; easing.type: Easing.OutCubic }
        }
    }
}
```

**Use for:** song titles in the bar, long window titles, Wi-Fi names, notification summaries in a compact island.

## Floating Bob

<div class="preview"><svg width="200" height="120" viewBox="0 0 200 120"><text x="100" y="60" font-size="36" text-anchor="middle">☁<animateTransform attributeName="transform" type="translate" values="0 -5;0 5;0 -5" dur="3s" repeatCount="indefinite" calcMode="spline" keySplines=".45 0 .55 1;.45 0 .55 1"/></text><ellipse cx="100" cy="95" rx="22" ry="4" fill="#000" opacity=".35"><animate attributeName="rx" values="18;24;18" dur="3s" repeatCount="indefinite"/></ellipse></svg></div>

**What it is.** A gentle up-and-down drift (with an optional shadow that grows and shrinks) that makes desktop decorations feel alive.

```qml file="Demo.qml"
import QtQuick

Item {
    id: root
    width: 120; height: 120
    Text {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        text: "cloud"; font.family: "Material Symbols Rounded"; font.pixelSize: 64; color: "#cdd6f4"
        property real bob: 0
        y: 20 + bob
        SequentialAnimation on bob {
            running: root.visible; loops: Animation.Infinite
            NumberAnimation { from: -6; to: 6; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 6; to: -6; duration: 1600; easing.type: Easing.InOutSine }
        }
    }
    Rectangle {                                                   // shadow reacts to height
        anchors.horizontalCenter: parent.horizontalCenter
        y: 104; height: 6; radius: 3; color: "#55000000"
        width: 40 + icon.bob * 1.5
    }
}
```

**Use for:** weather icons on a desktop card, a desktop pet, "empty state" illustrations ("All caught up").

## Heartbeat

<div class="preview"><svg width="200" height="110" viewBox="0 0 200 110"><g transform="translate(100 55)"><path d="M0 18 L-20 -2 A11 11 0 0 1 0 -16 A11 11 0 0 1 20 -2 Z" fill="#f38ba8"><animateTransform attributeName="transform" type="scale" values="1;1.25;1;1.18;1;1" keyTimes="0;.12;.24;.36;.5;1" dur="1.2s" repeatCount="indefinite"/></path></g></svg></div>

**What it is.** A double "lub-dub" scale pulse, rhythmic and organic.

```qml file="Demo.qml"
import QtQuick

Text {
    id: heart
    text: "favorite"; font.family: "Material Symbols Rounded"; font.pixelSize: 56; color: "#f38ba8"
    font.variableAxes: ({ "FILL": 1 })
    SequentialAnimation on scale {
        running: heart.visible; loops: Animation.Infinite
        NumberAnimation { to: 1.25; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { to: 1.0; duration: 140; easing.type: Easing.InQuad }
        NumberAnimation { to: 1.18; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { to: 1.0; duration: 160; easing.type: Easing.InQuad }
        PauseAnimation { duration: 700 }
    }
}
```

**Use for:** a "now playing" heart, a health or uptime widget, love/like buttons, a fun charging indicator.

## Rotating Gradient Ring

<div class="preview"><svg width="200" height="120" viewBox="0 0 200 120"><defs><linearGradient id="rgr" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#cba6f7"/><stop offset=".5" stop-color="#89b4fa"/><stop offset="1" stop-color="#94e2d5" stop-opacity="0"/></linearGradient></defs><g transform="translate(100 60)"><circle r="34" fill="none" stroke="url(#rgr)" stroke-width="6" stroke-linecap="round"><animateTransform attributeName="transform" type="rotate" from="0" to="360" dur="2s" repeatCount="indefinite"/></circle><circle r="24" fill="#cba6f7"/></g></svg></div>

**What it is.** A colorful ring that spins around an avatar or icon (Instagram-story style), fading from accent to transparent.

```qml file="Demo.qml"
import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

Item {
    id: root
    width: 90; height: 90
    property bool active: true
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        RotationAnimator on rotation { from: 0; to: 360; duration: 2000; loops: Animation.Infinite; running: root.active && root.visible }
        ShapePath {
            fillColor: "transparent"; strokeWidth: 5; capStyle: ShapePath.RoundCap
            strokeGradient: ConicalGradient {           // Qt 6.8+ (older: use strokeColor)
                centerX: 45; centerY: 45; angle: 0
                GradientStop { position: 0; color: "#cba6f7" }
                GradientStop { position: 0.6; color: "#89b4fa" }
                GradientStop { position: 1; color: "transparent" }
            }
            PathAngleArc { centerX: 45; centerY: 45; radiusX: 40; radiusY: 40; sweepAngle: 360 }
        }
    }
    ClippingRectangle {
        anchors.centerIn: parent; width: 66; height: 66; radius: 33; color: "#cba6f7"
        Image { anchors.fill: parent; source: "file:///home/me/.face"; fillMode: Image.PreserveAspectCrop }
    }
}
```

> [!NOTE] `strokeGradient` needs Qt 6.8+. On older Qt, use a solid `strokeColor` with a partial `sweepAngle` (e.g. 270°) for a similar spinning-arc look.

**Use for:** an avatar on the lock screen while authenticating, an "in a call" indicator, a story-style media button.

## Equalizer Bars (Fake)

<div class="preview"><svg width="200" height="100" viewBox="0 0 200 100"><g fill="#a6e3a1"><rect x="74" y="30" width="8" rx="3" height="40"><animate attributeName="height" values="12;40;20;34;12" dur=".9s" repeatCount="indefinite"/><animate attributeName="y" values="58;30;50;36;58" dur=".9s" repeatCount="indefinite"/></rect><rect x="88" y="30" width="8" rx="3" height="40"><animate attributeName="height" values="36;14;40;18;36" dur=".8s" repeatCount="indefinite"/><animate attributeName="y" values="34;56;30;52;34" dur=".8s" repeatCount="indefinite"/></rect><rect x="102" y="30" width="8" rx="3" height="40"><animate attributeName="height" values="20;38;12;30;20" dur="1s" repeatCount="indefinite"/><animate attributeName="y" values="50;32;58;40;50" dur="1s" repeatCount="indefinite"/></rect><rect x="116" y="30" width="8" rx="3" height="40"><animate attributeName="height" values="30;16;36;10;30" dur=".85s" repeatCount="indefinite"/><animate attributeName="y" values="40;54;34;60;40" dur=".85s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** Small bars bouncing at different speeds to suggest "music is playing", with no audio analysis needed.

```qml file="Demo.qml"
import QtQuick

Row {
    id: eq
    property bool playing: true
    spacing: 3
    height: 18
    Repeater {
        model: 4
        Rectangle {
            id: bar
            required property int index
            width: 3; radius: 1.5; color: "#a6e3a1"
            anchors.bottom: parent.bottom
            height: 4
            SequentialAnimation on height {
                running: eq.playing && eq.visible; loops: Animation.Infinite
                NumberAnimation { to: 6 + (bar.index * 5) % 12; duration: 220 + bar.index * 60; easing.type: Easing.InOutSine }
                NumberAnimation { to: 18 - (bar.index * 3) % 8; duration: 260 + bar.index * 40; easing.type: Easing.InOutSine }
                NumberAnimation { to: 3; duration: 240; easing.type: Easing.InOutSine }
                onRunningChanged: if (!running) bar.height = 3
            }
        }
    }
}
```

For real audio levels see the Visualizer in [[ch:g5-desktop]] or [[PwNodePeakMonitor]].

**Use for:** the media chip, the Dynamic Island in media mode, the active tab in a browser-like widget.
