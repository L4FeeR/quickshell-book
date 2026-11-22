# Animation Library: Overview and Every Easing Curve

A visual catalog of motion for your rice: **every animation type Qt Quick offers**, **every easing curve**, and dozens of ready-made effects (entrances, hovers, loaders, morphs). Each entry has a live preview, the code, and suggestions for where to use it.

If you haven't read them yet, [[ch:23-animation-basics]] and [[ch:24-animation-advanced]] explain the concepts; this part is the reference and idea book.

## How to try the examples

Every snippet is a self-contained item. Use this harness: it shows the item in a floating window, so you can watch animations without touching your bar.

```qml file="~/.config/quickshell/anim/shell.qml"
import Quickshell
import QtQuick

FloatingWindow {
    title: "anim-test"
    implicitWidth: 520
    implicitHeight: 360
    color: "#1e1e2e"

    // ↓ paste the example here (or put it in Demo.qml and write Demo {})
    Demo { anchors.centerIn: parent }
}
```

```bash
qs -c anim
```

Hyprland users can float it with `windowrule = float, title:^(anim-test)$`.

## The four ways to animate (quick recap)

| Tool | Use when | Example |
|---|---|---|
| `Behavior on prop { … }` | a property should *always* animate when it changes | `Behavior on x { NumberAnimation { duration: 250 } }` |
| `XxxAnimation on prop { … }` | animate one property immediately or in a loop | `NumberAnimation on opacity { from: 0; to: 1 }` |
| An animation with an `id` | start it from code (`restart()`) on an event | `SequentialAnimation { id: shake; … }` → `shake.restart()` |
| `states` + `transitions` | many properties change together between named modes | `State { name: "open"; … }` + `Transition { … }` |

## Choosing durations

| Element | Duration | Curve |
|---|---|---|
| hover color, opacity | 100–150 ms | `OutQuad` / linear |
| press feedback (scale) | 80–120 ms | `OutQuad` |
| small toggles, chips | 200–250 ms | `OutCubic` or M3 Emphasized |
| popups opening | 250–350 ms | `OutCubic`, `OutBack` (playful) |
| popups closing | 150–200 ms | `InCubic` |
| side panels, drawers | 350–450 ms | M3 Emphasized Decelerate |
| theme / wallpaper crossfades | 500–1000 ms | `InOutQuad` |

## Every easing curve

Each card plots the curve (time runs left to right, value bottom to top). The pink dot travels along the curve, and the blue square on the right shows what that easing *feels* like on a single moving value. The dashed line is the target value: curves that cross it overshoot (Back, Elastic) or bounce.

{{EASING_GRID}}

### Tuning parameters

| Property | Affects | Default |
|---|---|---|
| `easing.overshoot` | how far `Back` curves go past the target | 1.70158 |
| `easing.amplitude` | height of `Elastic` and `Bounce` swings | 1.0 |
| `easing.period` | how fast `Elastic` oscillates (smaller = more wobbles) | 0.3 |
| `easing.bezierCurve` | control points for `BezierSpline`: `[x1, y1, x2, y2, 1, 1]` (more segments can follow) | — |

```qml
NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.5 }    // bigger overshoot
NumberAnimation { duration: 900; easing.type: Easing.OutElastic; easing.amplitude: 1.2; easing.period: 0.4 }
```

> [!TIP] Which curve should I use?
> - **Default for UI:** `OutCubic` (or M3 Emphasized Decelerate). Things arrive fast and settle gently.
> - **Leaving the screen:** `InCubic`, so they speed up as they go.
> - **Playful, bouncy rices:** `OutBack` on scale and position, sparingly.
> - **Looping motion (pulse, breathe, float):** `InOutSine`, the most natural back-and-forth.
> - **Avoid** `Elastic` and `Bounce` on big panels; they look great on small icons and badges only.

## Browse all animations

{{ANIM_INDEX}}
