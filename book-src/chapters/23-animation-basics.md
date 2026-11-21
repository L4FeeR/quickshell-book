# Animation I: Behaviors and Easing

Motion is what separates a "config" from a rice that feels alive: the workspace pill that slides, the panel that eases in, the icon that bounces on hover. Qt's animation system runs on the GPU and is easy to use.

## Behavior: animate every change

A `Behavior` says "whenever this property changes, animate to the new value instead of jumping":

```qml
Rectangle {
    width: expanded ? 240 : 40
    color: expanded ? "#cba6f7" : "#45475a"
    property bool expanded: hover.hovered
    HoverHandler { id: hover }

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 200 } }
}
```

No matter *why* `width` changes (hover, a binding, a click), it animates. This is the single most useful animation tool in shells, and you can retrofit motion onto an existing bar by adding Behaviors.

```qml
// typical uses
Behavior on x       { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }   // sliding indicator
Behavior on opacity { NumberAnimation { duration: 150 } }                                 // fade
Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }    // bounce
Behavior on radius  { NumberAnimation { duration: 250 } }                                 // shape morph
Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } // grow with content
```

Disable a Behavior temporarily with `enabled`, e.g. to avoid animating on startup:

```qml
Behavior on x { enabled: root.ready; NumberAnimation { duration: 250 } }
```

## Animation types

| Type | Animates | Notes |
|---|---|---|
| `NumberAnimation` | numbers: x, y, width, opacity, scale, rotation… | the workhorse |
| `ColorAnimation` | colors | interpolates in RGB |
| `RotationAnimation` | rotation | `direction: RotationAnimation.Shortest` avoids spinning the long way |
| `PropertyAnimation` | anything (generic) | |
| `SmoothedAnimation` | follows a moving target smoothly | `velocity` instead of duration |
| `SpringAnimation` | physics spring | `spring`, `damping`, `mass`, `epsilon` |
| `Vector3dAnimation` | 3D vectors | rare |

## Duration and easing

`duration` is in milliseconds. Good defaults: **150 ms** for hover and color, **250 ms** for size and position, **350–500 ms** for panels sliding in.

**Easing** shapes the speed over time. Linear motion looks robotic; real objects accelerate and decelerate.

| Easing | Feel | Use for |
|---|---|---|
| `Easing.OutCubic` | fast start, gentle stop | **the default for UI**: panels, indicators |
| `Easing.OutQuint` / `OutExpo` | very fast start, long glide | snappy, modern |
| `Easing.InOutQuad` / `InOutCubic` | smooth both ends | looping, back-and-forth |
| `Easing.OutBack` | overshoots, then settles | playful bounces, scale-on-hover |
| `Easing.InCubic` | slow start, fast end | things *leaving* the screen |
| `Easing.OutElastic` | springy wobble | use sparingly |
| `Easing.OutBounce` | bounces like a ball | use sparingly |
| `Easing.Linear` | constant speed | spinners, progress |
| `Easing.BezierSpline` | your own curve | design-system curves (below) |

```qml
NumberAnimation {
    duration: 400
    easing.type: Easing.OutBack
    easing.overshoot: 1.6          // how far OutBack overshoots (default 1.70158)
}
```

### Custom curves (Material 3 motion)
Material Design 3 defines named curves as cubic Béziers. Use them with `BezierSpline`, writing the control points followed by the end point `1, 1`:

```qml
NumberAnimation {
    duration: 450
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]     // M3 "emphasized decelerate"
}
```

| M3 curve | bezierCurve |
|---|---|
| Standard | `[0.2, 0, 0, 1, 1, 1]` |
| Standard decelerate | `[0, 0, 0, 1, 1, 1]` |
| Standard accelerate | `[0.3, 0, 1, 1, 1, 1]` |
| Emphasized decelerate | `[0.05, 0.7, 0.1, 1, 1, 1]` |
| Emphasized accelerate | `[0.3, 0, 0.8, 0.15, 1, 1]` |
| Expressive spatial (overshoot) | `[0.38, 1.21, 0.22, 1, 1, 1]` |

> [!WILD] In the wild
> end-4's `Appearance.qml` and Caelestia's appearance config define animation tokens like these (durations plus Bézier curves) once, and every component references them. You'll build the same in [[ch:45-motion]].

Quickshell also has an [[EasingCurve]] helper type for evaluating curves in your own code.

## Standalone animations

Animations can also run on their own, not just as Behaviors.

### "on property" syntax: start immediately or when told
```qml
Rectangle {
    width: 20; height: 20; radius: 10; color: "#f38ba8"
    SequentialAnimation on opacity {          // animates THIS item's opacity
        running: recording                    // bind to state
        loops: Animation.Infinite
        NumberAnimation { to: 0.2; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
    }
}
```

### Animation with an id: start from code
```qml
Text {
    id: icon
    text: "notifications"
    font.family: "Material Symbols Rounded"

    SequentialAnimation {
        id: ring
        RotationAnimation { target: icon; to: 20; duration: 80 }
        RotationAnimation { target: icon; to: -20; duration: 120 }
        RotationAnimation { target: icon; to: 0; duration: 80 }
    }
}
// somewhere: ring.restart()  (e.g. when a notification arrives)
```

### Animation control
| Member | Meaning |
|---|---|
| `running` | Bind or set to start and stop |
| `loops` | Count, or `Animation.Infinite` |
| `paused` | Pause or resume |
| `alwaysRunToEnd` | Finish the cycle even when stopped |
| `start()`, `stop()`, `restart()`, `pause()`, `resume()`, `complete()` | Methods |
| `onStarted`, `onFinished`, `onStopped` | Signals |
| `target` / `targets`, `property` / `properties`, `from`, `to` | What to animate |

## Hover effects cookbook

```qml
// 1. grow on hover
scale: hover.hovered ? 1.08 : 1
Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

// 2. background fades in
color: hover.hovered ? "#45475a" : "transparent"
Behavior on color { ColorAnimation { duration: 120 } }

// 3. pill expands to reveal a label
width: hover.hovered ? icon.width + label.implicitWidth + 24 : icon.width + 16
clip: true
Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

// 4. icon fills in (Material Symbols variable FILL axis, Qt 6.7+)
font.variableAxes: ({ "FILL": hover.hovered ? 1 : 0 })

// 5. press feedback
scale: area.pressed ? 0.92 : 1
```

## Performance

- Animate **`opacity`, `scale`, `x`, `y`, `rotation`**: they're nearly free on the GPU.
- Animating `width`/`height` re-lays out children every frame. It's fine for small items, but be careful with big layouts.
- Infinite animations keep the shell redrawing at 60+ fps. **Bind `running` to visibility** so they stop when hidden.

> [!TRY] Exercises
> 1. Make a workspace indicator: 5 dots, where the active one is a wide pill. Clicking a dot activates it, and the width changes animate with `OutCubic`.
> 2. Make a "recording" dot that pulses only while `property bool recording` is true.
> 3. Make a notification bell icon that wiggles (`SequentialAnimation` of rotations) when you click it.
