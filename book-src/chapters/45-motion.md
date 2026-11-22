# Motion Design

Part III taught the mechanics of animation. This chapter covers the *craft*: how to make motion feel intentional and premium, the way the motion-heavy rices (Caelestia, end-4) do.

## Principles

1. **Motion explains change.** A panel slides *from* the button that opened it; a notification enters from the edge it lives on. Motion shows where things come from and go to.
2. **Fast in, slow settle.** Use decelerating curves (`OutCubic`, M3 emphasized) for things entering, accelerating curves (`InCubic`) for things leaving.
3. **Leaving is faster than entering.** Open in 350 ms, close in 200 ms. People wait for things to appear but not for them to disappear.
4. **Small things move fast, big things move slower.** 150 ms for a hover, 250 ms for a chip resizing, 400 ms+ for a full panel.
5. **Consistency beats cleverness.** The same few durations and curves everywhere ([[ch:43-design-system]]).
6. **Don't animate what the user is directly dragging.** Disable Behaviors while a slider is pressed so the fill sticks to the finger.

## Duration and curve table

| Interaction | Duration | Curve |
|---|---|---|
| Hover color, opacity | 120–150 ms | linear or standard |
| Press scale | 100 ms | standard |
| Toggle / switch knob | 200 ms | emphasized |
| Chip expand, workspace pill | 250–300 ms | emphasized or OutBack (playful) |
| Popup open | 250–300 ms | emphasized decelerate |
| Popup close | 150–200 ms | emphasized accelerate |
| Side panel slide in | 350–450 ms | emphasized decelerate |
| Fullscreen overlay fade | 200–250 ms | standard |
| Theme crossfade | 500–700 ms | standard |

## Techniques

### 1. Sliding indicator (workspaces, tabs)
One indicator that moves between items is far smoother than recoloring each item:

```qml
Item {
    id: tabs
    property int current: 0
    Row { id: row; spacing: 8
        Repeater { model: 5; Rectangle { required property int index; width: 40; height: 28; color: "transparent"
            TapHandler { onTapped: tabs.current = parent.index } } } }
    Rectangle {
        readonly property Item target: row.children[tabs.current] ?? null
        x: target?.x ?? 0
        width: target?.width ?? 0
        height: 28; radius: 14; color: Colors.primary; z: -1
        Behavior on x { Anim {} }
        Behavior on width { Anim {} }
    }
}
```

**Stretchy indicator** (end-4 style): animate the left and right edges separately, with the leading edge fast and the trailing edge slower, so the pill stretches while moving:

```qml
Rectangle {
    property real targetLeft: target.x
    property real targetRight: target.x + target.width
    property real left: targetLeft
    property real right: targetRight
    Behavior on left  { NumberAnimation { duration: movingRight ? 400 : 200; easing.type: Easing.OutCubic } }
    Behavior on right { NumberAnimation { duration: movingRight ? 200 : 400; easing.type: Easing.OutCubic } }
    property bool movingRight: false
    onTargetLeftChanged: movingRight = targetLeft > left
    x: left; width: right - left
}
```

### 2. Shape morphing
Animating `radius` changes the *shape*: circle to rounded square when toggled. M3 calls this expressive shape:

```qml
radius: toggled ? Appearance.rounding.normal : height / 2
Behavior on radius { Anim {} }
```

### 3. Grow from the source
Scale a popup up from where it was triggered by setting `transformOrigin` toward the trigger:

```qml
Rectangle {
    transformOrigin: Item.Top
    scale: open ? 1 : 0.9
    opacity: open ? 1 : 0
    Behavior on scale { Anim {} }
    Behavior on opacity { Anim { duration: Appearance.anim.fast } }
}
```

### 4. Staggered entrances
Delay each item slightly by its index for a cascading reveal:

```qml
Repeater {
    model: toggles
    QuickToggle {
        required property int index
        opacity: 0; y: 10
        Component.onCompleted: appear.start()
        SequentialAnimation {
            id: appear
            PauseAnimation { duration: index * 30 }
            ParallelAnimation {
                NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 200 }
                NumberAnimation { target: parent; property: "y"; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }
}
```

### 5. Content fades after the container grows
When a card expands, fade its new content in *after* most of the size change, and fade it out *first* when collapsing (see [[ch:24-animation-advanced]]).

### 6. Number tickers
Animate numbers (volume %, battery %) instead of jumping:

```qml
property real shownVolume: Audio.volume
Behavior on shownVolume { NumberAnimation { duration: 200 } }
Text { text: Math.round(shownVolume * 100) + "%" }
```

### 7. Elastic edges and overshoot
`Easing.OutBack` with a small overshoot (1.2–1.5) gives pills and buttons a lively "land". Use it on small elements only.

### 8. Window open/close with layer shell
The compositor can animate layer surfaces (Hyprland's `layerrule = animation slide top, …`). It's often better to animate in QML yourself for full control, and disable the compositor's animation with `layerrule = noanim, quickshell:osd`.

## Respecting performance

- Prefer `x`, `y`, `scale`, `opacity` over `width`/`height` for big items.
- Stop infinite animations when hidden.
- Avoid animating MultiEffect blur radius on large areas every frame.

## Respecting users

Offer a "reduce motion" option:

```qml
// Appearance.qml
readonly property real motionScale: Config.appearance.reduceMotion ? 0 : 1
readonly property QtObject anim: QtObject {
    readonly property int normal: 250 * root.motionScale
}
```

Durations of 0 make every Behavior instant.

## Practice

::: exercise warm | Sliding tab indicator
Build a 5-tab bar with an indicator that slides to the selected tab.
--- solution
```qml
Item { width: 400; height: 36; property int current: 0
    Rectangle { width: 80; height: 3; y: 33; color: "#cba6f7"; x: parent.current * 80
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
    Row { Repeater { model: 5
        Text { required property int index; width: 80; height: 33; horizontalAlignment: Text.AlignHCenter
               verticalAlignment: Text.AlignVCenter; text: "Tab " + (index + 1); color: "white"
               TapHandler { onTapped: parent.parent.parent.current = parent.index } } } } }
```
:::

::: exercise practice | Stretchy indicator
Make the indicator stretch while moving: the leading edge moves fast, the trailing edge slower.
--- hint
Animate `left` and `right` edges separately with different durations instead of animating `x`.
:::

::: exercise practice | Shape morph
Make an IconButton whose corner radius morphs from round to a rounded square when toggled.
--- solution
```qml
radius: toggled ? 10 : height / 2
Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
```
:::

::: exercise challenge | Asymmetric popup
Make a popup that scales from 0.9 to 1 from the top, opening in 300 ms and closing in 180 ms.
--- solution
```qml
Rectangle { transformOrigin: Item.Top; scale: open ? 1 : 0.9; opacity: open ? 1 : 0
    Behavior on scale { NumberAnimation { duration: open ? 300 : 180; easing.type: open ? Easing.OutCubic : Easing.InCubic } }
    Behavior on opacity { NumberAnimation { duration: open ? 300 : 180 } } }
```
:::
