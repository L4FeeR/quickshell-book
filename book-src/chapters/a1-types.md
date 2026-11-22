# Animations: Every Animation Type

Every animation building block in Qt Quick (plus Quickshell's [[EasingCurve]]), each with a preview, a minimal example and where it's useful in a rice. All types come from `import QtQuick`.

## NumberAnimation

<div class="preview"><svg width="320" height="80" viewBox="0 0 320 80"><rect x="20" y="36" width="280" height="8" rx="4" fill="#313244"/><circle cy="40" r="14" fill="#cba6f7"><animate attributeName="cx" values="34;286;34" dur="2.4s" repeatCount="indefinite" calcMode="spline" keySplines=".33 1 .68 1;.33 1 .68 1"/></circle></svg></div>

**What it is.** Animates any **number** property (`x`, `y`, `width`, `opacity`, `scale`, `rotation`, `radius`…) from one value to another. The workhorse of QML motion.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 400; height: 80
    Rectangle {
        id: dot
        width: 28; height: 28; radius: 14; color: "#cba6f7"
        anchors.verticalCenter: parent.verticalCenter
        NumberAnimation on x {                         // runs immediately, loops back and forth
            from: 0; to: 372
            duration: 1200
            easing.type: Easing.InOutCubic
            loops: Animation.Infinite
        }
    }
}
```

| Property | Meaning |
|---|---|
| `target` / `targets` | which object(s) (implicit with `on prop` or Behavior) |
| `property` / `properties` | which property ("x" or "x,y,opacity") |
| `from`, `to` | start and end values (omit `from` to start from the current value) |
| `duration` | ms, default 250 |
| `easing.*` | curve ([[ch:a0-overview|see all curves]]) |
| `loops`, `running`, `paused`, `alwaysRunToEnd` | control |

**Use for:** sliding indicators, growing pills, fading popups, progress bars, scaling icons on hover; basically 80% of everything.

## ColorAnimation

<div class="preview"><svg width="240" height="90" viewBox="0 0 240 90"><rect x="70" y="15" width="100" height="60" rx="18" fill="#cba6f7"><animate attributeName="fill" values="#cba6f7;#89b4fa;#a6e3a1;#f38ba8;#cba6f7" dur="4s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** Smoothly blends between colors instead of jumping.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: box
    width: 140; height: 80; radius: 18
    property bool active: false
    color: active ? "#a6e3a1" : "#45475a"
    Behavior on color { ColorAnimation { duration: 300 } }
    TapHandler { onTapped: box.active = !box.active }
}
```

**Use for:** toggle tiles turning accent-colored, hover backgrounds, battery color changing as it drains, crossfading the whole theme when the wallpaper (and palette) changes.

## RotationAnimation

<div class="preview"><svg width="260" height="100" viewBox="0 0 260 100"><g transform="translate(70 50)"><rect x="-22" y="-22" width="44" height="44" rx="10" fill="#89b4fa"><animateTransform attributeName="transform" type="rotate" values="0;180;180;0" keyTimes="0;.4;.6;1" dur="3s" repeatCount="indefinite"/></rect></g><g transform="translate(190 50)"><text x="0" y="10" font-size="32" fill="#cba6f7" text-anchor="middle">⟳<animateTransform attributeName="transform" type="rotate" from="0" to="360" dur="1s" repeatCount="indefinite"/></text></g></svg></div>

**What it is.** Animates `rotation`, with control over the **direction** so a turn from 350° to 10° can go the short way.

```qml file="Demo.qml"
import QtQuick

Row {
    spacing: 40
    Rectangle {                                         // turn toward a target angle the shortest way
        id: arrow
        width: 60; height: 60; radius: 12; color: "#89b4fa"
        property real target: 0
        Behavior on rotation { RotationAnimation { duration: 400; direction: RotationAnimation.Shortest; easing.type: Easing.OutCubic } }
        rotation: target
        TapHandler { onTapped: arrow.target = (arrow.target + 135) % 360 }
    }
    Text {                                              // endless spinner
        text: "progress_activity"; font.family: "Material Symbols Rounded"; font.pixelSize: 48; color: "#cba6f7"
        RotationAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite }
    }
}
```

`direction`: `RotationAnimation.Numerical` (default), `Clockwise`, `Counterclockwise`, `Shortest`.

**Use for:** loading spinners, refresh buttons, chevrons that flip when a section expands, compass/weather wind direction.

## PropertyAnimation

<div class="preview"><svg width="260" height="100" viewBox="0 0 260 100"><rect rx="12" fill="#cba6f7"><animate attributeName="x" values="30;170;30" dur="3s" repeatCount="indefinite"/><animate attributeName="y" values="30;20;30" dur="3s" repeatCount="indefinite"/><animate attributeName="width" values="40;60;40" dur="3s" repeatCount="indefinite"/><animate attributeName="height" values="40;60;40" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="1;.4;1" dur="3s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** The generic base of NumberAnimation and ColorAnimation. Use it to animate **several properties at once**, or properties of other types (`size`, `point`, `rect`, `real`).

```qml file="Demo.qml"
import QtQuick

Item {
    width: 300; height: 120
    Rectangle {
        id: card
        x: 10; y: 30; width: 60; height: 60; radius: 12; color: "#cba6f7"
        TapHandler { onTapped: grow.restart() }
    }
    PropertyAnimation {
        id: grow
        target: card
        properties: "width,height,x"           // several properties, comma-separated
        to: 120                                 // all of them animate to 120
        duration: 400; easing.type: Easing.OutBack
    }
}
```

> [!NOTE] One `to` for all
> With `properties`, every listed property gets the same `from`/`to`. Inside a **Transition** that's not a problem, because the target values come from the state change: `NumberAnimation { properties: "x,y,width,height,opacity" }` animates each to its own new value.

**Use for:** transitions between states, resizing cards, anything where several properties move together.

## SmoothedAnimation

<div class="preview"><svg width="320" height="100" viewBox="0 0 320 100"><circle r="5" fill="#f5e0dc"><animate attributeName="cx" values="40;280;120;250;40" dur="4s" repeatCount="indefinite" calcMode="discrete"/><animate attributeName="cy" values="30;70;60;25;30" dur="4s" repeatCount="indefinite" calcMode="discrete"/></circle><circle r="12" fill="none" stroke="#cba6f7" stroke-width="3"><animate attributeName="cx" values="40;280;120;250;40" dur="4s" repeatCount="indefinite"/><animate attributeName="cy" values="30;70;60;25;30" dur="4s" repeatCount="indefinite"/></circle></svg></div>

**What it is.** Follows a moving target at a set **velocity** with smooth acceleration, and re-targets gracefully when the target keeps changing. Perfect for things that chase the mouse or a selection.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 400; height: 250
    Rectangle {
        id: follower
        width: 30; height: 30; radius: 15
        color: "transparent"; border.color: "#cba6f7"; border.width: 3
        x: hover.point.position.x - 15
        y: hover.point.position.y - 15
        Behavior on x { SmoothedAnimation { velocity: 600 } }      // px per second
        Behavior on y { SmoothedAnimation { velocity: 600 } }
    }
    HoverHandler { id: hover }
}
```

`velocity`, `duration` (−1 = use velocity), `maximumEasingTime`, `reversingMode` (`SmoothedAnimation.Eased`, `Immediate`, `Sync`).

**Use for:** a highlight that follows the hovered app in a dock, a custom cursor glow, list highlights (`ListView.highlightMoveVelocity` uses it internally).

## SpringAnimation

<div class="preview"><svg width="320" height="100" viewBox="0 0 320 100"><rect x="150" y="10" width="2" height="16" fill="#585b70"/><circle cy="50" r="16" fill="#a6e3a1"><animate attributeName="cx" values="60;280;245;268;256;262;260;260;60" keyTimes="0;.15;.25;.33;.4;.46;.52;.9;1" dur="4s" repeatCount="indefinite"/></circle></svg></div>

**What it is.** Physics: the value behaves like a mass on a spring, overshooting and wobbling into place. Tunable with `spring`, `damping` and `mass`.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 400; height: 120
    property bool right: false
    Rectangle {
        width: 40; height: 40; radius: 20; color: "#a6e3a1"
        anchors.verticalCenter: parent.verticalCenter
        x: parent.right ? 340 : 20
        Behavior on x { SpringAnimation { spring: 3; damping: 0.2; mass: 1; epsilon: 0.5 } }
    }
    TapHandler { onTapped: parent.right = !parent.right }
}
```

| Property | Effect |
|---|---|
| `spring` | stiffness: higher = faster, snappier |
| `damping` | 0–1: lower = more wobble |
| `mass` | heavier = slower, more momentum |
| `epsilon` | how close counts as "arrived" |
| `modulus` | wrap-around for angles (360) |

**Use for:** the Dynamic Island size morph, dock icon bounce, playful toggles, notification cards settling in.

## SequentialAnimation

<div class="preview"><svg width="320" height="100" viewBox="0 0 320 100"><rect width="36" height="36" rx="8" fill="#cba6f7"><animate attributeName="x" values="40;240;240;240;40" keyTimes="0;.25;.5;.75;1" dur="4s" repeatCount="indefinite"/><animate attributeName="y" values="20;20;50;50;20" keyTimes="0;.25;.5;.75;1" dur="4s" repeatCount="indefinite"/><animate attributeName="opacity" values="1;1;1;.3;1" keyTimes="0;.25;.5;.75;1" dur="4s" repeatCount="indefinite"/></rect><g fill="#a6adc8" font-size="10"><text x="120" y="92">1 → 2 → 3 → 4, one after another</text></g></svg></div>

**What it is.** Runs its child animations **one after another**.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: box
    width: 40; height: 40; radius: 8; color: "#cba6f7"
    SequentialAnimation {
        running: true; loops: Animation.Infinite
        NumberAnimation { target: box; property: "x"; to: 200; duration: 500; easing.type: Easing.OutCubic }
        NumberAnimation { target: box; property: "y"; to: 60; duration: 300 }
        NumberAnimation { target: box; property: "opacity"; to: 0.3; duration: 300 }
        ParallelAnimation {                                  // reset everything at once
            NumberAnimation { target: box; properties: "x,y"; to: 0; duration: 500 }
            NumberAnimation { target: box; property: "opacity"; to: 1; duration: 500 }
        }
    }
}
```

**Use for:** multi-step choreography: a panel slides in *then* its content fades in, a shake (left-right-left), a notification that pops, waits, and leaves.

## ParallelAnimation

<div class="preview"><svg width="260" height="110" viewBox="0 0 260 110"><rect rx="14" fill="#89b4fa"><animate attributeName="x" values="40;150;40" dur="2.5s" repeatCount="indefinite"/><animate attributeName="y" values="60;20;60" dur="2.5s" repeatCount="indefinite"/><animate attributeName="width" values="30;70;30" dur="2.5s" repeatCount="indefinite"/><animate attributeName="height" values="30;70;30" dur="2.5s" repeatCount="indefinite"/><animate attributeName="fill" values="#89b4fa;#f5c2e7;#89b4fa" dur="2.5s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** Runs its children **at the same time**. Combine with SequentialAnimation for complex timelines.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: card
    width: 120; height: 80; radius: 16; color: "#89b4fa"
    opacity: 0; scale: 0.7
    ParallelAnimation {
        running: true
        NumberAnimation { target: card; property: "opacity"; to: 1; duration: 250 }
        NumberAnimation { target: card; property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack }
        NumberAnimation { target: card; property: "y"; from: 40; to: 0; duration: 400; easing.type: Easing.OutCubic }
    }
}
```

**Use for:** "pop in" entrances (fade + scale + slide together), crossfades, any effect where several properties change at once.

## PauseAnimation, ScriptAction, PropertyAction

<div class="preview"><svg width="340" height="90" viewBox="0 0 340 90"><g font-size="11"><rect x="20" y="30" width="80" height="30" rx="8" fill="#cba6f7"/><text x="60" y="49" fill="#1e1e2e" text-anchor="middle">animate</text><rect x="110" y="30" width="60" height="30" rx="8" fill="#45475a"/><text x="140" y="49" fill="#cdd6f4" text-anchor="middle">pause</text><rect x="180" y="30" width="60" height="30" rx="8" fill="#a6e3a1"/><text x="210" y="49" fill="#1e1e2e" text-anchor="middle">script</text><rect x="250" y="30" width="70" height="30" rx="8" fill="#f9e2af"/><text x="285" y="49" fill="#1e1e2e" text-anchor="middle">set prop</text></g><rect x="20" y="66" height="4" rx="2" fill="#f5e0dc"><animate attributeName="width" values="0;300" dur="3s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** Helpers for timelines: **PauseAnimation** waits, **ScriptAction** runs code at that moment, and **PropertyAction** sets a property instantly (no tween).

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: toast
    width: 220; height: 50; radius: 14; color: "#313244"; opacity: 0; visible: false
    Text { anchors.centerIn: parent; text: "Saved ✓"; color: "#a6e3a1" }

    SequentialAnimation {
        id: showToast
        PropertyAction { target: toast; property: "visible"; value: true }   // appear instantly
        NumberAnimation { target: toast; property: "opacity"; to: 1; duration: 200 }
        PauseAnimation { duration: 1500 }                                      // stay
        NumberAnimation { target: toast; property: "opacity"; to: 0; duration: 300 }
        PropertyAction { target: toast; property: "visible"; value: false }  // stop catching clicks
        ScriptAction { script: console.log("toast finished") }
    }
    Component.onCompleted: showToast.start()
}
```

**Use for:** show → wait → hide sequences (toasts, OSDs), setting `visible`/`z` at exact moments, triggering the next action after an animation.

## Behavior

<div class="preview"><svg width="300" height="90" viewBox="0 0 300 90"><rect x="30" y="30" height="30" rx="15" fill="#cba6f7"><animate attributeName="width" values="40;240;240;120;120;40" keyTimes="0;.15;.4;.55;.8;1" dur="5s" repeatCount="indefinite" calcMode="spline" keySplines=".2 .8 .2 1;0 0 1 1;.2 .8 .2 1;0 0 1 1;.2 .8 .2 1"/></rect><text x="150" y="82" fill="#a6adc8" font-size="10" text-anchor="middle">value changes anywhere → always animated</text></svg></div>

**What it is.** Attaches an animation to a property so **every change** animates, whatever caused it (a binding, a click, a service update). The easiest way to add motion.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    property real level: 0.3                 // imagine: bound to Audio.volume
    width: 300; height: 20; radius: 10; color: "#313244"
    Rectangle {
        width: parent.width * parent.level
        height: parent.height; radius: 10; color: "#cba6f7"
        Behavior on width {
            enabled: true                    // can be turned off, e.g. while dragging
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
    }
    TapHandler { onTapped: parent.level = Math.random() }
}
```

**Use for:** any value driven by system state (volume fill, battery bar, workspace indicator position), hover sizes and colors. Disable it (`enabled: false`) during drags so the UI follows your finger exactly.

## Animators (Render-Thread Animations)

<div class="preview"><svg width="320" height="100" viewBox="0 0 320 100"><g transform="translate(60 50)"><rect x="-20" y="-20" width="40" height="40" rx="10" fill="#cba6f7"><animateTransform attributeName="transform" type="rotate" from="0" to="360" dur="2s" repeatCount="indefinite"/></rect></g><g transform="translate(160 50)"><circle r="20" fill="#89b4fa"><animate attributeName="r" values="12;22;12" dur="1.5s" repeatCount="indefinite"/></circle></g><circle cx="260" cy="50" r="20" fill="#a6e3a1"><animate attributeName="opacity" values="1;.2;1" dur="1.5s" repeatCount="indefinite"/></circle><g fill="#a6adc8" font-size="10" text-anchor="middle"><text x="60" y="94">Rotation</text><text x="160" y="94">Scale</text><text x="260" y="94">Opacity</text></g></svg></div>

**What it is.** `OpacityAnimator`, `ScaleAnimator`, `RotationAnimator`, `XAnimator`, `YAnimator` and `UniformAnimator` run on Qt's **render thread**: they stay perfectly smooth even when JavaScript or a heavy layout is busy on the main thread.

```qml file="Demo.qml"
import QtQuick

Row {
    spacing: 40
    Rectangle {
        width: 50; height: 50; radius: 12; color: "#cba6f7"
        RotationAnimator on rotation { from: 0; to: 360; duration: 2000; loops: Animation.Infinite }
    }
    Rectangle {
        width: 50; height: 50; radius: 25; color: "#89b4fa"
        SequentialAnimation on scale {                         // animators can be grouped too
            loops: Animation.Infinite
            ScaleAnimator { from: 0.6; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            ScaleAnimator { from: 1.0; to: 0.6; duration: 700; easing.type: Easing.InOutSine }
        }
    }
}
```

> [!NOTE] Trade-off
> An animator only writes the final value back to the property when it finishes, so bindings that read the property mid-animation see the old value. Use them for purely visual, self-contained motion.

**Use for:** spinners, pulsing indicators, the spinning vinyl, anything that must never stutter.

## PathAnimation

<div class="preview"><svg width="320" height="120" viewBox="0 0 320 120"><path id="pa" d="M30 90 C 90 0, 230 0, 290 90" fill="none" stroke="#45475a" stroke-dasharray="4 4"/><circle r="10" fill="#f9e2af"><animateMotion dur="2.5s" repeatCount="indefinite" path="M30 90 C 90 0, 230 0, 290 90" keyPoints="0;1;0" keyTimes="0;.5;1" calcMode="linear"/></circle></svg></div>

**What it is.** Moves an item **along a curve** (any `Path`), optionally rotating it to follow the direction.

```qml file="Demo.qml"
import QtQuick

Item {
    width: 400; height: 200
    Rectangle { id: ball; width: 24; height: 24; radius: 12; color: "#f9e2af" }
    PathAnimation {
        running: true; loops: Animation.Infinite
        target: ball
        duration: 2000
        easing.type: Easing.InOutQuad
        anchorPoint: Qt.point(12, 12)                 // center of the ball sits on the path
        orientation: PathAnimation.Fixed              // or RightFirst: rotate along the curve
        path: Path {
            startX: 20; startY: 170
            PathCubic { x: 380; y: 170; control1X: 100; control1Y: -40; control2X: 300; control2Y: -40 }
        }
    }
}
```

**Use for:** a notification "flying" into the bell icon, a minimized window icon arcing into the dock, decorative orbiting dots.

## AnchorAnimation and AnchorChanges

<div class="preview"><svg width="300" height="120" viewBox="0 0 300 120"><rect x="20" y="15" width="260" height="90" rx="12" fill="none" stroke="#45475a"/><rect width="50" height="30" rx="8" fill="#cba6f7"><animate attributeName="x" values="28;222;222;28;28" keyTimes="0;.2;.5;.7;1" dur="5s" repeatCount="indefinite"/><animate attributeName="y" values="23;23;67;67;23" keyTimes="0;.2;.5;.7;1" dur="5s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** Animates an item moving between **anchor configurations** (e.g. from top-left to bottom-right) inside a state transition.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: frame
    width: 300; height: 120; color: "transparent"; border.color: "#45475a"; radius: 12
    property bool corner: false
    Rectangle {
        id: chip
        width: 60; height: 30; radius: 8; color: "#cba6f7"
        anchors { left: parent.left; top: parent.top; margins: 8 }
    }
    states: State {
        name: "moved"; when: frame.corner
        AnchorChanges { target: chip; anchors.left: undefined; anchors.top: undefined
                        anchors.right: frame.right; anchors.bottom: frame.bottom }
    }
    transitions: Transition { AnchorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    TapHandler { onTapped: frame.corner = !frame.corner }
}
```

**Use for:** a widget that moves between screen corners (notification position setting), a bar that switches between top and bottom with motion.

## ParentAnimation and ParentChange

<div class="preview"><svg width="320" height="120" viewBox="0 0 320 120"><rect x="20" y="20" width="120" height="80" rx="12" fill="#313244"/><rect x="180" y="20" width="120" height="80" rx="12" fill="#313244"/><rect width="40" height="40" rx="10" fill="#a6e3a1"><animate attributeName="x" values="60;220;220;60;60" keyTimes="0;.25;.5;.75;1" dur="4s" repeatCount="indefinite"/><animate attributeName="y" values="40;40;40;40;40" dur="4s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** Moves an item to a **different parent** (from one container to another) with a smooth flight between them.

```qml file="Demo.qml"
import QtQuick

Row {
    id: root
    spacing: 40
    property bool inRight: false
    Rectangle { id: left; width: 120; height: 80; radius: 12; color: "#313244" }
    Rectangle { id: right; width: 120; height: 80; radius: 12; color: "#313244" }
    Rectangle {
        id: token
        parent: left
        x: 40; y: 20; width: 40; height: 40; radius: 10; color: "#a6e3a1"
        states: State {
            when: root.inRight
            ParentChange { target: token; parent: right; x: 40; y: 20 }
        }
        transitions: Transition { ParentAnimation { NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic } } }
    }
    TapHandler { onTapped: root.inRight = !root.inRight }
}
```

**Use for:** pinning an app from the launcher into the dock, moving a tray icon between "shown" and "overflow" areas, drag-and-drop finishing animations.

## States and Transitions

<div class="preview"><svg width="300" height="130" viewBox="0 0 300 130"><rect x="20" fill="#1e1e2e" stroke="#45475a" rx="16"><animate attributeName="width" values="100;260;260;100;100" keyTimes="0;.2;.55;.75;1" dur="5s" repeatCount="indefinite"/><animate attributeName="height" values="40;110;110;40;40" keyTimes="0;.2;.55;.75;1" dur="5s" repeatCount="indefinite"/><animate attributeName="y" values="45;10;10;45;45" keyTimes="0;.2;.55;.75;1" dur="5s" repeatCount="indefinite"/></rect><text x="36" y="70" fill="#cdd6f4" font-size="12">collapsed ⇄ expanded</text></svg></div>

**What it is.** Named sets of property values (`State`) plus the animations used to move between them (`Transition`). Different transitions can be used for opening and closing.

```qml file="Demo.qml"
import QtQuick

Rectangle {
    id: card
    width: 120; height: 44; radius: 16
    color: "#1e1e2e"; border.color: "#45475a"
    property bool open: false
    Text { id: t; x: 14; y: 12; text: "Now playing"; color: "#cdd6f4" }
    Text { id: extra; x: 14; y: 40; text: "Midnight City · M83"; color: "#a6adc8"; opacity: 0 }

    states: State {
        name: "open"; when: card.open
        PropertyChanges { card.width: 260; card.height: 90 }
        PropertyChanges { extra.opacity: 1 }
    }
    transitions: [
        Transition {
            from: ""; to: "open"
            SequentialAnimation {
                NumberAnimation { properties: "width,height"; duration: 300; easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; duration: 200 }            // content after the growth
            }
        },
        Transition {
            from: "open"; to: ""
            SequentialAnimation {
                NumberAnimation { property: "opacity"; duration: 100 }            // content first, quickly
                NumberAnimation { properties: "width,height"; duration: 200; easing.type: Easing.InCubic }
            }
        }
    ]
    TapHandler { onTapped: card.open = !card.open }
}
```

**Use for:** any component with modes: collapsed/expanded media card, notification normal/expanded/dismissing, bar compact/full, launcher apps/calculator modes.

## View Transitions (ListView add / remove / displaced)

<div class="preview"><svg width="300" height="150" viewBox="0 0 300 150"><g><rect x="40" y="15" width="220" height="30" rx="10" fill="#313244"><animate attributeName="x" values="300;40;40;40" keyTimes="0;.2;.8;1" dur="5s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;1;1;0" keyTimes="0;.2;.8;1" dur="5s" repeatCount="indefinite"/></rect><rect x="40" width="220" height="30" rx="10" fill="#45475a"><animate attributeName="y" values="15;55;55;15" keyTimes="0;.2;.8;1" dur="5s" repeatCount="indefinite"/></rect><rect x="40" width="220" height="30" rx="10" fill="#45475a"><animate attributeName="y" values="55;95;95;55" keyTimes="0;.2;.8;1" dur="5s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** ListView, GridView and Repeater-like views can animate items being **added**, **removed**, **moved**, and the neighbors **displaced** to make room.

```qml file="Demo.qml"
import QtQuick

Column {
    spacing: 10
    ListModel { id: model; ListElement { t: "first" } ListElement { t: "second" } }
    Text { text: "[add]  [remove]"; color: "#89b4fa"
           TapHandler { onTapped: model.insert(0, { t: "new " + model.count }) }
           TapHandler { acceptedButtons: Qt.RightButton; onTapped: if (model.count) model.remove(0) } }
    ListView {
        width: 260; height: 200; spacing: 6; clip: true
        model: model
        delegate: Rectangle { required property string t; width: 260; height: 36; radius: 10; color: "#313244"
                              Text { anchors.centerIn: parent; text: t; color: "#cdd6f4" } }
        add:       Transition { ParallelAnimation {
                       NumberAnimation { property: "x"; from: 260; duration: 350; easing.type: Easing.OutCubic }
                       NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 } } }
        remove:    Transition { ParallelAnimation {
                       NumberAnimation { property: "x"; to: -260; duration: 250; easing.type: Easing.InCubic }
                       NumberAnimation { property: "opacity"; to: 0; duration: 250 } } }
        displaced: Transition { NumberAnimation { property: "y"; duration: 300; easing.type: Easing.OutCubic } }
    }
}
```

Slots: `add`, `remove`, `move`, `displaced`, `addDisplaced`, `removeDisplaced`, `moveDisplaced`, `populate`. Positioners (`Row`, `Column`, `Grid`, `Flow`) have `add`, `move` and `populate`.

**Use for:** notification stacks, clipboard history, launcher results (with [[ScriptModel]]), tray icons appearing, workspace dots being created.

## Staggered Delays with ViewTransition

<div class="preview"><svg width="300" height="120" viewBox="0 0 300 120"><g fill="#cba6f7"><rect x="30" y="40" width="40" height="40" rx="10"><animate attributeName="y" values="80;40;40" keyTimes="0;.2;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;1;1" keyTimes="0;.2;1" dur="3s" repeatCount="indefinite"/></rect><rect x="90" y="40" width="40" height="40" rx="10"><animate attributeName="y" values="80;80;40;40" keyTimes="0;.07;.27;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;0;1;1" keyTimes="0;.07;.27;1" dur="3s" repeatCount="indefinite"/></rect><rect x="150" y="40" width="40" height="40" rx="10"><animate attributeName="y" values="80;80;40;40" keyTimes="0;.14;.34;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;0;1;1" keyTimes="0;.14;.34;1" dur="3s" repeatCount="indefinite"/></rect><rect x="210" y="40" width="40" height="40" rx="10"><animate attributeName="y" values="80;80;40;40" keyTimes="0;.21;.41;1" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values="0;0;1;1" keyTimes="0;.21;.41;1" dur="3s" repeatCount="indefinite"/></rect></g></svg></div>

**What it is.** In view transitions, the attached `ViewTransition.index` tells each item its position, so you can delay each one a little more than the last: a **cascade**.

```qml file="Demo.qml"
import QtQuick

GridView {
    width: 300; height: 200; cellWidth: 60; cellHeight: 60
    model: 15
    delegate: Rectangle { width: 50; height: 50; radius: 12; color: "#cba6f7" }
    populate: Transition {
        id: pop
        SequentialAnimation {
            PauseAnimation { duration: pop.ViewTransition.index * 40 }        // 40 ms more per item
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 }
                NumberAnimation { property: "scale"; from: 0.6; to: 1; duration: 350; easing.type: Easing.OutBack }
            }
        }
    }
}
```

**Use for:** app grids appearing, quick-settings tiles cascading in, power-menu buttons, search results.

## FrameAnimation (Run Code Every Frame)

<div class="preview"><svg width="320" height="110" viewBox="0 0 320 110"><path fill="none" stroke="#89b4fa" stroke-width="3" d="M10 55 Q 35 20 60 55 T 110 55 T 160 55 T 210 55 T 260 55 T 310 55"><animateTransform attributeName="transform" type="translate" values="0 0;-50 0" dur="1s" repeatCount="indefinite"/></path></svg></div>

**What it is.** Calls `onTriggered` once per rendered frame with `frameTime` (seconds since the last frame), for custom physics or math-driven motion that no standard animation covers.

```qml file="Demo.qml"
import QtQuick

Canvas {
    id: wave
    width: 320; height: 100
    property real phase: 0
    FrameAnimation {
        running: wave.visible
        onTriggered: { wave.phase += frameTime * 4; wave.requestPaint() }
    }
    onPaint: {
        const ctx = getContext("2d"); ctx.reset()
        ctx.beginPath()
        for (let x = 0; x <= width; x += 4) {
            const y = height / 2 + Math.sin(x / 25 + phase) * 20
            x ? ctx.lineTo(x, y) : ctx.moveTo(x, y)
        }
        ctx.strokeStyle = "#89b4fa"; ctx.lineWidth = 3; ctx.stroke()
    }
}
```

**Use for:** wave lines under a media card, particle effects, custom spring simulations. Always bind `running` to visibility: it redraws every frame.

## Timer-Driven Steps

<div class="preview"><svg width="240" height="90" viewBox="0 0 240 90"><text x="120" y="55" fill="#cdd6f4" font-size="22" font-family="monospace" text-anchor="middle">Hello, rice<animate attributeName="opacity" values="1;1" dur="1s"/></text><rect x="182" y="35" width="3" height="26" fill="#cba6f7"><animate attributeName="opacity" values="1;0;1" dur="0.8s" repeatCount="indefinite"/></rect></svg></div>

**What it is.** Not every animation is a smooth tween. A `Timer` can step through discrete changes: a typewriter effect, a frame-by-frame icon, a countdown.

```qml file="Demo.qml"
import QtQuick

Text {
    id: tw
    property string full: "Hello, rice"
    property int shown: 0
    text: full.slice(0, shown) + (cursor.visible ? "▍" : " ")
    color: "#cdd6f4"; font.pixelSize: 24; font.family: "monospace"
    Timer { interval: 70; repeat: true; running: tw.shown < tw.full.length; onTriggered: tw.shown++ }
    Item { id: cursor; visible: true
           Timer { interval: 450; repeat: true; running: true; onTriggered: cursor.visible = !cursor.visible } }
}
```

**Use for:** a greeting on the lock screen typed out, terminal-style widgets, step counters.

## AnimatedImage and AnimatedSprite

<div class="preview"><svg width="240" height="100" viewBox="0 0 240 100"><g transform="translate(120 50)"><g><animateTransform attributeName="transform" type="scale" values="1 1;1.1 .9;.95 1.05;1 1" dur="0.6s" repeatCount="indefinite"/><circle r="26" fill="#f9e2af"/><circle cx="-9" cy="-5" r="4" fill="#1e1e2e"/><circle cx="9" cy="-5" r="4" fill="#1e1e2e"/><path d="M-10 8 Q 0 16 10 8" stroke="#1e1e2e" stroke-width="3" fill="none"/></g></g></svg></div>

**What it is.** Plays GIF/animated WebP files (`AnimatedImage`) or frames from a sprite sheet (`AnimatedSprite`).

```qml file="Demo.qml"
import QtQuick

Row {
    spacing: 20
    AnimatedImage {
        source: "file:///home/me/Pictures/cat.gif"
        width: 120; height: 120; fillMode: Image.PreserveAspectFit
        playing: visible                       // don't decode frames while hidden
        speed: 1.0
    }
    AnimatedSprite {
        source: "sprites/bongo.png"            // a horizontal strip of equal frames
        frameWidth: 64; frameHeight: 64
        frameCount: 8; frameDuration: 80
        loops: AnimatedSprite.Infinite
        running: visible
    }
}
```

**Use for:** a desktop pet, bongo cat reacting to typing, animated weather icons, loading GIFs.

## EasingCurve (Quickshell): Easing in Your Own Code

<div class="preview"><svg width="280" height="110" viewBox="0 0 280 110"><polyline fill="none" stroke="#cba6f7" stroke-width="2.5" points="20,90 50,60 80,42 110,31 140,24 170,20 200,18 230,17 260,17"/><rect x="20" y="95" width="240" height="4" rx="2" fill="#45475a"/><circle cy="97" r="6" fill="#f5e0dc"><animate attributeName="cx" values="20;260;20" dur="3s" repeatCount="indefinite"/></circle></svg></div>

**What it is.** [[EasingCurve]] evaluates any easing curve as a function, so you can map a value (a drag distance, a scroll offset, a progress) through a curve in JavaScript.

```qml file="Demo.qml"
import Quickshell
import QtQuick

Item {
    width: 300; height: 120
    EasingCurve { id: curve; curve.type: Easing.OutCubic }
    // drag the handle; the box follows through the curve (resistance near the end)
    Rectangle {
        id: handle; y: 90; width: 20; height: 20; radius: 10; color: "#f5e0dc"
        DragHandler { xAxis.minimumX: 0; xAxis.maximumX: 280; yAxis.enabled: false }
    }
    Rectangle {
        y: 20; width: 40; height: 40; radius: 10; color: "#cba6f7"
        x: curve.interpolate(handle.x / 280, 0, 260)          // eased mapping
    }
}
```

**Use for:** rubber-band overscroll, drawers that resist as you drag them open, parallax wallpapers, custom progress mappings.
