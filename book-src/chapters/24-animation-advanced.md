# Animation II: States, Transitions, Sequences

Behaviors animate single properties. For coordinated motion (a panel that slides in *while* fading *and then* reveals its content), use **states**, **transitions** and **grouped animations**.

## Grouped animations

```qml
SequentialAnimation {           // one after another
    NumberAnimation { target: panel; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic }
    PauseAnimation { duration: 100 }
    NumberAnimation { target: content; property: "opacity"; to: 1; duration: 200 }
}

ParallelAnimation {             // at the same time
    NumberAnimation { target: panel; property: "y"; to: 0; duration: 350 }
    NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 250 }
}
```

Nest them freely. Helper steps inside sequences:

| Step | Does |
|---|---|
| `PauseAnimation { duration }` | wait |
| `ScriptAction { script: doSomething() }` | run code at that moment |
| `PropertyAction { target; property; value }` | set a property instantly (e.g. `visible: true` before fading in) |

### Fade out, then hide
```qml
SequentialAnimation {
    id: hideAnim
    NumberAnimation { target: osd; property: "opacity"; to: 0; duration: 200 }
    PropertyAction { target: osd; property: "visible"; value: false }
}
```

## States

A **state** is a named set of property values. Switch states and all those properties change together:

```qml
Rectangle {
    id: panel
    property bool open: false
    width: 300; height: 400
    x: -width                                   // default state: hidden off the left edge
    opacity: 0

    states: [
        State {
            name: "open"
            when: panel.open                    // automatic: active while this is true
            PropertyChanges { panel.x: 0; panel.opacity: 1 }    // Qt 6 syntax
        }
    ]
}
```

- The default state has the empty name `""` and uses the property values written normally.
- `when:` activates a state automatically; or set `panel.state = "open"` manually.
- `PropertyChanges` lists what changes. In Qt 6 write `target.property: value` directly; older code writes `PropertyChanges { target: panel; x: 0 }`.

Other state elements: `AnchorChanges { target: x; anchors.left: … }`, `ParentChange` (re-parent an item), `StateChangeScript` (run code).

## Transitions

Without transitions, a state change jumps instantly. A **transition** animates it:

```qml
transitions: [
    Transition {
        from: ""; to: "open"                     // opening
        ParallelAnimation {
            NumberAnimation { property: "x"; duration: 350; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; duration: 250 }
        }
    },
    Transition {
        from: "open"; to: ""                     // closing: faster, accelerating
        NumberAnimation { properties: "x,opacity"; duration: 200; easing.type: Easing.InCubic }
    }
]
```

Inside a Transition you don't specify `to:` values. The animation uses the values from the state change. Write `from: "*"; to: "*"` (the default) to match any change.

## Behaviors vs states and transitions

| Use Behavior when… | Use States + Transitions when… |
|---|---|
| one or two properties animate | many properties change together |
| the same animation always applies | opening and closing need different animations |
| changes come from many places | you think in named modes (closed/open/expanded) |

Most shell code gets far with Behaviors. States shine for multi-mode components like a notification card (collapsed / expanded / dismissing) or a media widget (compact / full).

## Animating windows opening and closing

A Quickshell window that's `visible: false` isn't drawn, so you can't animate it out *after* hiding it. The pattern is to keep the window visible while the animation runs:

```qml
PanelWindow {
    id: win
    property bool open: GlobalStates.sidebarOpen
    visible: open || slide.running           // stay visible until the slide-out finishes
    color: "transparent"
    implicitWidth: 380
    anchors { top: true; bottom: true; right: true }

    Rectangle {
        id: panel
        width: parent.width; height: parent.height
        x: win.open ? 0 : width               // slide in from the right
        Behavior on x { NumberAnimation { id: slide; duration: 350; easing.type: Easing.OutCubic } }
        color: "#1e1e2e"
    }
}
```

Here `slide.running` refers to the animation inside the Behavior; while it runs, the window stays mapped.

## View transitions

Positioners and views have transition slots that animate items as they're added, removed or moved:

```qml
Row {
    add: Transition { NumberAnimation { properties: "opacity,scale"; from: 0; to: 1; duration: 200 } }
    move: Transition { NumberAnimation { properties: "x"; duration: 200; easing.type: Easing.OutCubic } }
}

ListView {
    add:       Transition { NumberAnimation { property: "x"; from: 400; duration: 300; easing.type: Easing.OutCubic } }
    remove:    Transition { NumberAnimation { property: "opacity"; to: 0; duration: 200 } }
    displaced: Transition { NumberAnimation { property: "y"; duration: 250; easing.type: Easing.OutCubic } }
    populate:  Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 } }
}
```

`ViewTransition` attached properties (`ViewTransition.index`, `ViewTransition.targetIndexes`) let you stagger animations, e.g. a delay of `ViewTransition.index * 30`.

## Animators: animations off the main thread

`OpacityAnimator`, `ScaleAnimator`, `XAnimator`, `YAnimator`, `RotationAnimator` and `UniformAnimator` run on the render thread. They stay smooth even if JavaScript is busy, but they only update the property's value at the end. Use them for continuous effects like spinners:

```qml
RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: busy }
```

## Choreography: a complete expanding card

```qml file="ExpandCard.qml"
import QtQuick

Rectangle {
    id: card
    property bool expanded: false
    width: 320
    height: expanded ? 220 : 64
    radius: expanded ? 22 : 32
    color: "#1e1e2e"
    clip: true

    Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
    Behavior on radius { NumberAnimation { duration: 380 } }

    Text { x: 20; y: 20; text: "Now playing"; color: "#cdd6f4"; font.bold: true }

    Column {
        x: 20; y: 64; spacing: 8
        opacity: card.expanded ? 1 : 0
        // content fades in AFTER the card has mostly grown, and out quickly
        Behavior on opacity { NumberAnimation { duration: card.expanded ? 250 : 100 } }
        Text { text: "Track title"; color: "white" }
        Text { text: "Artist"; color: "#a6adc8" }
    }

    TapHandler { onTapped: card.expanded = !card.expanded }
}
```

## Practice

::: exercise warm | States
Turn an expanding card into two `states` (`"collapsed"`, `"expanded"`) that change its height.
--- solution
```qml
Rectangle { id: card; width: 240; radius: 12; color: "#313244"; state: "collapsed"
    states: [ State { name: "collapsed"; PropertyChanges { card.height: 50 } },
              State { name: "expanded";  PropertyChanges { card.height: 160 } } ]
    transitions: Transition { NumberAnimation { property: "height"; duration: 250; easing.type: Easing.OutCubic } }
    TapHandler { onTapped: card.state = card.state === "collapsed" ? "expanded" : "collapsed" } }
```
:::

::: exercise practice | Different in and out
Give the card different transitions: opening uses `OutBack` (with overshoot), closing uses a quick `InCubic`.
--- solution
```qml
transitions: [
    Transition { from: "collapsed"; to: "expanded"; NumberAnimation { property: "height"; duration: 350; easing.type: Easing.OutBack } },
    Transition { from: "expanded"; to: "collapsed"; NumberAnimation { property: "height"; duration: 160; easing.type: Easing.InCubic } } ]
```
:::

::: exercise practice | Chips that slide
Make a `Row` of chips where new chips scale in (`add`) and the others slide over (`move`).
--- solution
```qml
Row { spacing: 6
    add: Transition { NumberAnimation { property: "scale"; from: 0; to: 1; duration: 250; easing.type: Easing.OutBack } }
    move: Transition { NumberAnimation { property: "x"; duration: 250; easing.type: Easing.OutCubic } }
    Repeater { model: count; Rectangle { width: 40; height: 24; radius: 12; color: "#89b4fa" } } }
```
Increase a `property int count` with a click to see it.
:::

::: exercise challenge | Slide-out sidebar
Build a sidebar window that slides in from the right and stays mapped until its slide-out finishes.
--- hint
Keep the window `visible` while either `open` is true **or** the animation is running.
--- solution
```qml
PanelWindow {
    id: w
    property bool open: false
    visible: open || slide.running
    anchors { top: true; bottom: true; right: true }
    implicitWidth: 320; color: "transparent"
    Rectangle { width: parent.width; height: parent.height; color: "#1e1e2e"
        x: w.open ? 0 : width
        Behavior on x { NumberAnimation { id: slide; duration: 300; easing.type: Easing.OutCubic } } }
}
```
:::
