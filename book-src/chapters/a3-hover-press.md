# Animations: Hover and Press Micro-interactions

Tiny reactions to the pointer. They're what make a bar feel responsive and premium. Each pattern is a small self-contained item you can wrap around your own buttons. Keep them **fast** (100–200 ms): the user is waiting.

## Scale Up on Hover

<div class="preview"><svg width="260" height="100" viewBox="0 0 260 100"><g transform="translate(130 50)"><rect x="-26" y="-26" width="52" height="52" rx="14" fill="#cba6f7"><animateTransform attributeName="transform" type="scale" values="1;1.15;1.15;1" keyTimes="0;.15;.6;.75" dur="2.5s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** The item grows slightly when hovered and returns when the pointer leaves.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    width: 56; height: 56; radius: 14; color: "#cba6f7"
    scale: hover.hovered ? 1.12 : 1
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 2 } }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
}
```

**Use for:** dock icons, launcher grid icons, tray icons, workspace dots.

## Press Down (Squish)

<div class="preview"><svg width="260" height="100" viewBox="0 0 260 100"><g transform="translate(130 50)"><rect x="-60" y="-22" width="120" height="44" rx="22" fill="#313244"><animateTransform attributeName="transform" type="scale" values="1;0.9;1.03;1;1" keyTimes="0;.1;.2;.28;1" dur="2s" repeatCount="indefinite"/></rect><text y="5" fill="#cdd6f4" font-size="13" text-anchor="middle">Apply</text></g></svg></div>

**What it is.** The button shrinks while pressed and pops back on release, giving tactile feedback like a physical button.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    width: 140; height: 44; radius: 22; color: "#313244"
    scale: tap.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: tap.pressed ? 80 : 250; easing.type: tap.pressed ? Easing.OutQuad : Easing.OutBack } }
    Text { anchors.centerIn: parent; text: "Apply"; color: "#cdd6f4" }
    TapHandler { id: tap }
}
```

**Use for:** every clickable button and tile. Combine it with any hover effect.

## Lift with Shadow

<div class="preview"><svg width="260" height="120" viewBox="0 0 260 120"><defs><filter id="lift" x="-30%" y="-30%" width="160%" height="180%"><feDropShadow dx="0" stdDeviation="4" flood-color="#000" flood-opacity=".6"><animate attributeName="dy" values="2;12;12;2" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/><animate attributeName="stdDeviation" values="3;10;10;3" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/></feDropShadow></filter></defs><rect x="70" width="120" height="70" rx="16" fill="#313244" filter="url(#lift)"><animate attributeName="y" values="30;20;20;30" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** On hover the card rises a few pixels and its shadow grows and softens, as if it lifted off the surface.

```qml file="Demo.qml"
import QtQuick
import QtQuick.Effects

Item {
    width: 220; height: 140
    Rectangle {
        id: card
        width: 160; height: 90; radius: 16; color: "#313244"
        anchors.centerIn: parent
        anchors.verticalCenterOffset: hover.hovered ? -6 : 0
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: "black"
            shadowOpacity: hover.hovered ? 0.55 : 0.3
            shadowBlur: hover.hovered ? 1.0 : 0.4
            shadowVerticalOffset: hover.hovered ? 10 : 3
            Behavior on shadowBlur { NumberAnimation { duration: 200 } }
            Behavior on shadowVerticalOffset { NumberAnimation { duration: 200 } }
            Behavior on shadowOpacity { NumberAnimation { duration: 200 } }
        }
        HoverHandler { id: hover }
    }
}
```

**Use for:** wallpaper thumbnails, app cards, desktop widgets, notification cards.

## Glow

<div class="preview"><svg width="260" height="110" viewBox="0 0 260 110"><defs><filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="0" dy="0" flood-color="#cba6f7"><animate attributeName="stdDeviation" values="0;9;9;0" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/><animate attributeName="flood-opacity" values="0;1;1;0" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/></feDropShadow></filter></defs><rect x="80" y="30" width="100" height="50" rx="25" fill="#cba6f7" filter="url(#glow)"/></svg></div>

**What it is.** A colored halo blooms around the item on hover (a shadow in the accent color with no offset).

```qml file="Demo.qml"
import QtQuick
import QtQuick.Effects

Rectangle {
    width: 120; height: 50; radius: 25; color: "#cba6f7"
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#cba6f7"
        shadowHorizontalOffset: 0; shadowVerticalOffset: 0
        shadowBlur: hover.hovered ? 1.0 : 0.0
        shadowOpacity: hover.hovered ? 0.9 : 0.0
        autoPaddingEnabled: true
        Behavior on shadowBlur { NumberAnimation { duration: 250 } }
        Behavior on shadowOpacity { NumberAnimation { duration: 250 } }
    }
    HoverHandler { id: hover }
}
```

**Use for:** the active workspace, a "now playing" button, neon/cyberpunk rices, focus indicators.

## Color and State Layer

<div class="preview"><svg width="260" height="100" viewBox="0 0 260 100"><rect x="70" y="28" width="120" height="44" rx="14" fill="#313244"/><rect x="70" y="28" width="120" height="44" rx="14" fill="#cdd6f4"><animate attributeName="opacity" values="0;.1;.1;.2;.1;0" keyTimes="0;.2;.45;.5;.6;.8" dur="3s" repeatCount="indefinite"/></rect><text x="130" y="55" fill="#cdd6f4" font-size="13" text-anchor="middle">Settings</text></svg></div>

**What it is.** Material Design's standard: a translucent overlay in the text color appears on hover (8%) and darkens on press (16%). It works on any background color.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    width: 140; height: 44; radius: 14; color: "#313244"
    Text { anchors.centerIn: parent; text: "Settings"; color: "#cdd6f4" }
    Rectangle {                                         // the state layer
        anchors.fill: parent; radius: parent.radius
        color: "#cdd6f4"
        opacity: area.pressed ? 0.16 : area.containsMouse ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
}
```

**Use for:** every list row, menu item and button in an M3-style rice. Make it a reusable `StateLayer.qml` ([[ch:43-design-system]]).

## Icon Fill on Hover

<div class="preview"><svg width="260" height="100" viewBox="0 0 260 100"><path d="M130 72 L106 48 A14 14 0 0 1 130 30 A14 14 0 0 1 154 48 Z" fill="#f38ba8" stroke="#f38ba8" stroke-width="3"><animate attributeName="fill-opacity" values="0;1;1;0" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/></path></svg></div>

**What it is.** A Material Symbols outline icon fills in smoothly on hover, using the variable font's FILL axis.

```qml file="Demo.qml"
import QtQuick

Text {
    property real fill: hover.hovered ? 1 : 0
    Behavior on fill { NumberAnimation { duration: 200 } }
    text: "favorite"
    font.family: "Material Symbols Rounded"
    font.pixelSize: 48
    font.variableAxes: ({ "FILL": fill, "wght": 400 + 200 * fill })     // bolder as it fills
    color: "#f38ba8"
    HoverHandler { id: hover }
}
```

Needs Qt 6.7+ and the variable Material Symbols font.

**Use for:** toggle buttons, like/favorite actions, nav icons in sidebars, the active tab.

## Wiggle (Attention)

<div class="preview"><svg width="240" height="100" viewBox="0 0 240 100"><g transform="translate(120 50)"><g><animateTransform attributeName="transform" type="rotate" values="0;-14;12;-8;5;0;0" keyTimes="0;.06;.12;.18;.24;.3;1" dur="2.5s" repeatCount="indefinite"/><rect x="-24" y="-24" width="48" height="48" rx="12" fill="#f9e2af"/></g></g></svg></div>

**What it is.** A short left-right rotation shake that draws attention: "something happened here".

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: icon
    width: 50; height: 50; radius: 12; color: "#f9e2af"
    function wiggle() { anim.restart() }
    SequentialAnimation {
        id: anim
        RotationAnimation { target: icon; to: -14; duration: 60 }
        RotationAnimation { target: icon; to: 12; duration: 90 }
        RotationAnimation { target: icon; to: -8; duration: 80 }
        RotationAnimation { target: icon; to: 5; duration: 70 }
        RotationAnimation { target: icon; to: 0; duration: 60 }
    }
    TapHandler { onTapped: icon.wiggle() }
}
```

**Use for:** the notification bell on a new message, a wrong-password field (use `x` instead of `rotation` for a horizontal shake), an update counter.

## Jelly (Squash and Stretch)

<div class="preview"><svg width="240" height="110" viewBox="0 0 240 110"><g transform="translate(120 55)"><circle r="28" fill="#94e2d5"><animateTransform attributeName="transform" type="scale" values="1 1;1.25 .8;.85 1.15;1.08 .94;.97 1.02;1 1;1 1" keyTimes="0;.08;.16;.24;.32;.4;1" dur="2.5s" repeatCount="indefinite"/></circle></g></svg></div>

**What it is.** On click the item squashes wide, stretches tall, and wobbles back. It's cartoonish, but delightful on small buttons.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: blob
    width: 60; height: 60; radius: 30; color: "#94e2d5"
    property real sx: 1
    property real sy: 1
    transform: Scale { origin.x: blob.width / 2; origin.y: blob.height / 2; xScale: blob.sx; yScale: blob.sy }
    SequentialAnimation {
        id: jelly
        ParallelAnimation { NumberAnimation { target: blob; property: "sx"; to: 1.25; duration: 90 }
                            NumberAnimation { target: blob; property: "sy"; to: 0.8; duration: 90 } }
        ParallelAnimation { NumberAnimation { target: blob; property: "sx"; to: 0.88; duration: 110 }
                            NumberAnimation { target: blob; property: "sy"; to: 1.12; duration: 110 } }
        ParallelAnimation { NumberAnimation { target: blob; property: "sx"; to: 1; duration: 400; easing.type: Easing.OutElastic }
                            NumberAnimation { target: blob; property: "sy"; to: 1; duration: 400; easing.type: Easing.OutElastic } }
    }
    TapHandler { onTapped: jelly.restart() }
}
```

**Use for:** play/pause buttons, a desktop pet, fun toggle switches, the launcher button.

## Magnetic Hover

<div class="preview"><svg width="280" height="120" viewBox="0 0 280 120"><circle r="4" fill="#f5e0dc"><animate attributeName="cx" values="100;170;190;150;100" dur="4s" repeatCount="indefinite"/><animate attributeName="cy" values="50;40;75;80;50" dur="4s" repeatCount="indefinite"/></circle><rect width="70" height="44" rx="22" fill="#cba6f7" opacity=".9"><animate attributeName="x" values="100;111;115;107;100" dur="4s" repeatCount="indefinite"/><animate attributeName="y" values="38;36;43;44;38" dur="4s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** The button leans toward the pointer while hovered, as if attracted to it, and snaps back to center when the pointer leaves.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 200; height: 120
    Rectangle {
        id: btn
        width: 90; height: 46; radius: 23; color: "#cba6f7"
        anchors.centerIn: parent
        readonly property point p: hover.point.position
        // offset = distance from center × strength, only while hovered
        anchors.horizontalCenterOffset: hover.hovered ? (p.x - parent.width / 2) * 0.25 : 0
        anchors.verticalCenterOffset: hover.hovered ? (p.y - parent.height / 2) * 0.25 : 0
        Behavior on anchors.horizontalCenterOffset { SmoothedAnimation { velocity: 300 } }
        Behavior on anchors.verticalCenterOffset { SmoothedAnimation { velocity: 300 } }
    }
    HoverHandler { id: hover }                       // on the parent: tracks the pointer near the button too
}
```

**Use for:** big call-to-action buttons, power-menu bubbles, launcher button, playful desktop widgets.

## Underline Grow

<div class="preview"><svg width="280" height="90" viewBox="0 0 280 90"><text x="140" y="45" fill="#cdd6f4" font-size="16" text-anchor="middle">Notifications</text><rect y="54" height="3" rx="1.5" fill="#cba6f7"><animate attributeName="width" values="0;110;110;0" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/><animate attributeName="x" values="140;85;85;140" keyTimes="0;.2;.6;.8" dur="3s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** A line grows out from the center under a label on hover (or when selected).

```qml file="Demo.qml"
import QtQuick

Item {
    width: label.implicitWidth; height: label.implicitHeight + 8
    Text { id: label; text: "Notifications"; color: "#cdd6f4"; font.pixelSize: 16 }
    Rectangle {
        anchors { top: label.bottom; topMargin: 3; horizontalCenter: label.horizontalCenter }
        height: 3; radius: 1.5; color: "#cba6f7"
        width: hover.hovered ? label.width : 0
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }
    HoverHandler { id: hover }
}
```

**Use for:** tab bars in sidebars and settings, links, the active window title.

## Ripple

<div class="preview"><svg width="260" height="110" viewBox="0 0 260 110"><clipPath id="rip2"><rect x="60" y="30" width="140" height="50" rx="14"/></clipPath><rect x="60" y="30" width="140" height="50" rx="14" fill="#313244"/><g clip-path="url(#rip2)"><circle cx="100" cy="55" fill="#cdd6f4"><animate attributeName="r" values="0;100" dur="1.4s" repeatCount="indefinite"/><animate attributeName="opacity" values=".35;0" dur="1.4s" repeatCount="indefinite"/></circle></g></svg></div>

**What it is.** A circle spreads out from the exact click point and fades, Material's classic touch feedback.

The complete code is in the effects gallery: [[ch:g6-effects|Click Ripple]].

**Use for:** quick-settings tiles, list rows, any large clickable surface.

## Tooltip Delay and Fade

<div class="preview"><svg width="260" height="110" viewBox="0 0 260 110"><rect x="110" y="60" width="40" height="30" rx="10" fill="#313244"/><g opacity="0"><animate attributeName="opacity" values="0;0;1;1;0" keyTimes="0;.3;.4;.75;.8" dur="3s" repeatCount="indefinite"/><rect x="85" y="18" width="90" height="28" rx="8" fill="#11111b"/><text x="130" y="36" fill="#cdd6f4" font-size="11" text-anchor="middle">Wi-Fi: Home-5G</text></g></svg></div>

**What it is.** A tooltip that appears only after the pointer rests for 500 ms (so it doesn't flicker while you move across the bar), fades in, and fades out quickly when you leave.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 220; height: 120
    Rectangle { id: target; width: 40; height: 30; radius: 10; color: "#313244"; anchors.centerIn: parent; anchors.verticalCenterOffset: 20 }
    HoverHandler { id: hover; target: target }
    Timer { id: delay; interval: 500; running: hover.hovered }
    readonly property bool tip: hover.hovered && !delay.running
    Rectangle {
        anchors { bottom: target.top; horizontalCenter: target.horizontalCenter }
        width: t.implicitWidth + 16; height: 26; radius: 8; color: "#11111b"
        opacity: parent.tip ? 1 : 0
        anchors.bottomMargin: parent.tip ? 8 : 2
        Behavior on opacity { NumberAnimation { duration: parent.tip ? 150 : 80 } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 150 } }
        Text { id: t; anchors.centerIn: parent; text: "Wi-Fi: Home-5G"; color: "#cdd6f4"; font.pixelSize: 11 }
    }
}
```

In a real bar, put the tooltip in a [[PopupWindow]] so it can extend beyond the bar ([[ch:32-popups-menus]]).

**Use for:** status icons, tray icons, workspace dots (window list), any icon-only button.
