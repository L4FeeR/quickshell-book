# Animations: Entrances and Exits

How things **appear** and **disappear**: popups, panels, notifications, OSDs, cards. Each effect is written as a reusable pattern driven by a single `shown` boolean, so you can apply it to any item.

> [!TIP] Keep windows mapped while animating out
> If the element lives in its own window, keep the window visible until the exit animation finishes: `visible: shown || anim.running`. With a [[LazyLoader]], use `active: shown || anim.running`.

## Fade

<div class="preview"><svg width="240" height="100" viewBox="0 0 240 100"><rect x="60" y="20" width="120" height="60" rx="16" fill="#cba6f7"><animate attributeName="opacity" values="0;1;1;0;0" keyTimes="0;.2;.6;.8;1" dur="3s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** The simplest entrance: opacity from 0 to 1. Subtle and never wrong.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: card
    property bool shown: false
    width: 160; height: 80; radius: 16; color: "#cba6f7"
    opacity: shown ? 1 : 0
    visible: opacity > 0                       // stop catching clicks when fully faded
    Behavior on opacity { NumberAnimation { duration: shown ? 200 : 150 } }
    Timer { interval: 1500; running: true; repeat: true; onTriggered: card.shown = !card.shown }
}
```

**Use for:** tooltips, the content inside a panel after it expands, overlays and dimming scrims, swapping a widget's content.

## Slide In from an Edge

<div class="preview"><svg width="320" height="110" viewBox="0 0 320 110"><rect x="0" y="0" width="320" height="4" fill="#45475a"/><rect x="80" width="160" height="56" rx="16" fill="#313244" stroke="#45475a"><animate attributeName="y" values="-60;20;20;-60;-60" keyTimes="0;.2;.6;.75;1" dur="3.5s" repeatCount="indefinite" calcMode="spline" keySplines=".2 .8 .2 1;0 0 1 1;.6 0 .8 .3;0 0 1 1"/></rect></svg></div>

**What it is.** The element moves in from outside the screen edge it belongs to. It's the most "explanatory" motion: users see where it lives.

```qml file="Demo.qml"
import QtQuick

Item {
    id: root
    width: 360; height: 200
    clip: true
    property bool shown: false
    property int edge: Qt.TopEdge                  // Qt.TopEdge, BottomEdge, LeftEdge, RightEdge

    Rectangle {
        id: panel
        width: 220; height: 70; radius: 16; color: "#313244"
        readonly property real homeX: (root.width - width) / 2
        readonly property real homeY: 20
        x: !root.shown && root.edge === Qt.LeftEdge ? -width
         : !root.shown && root.edge === Qt.RightEdge ? root.width : homeX
        y: !root.shown && root.edge === Qt.TopEdge ? -height
         : !root.shown && root.edge === Qt.BottomEdge ? root.height : homeY
        Behavior on x { NumberAnimation { duration: root.shown ? 380 : 220; easing.type: root.shown ? Easing.OutCubic : Easing.InCubic } }
        Behavior on y { NumberAnimation { duration: root.shown ? 380 : 220; easing.type: root.shown ? Easing.OutCubic : Easing.InCubic } }
    }
    TapHandler { onTapped: root.shown = !root.shown }
}
```

**Use for:** sidebars (from left/right), notification popups (from the right), toasts and drop-downs (from the top), docks (from the bottom).

## Pop (Scale + Fade)

<div class="preview"><svg width="240" height="120" viewBox="0 0 240 120"><g transform="translate(120 60)"><rect x="-60" y="-35" width="120" height="70" rx="18" fill="#cba6f7"><animateTransform attributeName="transform" type="scale" values="0.6;1.06;1;1;0.8;0.6" keyTimes="0;.18;.26;.65;.75;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;1;1;1;0;0" keyTimes="0;.15;.26;.65;.75;1" dur="3s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** Starts slightly small and transparent and grows to full size with a gentle overshoot. It feels lively and modern.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: card
    property bool shown: false
    width: 180; height: 100; radius: 18; color: "#cba6f7"
    scale: shown ? 1 : 0.85
    opacity: shown ? 1 : 0
    Behavior on scale { NumberAnimation { duration: card.shown ? 350 : 150; easing.type: card.shown ? Easing.OutBack : Easing.InQuad; easing.overshoot: 1.4 } }
    Behavior on opacity { NumberAnimation { duration: card.shown ? 200 : 150 } }
    TapHandler { onTapped: card.shown = !card.shown }
}
```

**Use for:** launchers, power menus, calculators, emoji pickers, dialogs: anything centered on screen.

## Grow from the Trigger

<div class="preview"><svg width="300" height="150" viewBox="0 0 300 150"><rect x="20" y="10" width="260" height="26" rx="10" fill="#1e1e2e"/><rect x="128" y="14" width="44" height="18" rx="9" fill="#cba6f7"/><rect x="70" y="44" width="160" height="96" rx="16" fill="#313244" style="transform-origin:150px 44px"><animateTransform attributeName="transform" type="scale" values="0.3 0.1;1 1;1 1;0.3 0.1;0.3 0.1" keyTimes="0;.2;.6;.75;1" dur="3.5s" repeatCount="indefinite" additive="sum"/><animate attributeName="opacity" values="0;1;1;0;0" keyTimes="0;.15;.6;.72;1" dur="3.5s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** A popup that expands out of the button that opened it (the scale origin is the trigger), so the cause and effect are obvious.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 300; height: 220
    Rectangle {                                         // the trigger button
        id: btn
        x: 120; y: 10; width: 60; height: 26; radius: 13; color: "#cba6f7"
        TapHandler { onTapped: menu.shown = !menu.shown }
    }
    Rectangle {
        id: menu
        property bool shown: false
        anchors.top: btn.bottom; anchors.topMargin: 8
        anchors.horizontalCenter: btn.horizontalCenter
        width: 200; height: 140; radius: 16; color: "#313244"
        transformOrigin: Item.Top                       // grow from the edge touching the button
        scale: shown ? 1 : 0.4
        opacity: shown ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }
}
```

`transformOrigin` can be `Item.Top`, `TopLeft`, `TopRight`, `Left`, `Center`, `Right`, `BottomLeft`, `Bottom`, `BottomRight`.

**Use for:** calendar under the clock, tray menus, the media popup from the media chip, any [[PopupWindow]].

## Drop with Spring

<div class="preview"><svg width="240" height="130" viewBox="0 0 240 130"><rect x="70" width="100" height="44" rx="14" fill="#a6e3a1"><animate attributeName="y" values="-50;50;30;44;38;40;40;-50" keyTimes="0;.15;.22;.29;.35;.4;.85;1" dur="4s" repeatCount="indefinite"/></rect><line x1="20" y1="110" x2="220" y2="110" stroke="#45475a"/></svg></div>

**What it is.** The element falls in from above and settles with a springy bounce, physical and playful.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 260; height: 160
    clip: true
    property bool shown: false
    Rectangle {
        width: 120; height: 50; radius: 14; color: "#a6e3a1"
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.shown ? 50 : -60
        Behavior on y { SpringAnimation { spring: 2.5; damping: 0.18; epsilon: 0.3 } }
    }
    TapHandler { onTapped: parent.shown = !parent.shown }
}
```

**Use for:** notification badges, achievement-style toasts, a playful Dynamic Island, the charging popup.

## Flip In (3D)

<div class="preview"><svg width="240" height="130" viewBox="0 0 240 130"><g transform="translate(120 65)"><rect x="-60" y="-40" width="120" height="80" rx="16" fill="#89b4fa"><animateTransform attributeName="transform" type="scale" values="0 1;1 1;1 1;0 1;0 1" keyTimes="0;.2;.6;.8;1" dur="3s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** The card rotates around its vertical (or horizontal) axis into view, like a card being turned over.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: card
    property bool shown: false
    width: 180; height: 110; radius: 16; color: "#89b4fa"
    property real angle: shown ? 0 : 90
    Behavior on angle { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
    opacity: angle < 89 ? 1 : 0
    transform: Rotation {
        origin.x: card.width / 2; origin.y: card.height / 2
        axis { x: 0; y: 1; z: 0 }                    // y axis = flip horizontally; x axis = flip vertically
        angle: card.angle
    }
    TapHandler { onTapped: card.shown = !card.shown }
}
```

**Use for:** flipping a desktop widget to its settings side, revealing a weather forecast, a fun lock-screen clock transition.

## Blur In

<div class="preview"><svg width="260" height="110" viewBox="0 0 260 110"><defs><filter id="blurin"><feGaussianBlur><animate attributeName="stdDeviation" values="10;0;0;10;10" keyTimes="0;.25;.6;.85;1" dur="3.5s" repeatCount="indefinite"/></feGaussianBlur></filter></defs><text x="130" y="68" fill="#cdd6f4" font-size="34" font-weight="900" text-anchor="middle" filter="url(#blurin)">14:32</text></svg></div>

**What it is.** Content starts blurred and transparent and comes into focus: a cinematic entrance for big text like clocks and greetings.

```qml file="Demo.qml"
import QtQuick
import QtQuick.Effects

Item {
    id: root
    width: 300; height: 120
    property bool shown: false
    property real blur: shown ? 0 : 1
    Behavior on blur { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    Text { id: clock; anchors.centerIn: parent; text: "14:32"; color: "#cdd6f4"; font.pixelSize: 64; font.weight: Font.Black; visible: false }
    MultiEffect {
        anchors.fill: clock; source: clock
        blurEnabled: true; blurMax: 48; blur: root.blur
        opacity: 1 - root.blur * 0.8
    }
    TapHandler { onTapped: root.shown = !root.shown }
}
```

**Use for:** lock-screen clock appearing, desktop greeting at login, wallpaper changes, the session menu's title.

## Clip Reveal (Wipe)

<div class="preview"><svg width="300" height="100" viewBox="0 0 300 100"><clipPath id="wipe"><rect x="40" y="20" height="60"><animate attributeName="width" values="0;220;220;0;0" keyTimes="0;.25;.6;.8;1" dur="3.5s" repeatCount="indefinite"/></rect></clipPath><g clip-path="url(#wipe)"><rect x="40" y="20" width="220" height="60" rx="14" fill="#313244"/><text x="60" y="56" fill="#cdd6f4" font-size="14">Notification revealed →</text></g></svg></div>

**What it is.** A container grows from zero width (or height) with `clip: true`, revealing the content inside as if it were being wiped in.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 320; height: 100
    property bool shown: false
    Rectangle {
        id: wiper
        x: 20; y: 20; height: 60; radius: 14; color: "#313244"
        width: parent.shown ? 260 : 0
        clip: true                                       // hide the content outside the growing box
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: "Notification revealed →"; color: "#cdd6f4"; width: 220 }
    }
    TapHandler { onTapped: parent.shown = !parent.shown }
}
```

**Use for:** bar chips expanding to show text, media title revealing, Caelestia-style drawers growing out of the bar ([[ch:65-proj-drawers]]).

## Staggered List Entrance

<div class="preview"><svg width="280" height="150" viewBox="0 0 280 150"><g fill="#313244"><rect x="40" y="15" width="200" height="28" rx="10"><animate attributeName="x" values="80;40;40" keyTimes="0;.15;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;1;1" keyTimes="0;.15;1" dur="3s" repeatCount="indefinite"/></rect><rect x="40" y="51" width="200" height="28" rx="10"><animate attributeName="x" values="80;80;40;40" keyTimes="0;.06;.21;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;0;1;1" keyTimes="0;.06;.21;1" dur="3s" repeatCount="indefinite"/></rect><rect x="40" y="87" width="200" height="28" rx="10"><animate attributeName="x" values="80;80;40;40" keyTimes="0;.12;.27;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;0;1;1" keyTimes="0;.12;.27;1" dur="3s" repeatCount="indefinite"/></rect><rect x="40" y="123" width="200" height="20" rx="8"><animate attributeName="x" values="80;80;40;40" keyTimes="0;.18;.33;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;0;1;1" keyTimes="0;.18;.33;1" dur="3s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** Items of a list or grid enter one after another with a small delay each, as a cascade.

```qml file="Demo.qml"
import QtQuick

Column {
    id: list
    spacing: 8
    property bool shown: true
    Repeater {
        model: ["Wi-Fi", "Bluetooth", "Night light", "Caffeine"]
        Rectangle {
            id: row
            required property string modelData
            required property int index
            width: 220; height: 34; radius: 10; color: "#313244"
            opacity: 0
            Text { anchors.centerIn: parent; text: row.modelData; color: "#cdd6f4" }
            transform: Translate { id: tr; x: 40 }
            SequentialAnimation {
                running: list.shown
                PauseAnimation { duration: row.index * 50 }               // the stagger
                ParallelAnimation {
                    NumberAnimation { target: row; property: "opacity"; to: 1; duration: 220 }
                    NumberAnimation { target: tr; property: "x"; to: 0; duration: 320; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
```

For ListView/GridView use `populate`/`add` transitions with `ViewTransition.index` ([[ch:a1-types|see Animation Types]]).

**Use for:** control-center tiles, session-menu buttons, launcher results, notification history opening.

## Exit by Swipe

<div class="preview"><svg width="320" height="100" viewBox="0 0 320 100"><rect y="25" width="200" height="50" rx="14" fill="#313244"><animate attributeName="x" values="60;60;340;340;60" keyTimes="0;.3;.55;.9;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines="0 0 1 1;.6 0 .9 .4;0 0 1 1;0 0 1 1"/><animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;.3;.55;.9;1" dur="4s" repeatCount="indefinite"/></rect><path d="M150 50 h40" stroke="#a6adc8" stroke-width="2"><animate attributeName="opacity" values="0;1;0;0" keyTimes="0;.3;.5;1" dur="4s" repeatCount="indefinite"/></path></svg></div>

**What it is.** Drag a card sideways to dismiss it. Past a threshold it flies off with momentum; otherwise it springs back.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: card
    signal dismissed()
    width: 260; height: 64; radius: 16; color: "#313244"
    opacity: 1 - Math.abs(x) / 300
    Text { anchors.centerIn: parent; text: "Swipe me →"; color: "#cdd6f4" }

    Behavior on x { enabled: !drag.active; NumberAnimation { id: back; duration: 250; easing.type: Easing.OutCubic } }
    DragHandler {
        id: drag
        yAxis.enabled: false
        onActiveChanged: {
            if (active) return
            if (Math.abs(card.x) > 110) { fly.to = card.x > 0 ? 400 : -400; fly.restart() }
            else card.x = 0                                        // spring back
        }
    }
    NumberAnimation { id: fly; target: card; property: "x"; duration: 200; easing.type: Easing.InCubic
                      onFinished: card.dismissed() }
}
```

**Use for:** notification cards, clipboard history items, closing windows in an overview.

## Exit by Shrink to Target

<div class="preview"><svg width="320" height="130" viewBox="0 0 320 130"><circle cx="280" cy="25" r="12" fill="#45475a"/><text x="280" y="30" fill="#cdd6f4" font-size="13" text-anchor="middle">🔔</text><rect rx="14" fill="#313244"><animate attributeName="x" values="40;40;270;270;40" keyTimes="0;.3;.55;.9;1" dur="4s" repeatCount="indefinite"/><animate attributeName="y" values="60;60;18;18;60" keyTimes="0;.3;.55;.9;1" dur="4s" repeatCount="indefinite"/><animate attributeName="width" values="180;180;20;20;180" keyTimes="0;.3;.55;.9;1" dur="4s" repeatCount="indefinite"/><animate attributeName="height" values="50;50;14;14;50" keyTimes="0;.3;.55;.9;1" dur="4s" repeatCount="indefinite"/><animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;.3;.58;.9;1" dur="4s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** When dismissed, the element shrinks and flies into the icon where it "goes" (for example, a notification into the bell), teaching users where to find it later.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 360; height: 200
    Text { id: bell; x: 320; y: 10; text: "notifications"; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: "#cdd6f4" }
    Rectangle {
        id: card
        x: 40; y: 90; width: 220; height: 60; radius: 14; color: "#313244"
        Text { anchors.centerIn: parent; text: "New message"; color: "#cdd6f4" }
        TapHandler { onTapped: toBell.restart() }
    }
    ParallelAnimation {
        id: toBell
        NumberAnimation { target: card; property: "x"; to: bell.x; duration: 450; easing.type: Easing.InOutCubic }
        NumberAnimation { target: card; property: "y"; to: bell.y; duration: 450; easing.type: Easing.InOutCubic }
        NumberAnimation { target: card; property: "scale"; to: 0.1; duration: 450; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 450; easing.type: Easing.InQuad }
    }
}
```

**Use for:** notifications going to the bell or notification center, minimizing to the dock, saving to a clipboard icon.
