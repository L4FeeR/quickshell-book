# Animations: Morphs, Indicators and Transitions

Motion that **changes one thing into another**: shapes morphing, indicators sliding between items, numbers rolling, content swapping, pages sliding. These are the signature effects of Material 3 Expressive, end-4 and Caelestia.

## Shape Morph (Circle ⇄ Rounded Square)

<div class="preview"><svg width="220" height="110" viewBox="0 0 220 110"><rect x="80" y="25" width="60" height="60" fill="#cba6f7"><animate attributeName="rx" values="30;12;12;30;30" keyTimes="0;.2;.5;.7;1" dur="3s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** Animating `radius` changes the shape: a circle becomes a rounded square when activated. It's Material 3's way to show state.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: btn
    property bool on: false
    width: 64; height: 64
    radius: on ? 18 : width / 2
    color: on ? "#cba6f7" : "#45475a"
    Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] } }
    Behavior on color { ColorAnimation { duration: 200 } }
    TapHandler { onTapped: btn.on = !btn.on }
}
```

**Use for:** toggle buttons, the play/pause button (squircle while playing), quick-settings tiles, the active workspace.

## Pill Expand (Icon ⇄ Icon + Label)

<div class="preview"><svg width="280" height="90" viewBox="0 0 280 90"><rect y="25" height="40" rx="20" fill="#313244"><animate attributeName="width" values="40;170;170;40;40" keyTimes="0;.2;.55;.75;1" dur="4s" repeatCount="indefinite"/><animate attributeName="x" values="120;55;55;120;120" keyTimes="0;.2;.55;.75;1" dur="4s" repeatCount="indefinite"/></rect><text font-size="16" fill="#cdd6f4" y="51">🔊<animate attributeName="x" values="130;67;67;130;130" keyTimes="0;.2;.55;.75;1" dur="4s" repeatCount="indefinite"/></text><text x="95" y="50" font-size="13" fill="#cdd6f4" opacity="0">Speakers 62%<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;.15;.25;.5;.55;1" dur="4s" repeatCount="indefinite"/></text></svg></div>

**What it is.** A circular icon button that stretches into a pill to reveal a label. The width follows the content automatically.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: pill
    property bool expanded: hover.hovered
    implicitWidth: expanded ? row.implicitWidth + 24 : height
    implicitHeight: 40
    radius: height / 2
    color: "#313244"
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Row {
        id: row
        x: (pill.height - icon.width) / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text { id: icon; text: "volume_up"; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: "#cdd6f4" }
        Text { text: "Speakers 62%"; color: "#cdd6f4"; anchors.verticalCenter: parent.verticalCenter
               opacity: pill.expanded ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 180 } } }
    }
    HoverHandler { id: hover }
}
```

**Use for:** bar status icons, the media chip, FAB-style buttons in panels.

## Sliding Indicator

<div class="preview"><svg width="300" height="80" viewBox="0 0 300 80"><rect x="20" y="20" width="260" height="40" rx="20" fill="#313244"/><rect y="24" width="80" height="32" rx="16" fill="#cba6f7"><animate attributeName="x" values="24;24;110;110;196;196;24" keyTimes="0;.2;.3;.5;.6;.85;1" dur="5s" repeatCount="indefinite" calcMode="spline" keySplines=".2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1;.2 .8 .2 1"/></rect><g font-size="12" text-anchor="middle" fill="#cdd6f4"><text x="64" y="45">Apps</text><text x="150" y="45">Files</text><text x="236" y="45">Web</text></g></svg></div>

**What it is.** One highlight that moves (and resizes) to the selected item, instead of each item lighting up on its own. The eye follows the change.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: tabs
    property int current: 0
    property var labels: ["Apps", "Files", "Web"]
    width: row.implicitWidth + 8; height: 40; radius: 20; color: "#313244"

    Rectangle {                                       // the indicator
        readonly property Item target: rep.itemAt(tabs.current)
        x: row.x + (target?.x ?? 0); width: target?.width ?? 0
        y: 4; height: parent.height - 8; radius: height / 2
        color: "#cba6f7"
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }
    Row {
        id: row
        x: 4; anchors.verticalCenter: parent.verticalCenter
        Repeater {
            id: rep
            model: tabs.labels
            Item {
                required property string modelData
                required property int index
                width: lbl.implicitWidth + 32; height: 32
                Text { id: lbl; anchors.centerIn: parent; text: modelData
                       color: tabs.current === index ? "#1e1e2e" : "#cdd6f4"
                       Behavior on color { ColorAnimation { duration: 200 } } }
                TapHandler { onTapped: tabs.current = index }
            }
        }
    }
}
```

**Use for:** tabs, segmented controls, workspace indicators, launcher modes, sidebar navigation.

## Stretchy Indicator (Liquid Move)

<div class="preview"><svg width="300" height="80" viewBox="0 0 300 80"><rect x="20" y="20" width="260" height="40" rx="20" fill="#313244"/><rect y="28" height="24" rx="12" fill="#cba6f7"><animate attributeName="x" values="40;40;40;160;160;160;40;40" keyTimes="0;.15;.25;.35;.6;.7;.8;1" dur="5s" repeatCount="indefinite"/><animate attributeName="width" values="30;30;150;30;30;150;30;30" keyTimes="0;.15;.25;.35;.6;.7;.8;1" dur="5s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** The indicator's leading edge moves first and the trailing edge catches up, so it stretches while traveling and shrinks back on arrival, like a drop of liquid. end-4's workspace indicator works like this.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: root
    property int current: 0
    property int count: 6
    property real slot: 36
    width: count * slot + 8; height: 36; radius: 18; color: "#313244"

    // target edges
    readonly property real targetLeft: 4 + current * slot + 8
    readonly property real targetRight: targetLeft + slot - 16
    // animated edges: fast in the direction of travel, slow behind
    property bool forward: true
    onTargetLeftChanged: forward = targetLeft > left
    property real left: targetLeft
    property real right: targetRight
    Behavior on left  { NumberAnimation { duration: root.forward ? 380 : 180; easing.type: Easing.OutCubic } }
    Behavior on right { NumberAnimation { duration: root.forward ? 180 : 380; easing.type: Easing.OutCubic } }

    Rectangle { x: root.left; width: root.right - root.left; y: 9; height: 18; radius: 9; color: "#cba6f7" }
    Row {
        x: 4
        Repeater { model: root.count
            Item { required property int index; width: root.slot; height: 36
                   TapHandler { onTapped: root.current = index } } }
    }
}
```

**Use for:** workspace indicators, tab bars, page dots.

## Accordion Expand

<div class="preview"><svg width="300" height="150" viewBox="0 0 300 150"><rect x="30" y="10" width="240" rx="12" fill="#313244"><animate attributeName="height" values="36;120;120;36;36" keyTimes="0;.2;.55;.75;1" dur="4s" repeatCount="indefinite"/></rect><text x="46" y="33" fill="#cdd6f4" font-size="13">Bluetooth devices</text><text x="250" y="33" fill="#cdd6f4" font-size="12" text-anchor="middle">⌄<animateTransform attributeName="transform" type="rotate" values="0 250 29;180 250 29;180 250 29;0 250 29;0 250 29" keyTimes="0;.2;.55;.75;1" dur="4s" repeatCount="indefinite"/></text><g fill="#a6adc8" font-size="11" opacity="0"><animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;.15;.25;.5;.6;1" dur="4s" repeatCount="indefinite"/><text x="46" y="62">Sony WH-1000XM4</text><text x="46" y="84">Keychron K2</text><text x="46" y="106">Pixel Buds</text></g></svg></div>

**What it is.** A section header that expands to reveal its content, with the chevron rotating, then collapses back. The height animates to fit whatever is inside.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: sec
    property bool open: false
    width: 260
    height: header.height + (open ? body.implicitHeight + 8 : 0)
    radius: 12; color: "#313244"; clip: true
    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    Item {
        id: header
        width: parent.width; height: 40
        Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "Bluetooth devices"; color: "#cdd6f4" }
        Text {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: "expand_more"; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: "#cdd6f4"
            rotation: sec.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }
        TapHandler { onTapped: sec.open = !sec.open }
    }
    Column {
        id: body
        y: header.height
        x: 14; spacing: 8
        opacity: sec.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Repeater { model: ["Sony WH-1000XM4", "Keychron K2", "Pixel Buds"]
                   Text { required property string modelData; text: modelData; color: "#a6adc8" } }
    }
}
```

**Use for:** grouped notifications by app, settings sections, Wi-Fi/Bluetooth device lists, expandable notification bodies.

## Number Ticker (Count Up)

<div class="preview"><svg width="240" height="90" viewBox="0 0 240 90"><text x="120" y="58" fill="#cdd6f4" font-size="34" font-weight="800" text-anchor="middle">62%<animate attributeName="opacity" values="1;1" dur="1s"/></text></svg></div>

**What it is.** When a number changes, it counts through the intermediate values instead of jumping. It works for percentages, temperatures and speeds.

```qml file="Demo.qml"
import QtQuick

Text {
    id: t
    property real value: 0                  // bind to Audio.volume * 100, Battery %, etc.
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    text: Math.round(shown) + "%"
    color: "#cdd6f4"; font.pixelSize: 40; font.bold: true
    font.features: ({ "tnum": 1 })          // equal-width digits so the text doesn't wobble
    TapHandler { onTapped: t.value = Math.round(Math.random() * 100) }
}
```

**Use for:** OSD percentages, battery and CPU numbers, download progress, dashboard stats.

## Rolling Digits

<div class="preview"><svg width="240" height="100" viewBox="0 0 240 100"><clipPath id="roll"><rect x="70" y="25" width="100" height="44"/></clipPath><g clip-path="url(#roll)" font-size="34" font-weight="800" fill="#cdd6f4" text-anchor="middle"><text x="100" y="60">1</text><g><animateTransform attributeName="transform" type="translate" values="0 0;0 0;0 -44;0 -44" keyTimes="0;.4;.55;1" dur="3s" repeatCount="indefinite"/><text x="140" y="60">4</text><text x="140" y="104">5</text></g></g></svg></div>

**What it is.** Each digit rolls vertically like an odometer when it changes. It's a classic clock or counter effect.

```qml file="Demo.qml"
import QtQuick

Row {
    id: root
    property int value: 1234
    spacing: 0
    Repeater {
        model: String(root.value).length
        Item {
            id: cell
            required property int index
            readonly property int digit: parseInt(String(root.value)[index])
            width: 26; height: 44; clip: true
            Column {
                y: -cell.digit * 44                      // show the current digit
                Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                Repeater { model: 10
                    Text { required property int index; width: 26; height: 44
                           horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                           text: index; color: "#cdd6f4"; font.pixelSize: 34; font.bold: true } }
            }
        }
    }
    Timer { interval: 1200; running: true; repeat: true; onTriggered: root.value = (root.value + 7) % 10000 }
}
```

**Use for:** a flip-style desktop clock (feed it `hhmm`), notification counters, update counts, a CPU temperature display.

## Content Crossfade

<div class="preview"><svg width="260" height="100" viewBox="0 0 260 100"><rect x="40" y="20" width="180" height="60" rx="16" fill="#313244"/><text x="130" y="56" fill="#cdd6f4" font-size="14" text-anchor="middle">Wi-Fi: Home-5G<animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;.4;.5;.9;1" dur="4s" repeatCount="indefinite"/></text><text x="130" y="56" fill="#a6e3a1" font-size="14" text-anchor="middle" opacity="0">Connected ✓<animate attributeName="opacity" values="0;0;1;1;0" keyTimes="0;.45;.55;.9;1" dur="4s" repeatCount="indefinite"/></text></svg></div>

**What it is.** When content changes (a different label, image or icon), the old fades out while the new fades in, instead of snapping.

```qml file="Demo.qml"
import QtQuick

Item {
    id: root
    width: 200; height: 60
    property string text: "Wi-Fi: Home-5G"
    // two labels: when text changes, swap which one is visible
    property bool flip: false
    onTextChanged: { (flip ? a : b).text = text; flip = !flip }
    Text { id: a; anchors.centerIn: parent; text: root.text; color: "#cdd6f4"; opacity: root.flip ? 0 : 1
           Behavior on opacity { NumberAnimation { duration: 250 } } }
    Text { id: b; anchors.centerIn: parent; color: "#cdd6f4"; opacity: root.flip ? 1 : 0
           Behavior on opacity { NumberAnimation { duration: 250 } } }
    TapHandler { onTapped: root.text = root.text.startsWith("Wi") ? "Connected ✓" : "Wi-Fi: Home-5G" }
}
```

The same two-layer trick crossfades images: album art changing tracks, wallpapers ([[ch:60-proj-wallpaper]]).

**Use for:** album art, status text, weather icon changes, the clock's date/time swap.

## Icon Morph (Play ⇄ Pause)

<div class="preview"><svg width="200" height="110" viewBox="0 0 200 110"><circle cx="100" cy="55" r="34" fill="#cba6f7"/><g transform="translate(100 55)"><g><animateTransform attributeName="transform" type="rotate" values="0;90;90;0;0" keyTimes="0;.2;.5;.7;1" dur="3s" repeatCount="indefinite"/><path d="M-9 -14 L15 0 L-9 14 Z" fill="#1e1e2e"><animate attributeName="opacity" values="1;0;0;1;1" keyTimes="0;.15;.55;.65;1" dur="3s" repeatCount="indefinite"/></path><g fill="#1e1e2e" opacity="0"><animate attributeName="opacity" values="0;1;1;0;0" keyTimes="0;.15;.55;.65;1" dur="3s" repeatCount="indefinite"/><rect x="-14" y="-10" width="28" height="8" rx="2"/><rect x="-14" y="4" width="28" height="8" rx="2"/></g></g></g></svg></div>

**What it is.** Switching icons with a rotate + scale + crossfade, so the change feels like a transformation rather than a swap.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: btn
    property bool playing: false
    width: 64; height: 64; radius: playing ? 20 : 32; color: "#cba6f7"
    Behavior on radius { NumberAnimation { duration: 250 } }

    component MorphIcon: Text {
        property bool active
        font.family: "Material Symbols Rounded"; font.pixelSize: 34; color: "#1e1e2e"
        font.variableAxes: ({ "FILL": 1 })
        anchors.centerIn: parent
        opacity: active ? 1 : 0
        scale: active ? 1 : 0.5
        rotation: active ? 0 : -90
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }
    MorphIcon { text: "play_arrow"; active: !btn.playing }
    MorphIcon { text: "pause"; active: btn.playing }
    TapHandler { onTapped: btn.playing = !btn.playing }
}
```

**Use for:** play/pause, mute/unmute, Wi-Fi on/off, expand/collapse, the theme light/dark toggle (sun ⇄ moon).

## Page Slide (StackView)

<div class="preview"><svg width="300" height="140" viewBox="0 0 300 140"><clipPath id="ps"><rect x="40" y="15" width="220" height="110" rx="16"/></clipPath><rect x="40" y="15" width="220" height="110" rx="16" fill="#1e1e2e"/><g clip-path="url(#ps)"><g><animateTransform attributeName="transform" type="translate" values="0 0;0 0;-220 0;-220 0;0 0" keyTimes="0;.3;.45;.8;1" dur="4s" repeatCount="indefinite"/><text x="60" y="45" fill="#cdd6f4" font-size="13" font-weight="700">Quick settings</text><rect x="60" y="58" width="80" height="28" rx="10" fill="#313244"/><rect x="150" y="58" width="80" height="28" rx="10" fill="#cba6f7"/><text x="280" y="45" fill="#cdd6f4" font-size="13" font-weight="700">← Wi-Fi</text><rect x="280" y="58" width="180" height="20" rx="6" fill="#313244"/><rect x="280" y="84" width="180" height="20" rx="6" fill="#313244"/></g></g></svg></div>

**What it is.** Navigating into a sub-page slides the new page in from the right while the old one slides left (and the reverse when going back).

```qml file="Demo.qml"
import QtQuick
import QtQuick.Controls

StackView {
    id: stack
    width: 300; height: 200
    clip: true
    initialItem: Rectangle {
        color: "#1e1e2e"
        Text { anchors.centerIn: parent; text: "Main page →"; color: "#cdd6f4"; TapHandler { onTapped: stack.push(sub) } }
    }
    Component { id: sub
        Rectangle { color: "#1e1e2e"
            Text { anchors.centerIn: parent; text: "← Wi-Fi page"; color: "#cdd6f4"; TapHandler { onTapped: stack.pop() } } } }

    pushEnter: Transition { ParallelAnimation {
        NumberAnimation { property: "x"; from: stack.width; to: 0; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } } }
    pushExit:  Transition { NumberAnimation { property: "x"; from: 0; to: -stack.width * 0.3; duration: 300; easing.type: Easing.OutCubic } }
    popEnter:  Transition { NumberAnimation { property: "x"; from: -stack.width * 0.3; to: 0; duration: 300; easing.type: Easing.OutCubic } }
    popExit:   Transition { ParallelAnimation {
        NumberAnimation { property: "x"; from: 0; to: stack.width; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 250 } } }
}
```

**Use for:** control center → Wi-Fi/Bluetooth details ([[ch:55-proj-control-center]]), settings pages, tray submenus.

## Card Flip (Front ⇄ Back)

<div class="preview"><svg width="240" height="140" viewBox="0 0 240 140"><g transform="translate(120 70)"><g><animateTransform attributeName="transform" type="scale" values="1 1;0 1;1 1;1 1;0 1;1 1;1 1" keyTimes="0;.1;.2;.5;.6;.7;1" dur="4s" repeatCount="indefinite"/><rect x="-70" y="-45" width="140" height="90" rx="16" fill="#89b4fa"><animate attributeName="fill" values="#89b4fa;#89b4fa;#313244;#313244;#313244;#89b4fa;#89b4fa" keyTimes="0;.1;.11;.5;.6;.61;1" dur="4s" repeatCount="indefinite"/></rect></g></g></svg></div>

**What it is.** A two-sided card: clicking flips it in 3D to reveal the back (for example, a clock that flips to show the calendar).

```qml file="Demo.qml"
import QtQuick

Flipable {
    id: card
    property bool flipped: false
    width: 180; height: 110
    front: Rectangle { anchors.fill: parent; radius: 16; color: "#89b4fa"
                       Text { anchors.centerIn: parent; text: "14:32"; font.pixelSize: 34; font.bold: true; color: "#1e1e2e" } }
    back:  Rectangle { anchors.fill: parent; radius: 16; color: "#313244"
                       Text { anchors.centerIn: parent; text: "Fri 21 Nov"; font.pixelSize: 20; color: "#cdd6f4" } }
    transform: Rotation {
        id: rot
        origin.x: card.width / 2; origin.y: card.height / 2
        axis { x: 0; y: 1; z: 0 }
        angle: card.flipped ? 180 : 0
        Behavior on angle { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }
    }
    TapHandler { onTapped: card.flipped = !card.flipped }
}
```

`Flipable` shows `front` or `back` depending on which side faces you, so you only animate the rotation.

**Use for:** desktop clock ⇄ calendar, weather now ⇄ forecast, album art ⇄ lyrics, widget ⇄ its settings.

## Liquid Blob

<div class="preview"><svg width="240" height="140" viewBox="0 0 240 140"><path fill="#cba6f7" opacity=".9"><animate attributeName="d" dur="5s" repeatCount="indefinite" values="M120 30 C160 30 180 55 180 75 C180 100 155 115 120 115 C85 115 60 100 60 75 C60 50 80 30 120 30Z;M120 25 C170 35 175 60 185 80 C190 105 150 120 115 112 C80 108 55 95 62 70 C68 45 85 22 120 25Z;M120 35 C150 25 190 50 178 78 C170 102 160 118 122 118 C88 118 50 105 58 78 C64 52 92 42 120 35Z;M120 30 C160 30 180 55 180 75 C180 100 155 115 120 115 C85 115 60 100 60 75 C60 50 80 30 120 30Z"/></path></svg></div>

**What it is.** An organic shape whose outline slowly wobbles, made from a closed path whose control points drift on sine waves.

```qml file="Demo.qml"
import QtQuick
import QtQuick.Shapes

Shape {
    id: blob
    width: 200; height: 200
    preferredRendererType: Shape.CurveRenderer
    property real t: 0
    NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 6000; loops: Animation.Infinite; running: blob.visible }
    // radius of point i at the current time
    function r(i: int): real { return 70 + 10 * Math.sin(t + i * 1.7) + 6 * Math.sin(2 * t + i) }
    function px(i: int): real { return 100 + r(i) * Math.cos(i * Math.PI / 2) }
    function py(i: int): real { return 100 + r(i) * Math.sin(i * Math.PI / 2) }
    readonly property real k: 0.55                     // circle-approximation factor
    ShapePath {
        fillColor: "#cba6f7"; strokeWidth: -1
        startX: blob.px(0); startY: blob.py(0)
        PathCubic { x: blob.px(1); y: blob.py(1); control1X: blob.px(0); control1Y: blob.py(0) + blob.r(0) * blob.k; control2X: blob.px(1) + blob.r(1) * blob.k; control2Y: blob.py(1) }
        PathCubic { x: blob.px(2); y: blob.py(2); control1X: blob.px(1) - blob.r(1) * blob.k; control1Y: blob.py(1); control2X: blob.px(2); control2Y: blob.py(2) + blob.r(2) * blob.k }
        PathCubic { x: blob.px(3); y: blob.py(3); control1X: blob.px(2); control1Y: blob.py(2) - blob.r(2) * blob.k; control2X: blob.px(3) - blob.r(3) * blob.k; control2Y: blob.py(3) }
        PathCubic { x: blob.px(0); y: blob.py(0); control1X: blob.px(3) + blob.r(3) * blob.k; control1Y: blob.py(3); control2X: blob.px(0); control2Y: blob.py(0) - blob.r(0) * blob.k }
    }
}
```

**Use for:** an ambient background behind a desktop clock, an "AI is listening" orb, a lock-screen avatar backdrop, album-art-colored blobs (tint with [[ColorQuantizer]]).

## Progress Ring Fill

<div class="preview"><svg width="200" height="130" viewBox="0 0 200 130"><circle cx="100" cy="65" r="40" fill="none" stroke="#313244" stroke-width="9"/><circle cx="100" cy="65" r="40" fill="none" stroke="#a6e3a1" stroke-width="9" stroke-linecap="round" transform="rotate(-90 100 65)" stroke-dasharray="0 252"><animate attributeName="stroke-dasharray" values="0 252;190 252;190 252;0 252" keyTimes="0;.4;.8;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines=".2 .8 .2 1;0 0 1 1;.6 0 .8 .3"/></circle><text x="100" y="71" fill="#cdd6f4" font-size="16" font-weight="800" text-anchor="middle">75%</text></svg></div>

**What it is.** A circular gauge that sweeps smoothly to each new value, with the number counting along.

```qml file="Demo.qml"
import QtQuick
import QtQuick.Shapes

Item {
    id: ring
    property real value: 0.75                  // 0..1
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    width: 110; height: 110
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath { fillColor: "transparent"; strokeColor: "#313244"; strokeWidth: 10
            PathAngleArc { centerX: 55; centerY: 55; radiusX: 45; radiusY: 45; sweepAngle: 360 } }
        ShapePath { fillColor: "transparent"; strokeColor: "#a6e3a1"; strokeWidth: 10; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 55; centerY: 55; radiusX: 45; radiusY: 45; startAngle: -90; sweepAngle: 360 * ring.shown } }
    }
    Text { anchors.centerIn: parent; text: Math.round(ring.shown * 100) + "%"; color: "#cdd6f4"; font.pixelSize: 20; font.bold: true }
    TapHandler { onTapped: ring.value = Math.random() }
}
```

**Use for:** battery, CPU, RAM, disk, a pomodoro timer, download progress, volume in a circular OSD.
