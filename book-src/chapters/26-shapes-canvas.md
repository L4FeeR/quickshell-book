# Shapes and Canvas

Rectangles can't do everything. Inverted "screen corners", panels that curve smoothly into the bar, circular progress rings, wavy separators, sparkline graphs: these need **Shape** (GPU vector paths) or **Canvas** (a JavaScript 2D drawing API).

## Shape basics

`import QtQuick.Shapes`. A `Shape` contains one or more `ShapePath`s. Each path starts at `startX/startY` and is built from path elements.

```qml
import QtQuick
import QtQuick.Shapes

Shape {
    width: 200; height: 100
    preferredRendererType: Shape.CurveRenderer     // smooth anti-aliased curves (Qt 6.6+)

    ShapePath {
        fillColor: "#cba6f7"
        strokeColor: "#1e1e2e"
        strokeWidth: 2                             // -1 = no stroke
        startX: 0; startY: 100
        PathLine { x: 100; y: 0 }                  // straight line to (100, 0)
        PathLine { x: 200; y: 100 }
        PathLine { x: 0; y: 100 }                  // back to start: a triangle
    }
}
```

### Path elements

| Element | Draws | Key properties |
|---|---|---|
| `PathLine` | straight line | `x`, `y` (or `relativeX/Y`) |
| `PathArc` | circular/elliptical arc | `x`, `y`, `radiusX`, `radiusY`, `direction` (`PathArc.Clockwise`/`Counterclockwise`), `useLargeArc` |
| `PathAngleArc` | arc by center and angles (rings!) | `centerX`, `centerY`, `radiusX`, `radiusY`, `startAngle`, `sweepAngle`, `moveToStart` |
| `PathQuad` | quadratic curve | `x`, `y`, `controlX`, `controlY` |
| `PathCubic` | cubic Bézier | `x`, `y`, `control1X/Y`, `control2X/Y` |
| `PathMove` | jump without drawing | `x`, `y` |
| `PathSvg` | SVG path data | `path: "M 0 0 L 10 10 …"` |
| `PathRectangle` (6.8+) | rectangle with radius | `x y width height radius` |

### ShapePath properties

| Property | Meaning |
|---|---|
| `fillColor` | inside color (`"transparent"` for outline only) |
| `fillGradient` | `LinearGradient`, `RadialGradient`, `ConicalGradient` |
| `strokeColor`, `strokeWidth` | outline |
| `strokeStyle`, `dashPattern` | `ShapePath.SolidLine` / `DashLine` |
| `capStyle` | `ShapePath.FlatCap`, `SquareCap`, `RoundCap` |
| `joinStyle` | `MiterJoin`, `BevelJoin`, `RoundJoin` |
| `fillRule` | `ShapePath.OddEvenFill` / `WindingFill` |

## Recipe: inverted corner (screen corners)

The black rounded corners many rices draw at the screen corners, or where a panel meets the bar, are squares with a quarter circle *removed*:

```qml
Shape {
    id: corner
    property int r: 20
    property color c: "#000000"
    width: r; height: r
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        fillColor: corner.c
        strokeWidth: -1
        startX: 0; startY: 0
        PathLine { x: corner.r; y: 0 }                                     // along the top
        PathArc  { x: 0; y: corner.r; radiusX: corner.r; radiusY: corner.r
                   direction: PathArc.Counterclockwise }                    // curve back to the left edge
        PathLine { x: 0; y: 0 }
    }
}
```

Rotate it 90°, 180° or 270° for the other corners. [[ch:62-proj-desktop]] places four of them in a click-through overlay window.

## Recipe: circular progress ring

```qml
Shape {
    id: ring
    property real value: 0.72          // 0..1
    property real thickness: 5
    property color trackColor: "#313244"
    property color fillColor: "#a6e3a1"
    width: 48; height: 48
    preferredRendererType: Shape.CurveRenderer

    ShapePath {                        // background track
        fillColor: "transparent"
        strokeColor: ring.trackColor
        strokeWidth: ring.thickness
        capStyle: ShapePath.RoundCap
        PathAngleArc {
            centerX: ring.width / 2; centerY: ring.height / 2
            radiusX: ring.width / 2 - ring.thickness; radiusY: radiusX
            startAngle: 0; sweepAngle: 360
        }
    }
    ShapePath {                        // value arc, starting at 12 o'clock
        fillColor: "transparent"
        strokeColor: ring.fillColor
        strokeWidth: ring.thickness
        capStyle: ShapePath.RoundCap
        PathAngleArc {
            centerX: ring.width / 2; centerY: ring.height / 2
            radiusX: ring.width / 2 - ring.thickness; radiusY: radiusX
            startAngle: -90
            sweepAngle: 360 * ring.value
        }
    }
    Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
}
```

Put a percentage `Text` in the middle and you have a CPU, RAM or battery gauge.

## Recipe: a panel that melts into the bar

Caelestia's drawers and end-4's corners connect panels to the bar with concave curves. Draw the panel's outline as a single path: straight sides, convex rounded bottom corners, and concave "flares" at the top where it meets the bar:

```qml
Shape {
    id: drawer
    property real w: 300
    property real h: 200
    property real r: 18                // corner radius
    width: w + 2 * r; height: h
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        fillColor: "#1e1e2e"; strokeWidth: -1
        startX: 0; startY: 0
        // concave flare top-left
        PathArc { x: drawer.r; y: drawer.r; radiusX: drawer.r; radiusY: drawer.r }
        PathLine { x: drawer.r; y: drawer.h - drawer.r }
        // convex bottom-left
        PathArc { x: drawer.r * 2; y: drawer.h; radiusX: drawer.r; radiusY: drawer.r; direction: PathArc.Counterclockwise }
        PathLine { x: drawer.w; y: drawer.h }
        // convex bottom-right
        PathArc { x: drawer.w + drawer.r; y: drawer.h - drawer.r; radiusX: drawer.r; radiusY: drawer.r; direction: PathArc.Counterclockwise }
        PathLine { x: drawer.w + drawer.r; y: drawer.r }
        // concave flare top-right
        PathArc { x: drawer.w + 2 * drawer.r; y: 0; radiusX: drawer.r; radiusY: drawer.r }
        PathLine { x: 0; y: 0 }
    }
    Behavior on h { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
}
```

Animate `h` from 0 to its full height and the panel "grows" out of the bar. [[ch:65-proj-drawers]] builds a full drawer system on this.

## Canvas: draw with JavaScript

`Canvas` gives you an HTML5-style 2D context. It's great for graphs, waveforms and anything data-driven. It's slower than Shape (it rasterizes on the CPU by default), so redraw only when data changes.

```qml
Canvas {
    id: graph
    property var samples: []           // values 0..1
    width: 220; height: 50

    onSamplesChanged: requestPaint()   // redraw only on change
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (samples.length < 2) return
        const step = width / (samples.length - 1)

        // filled area
        ctx.beginPath()
        ctx.moveTo(0, height)
        samples.forEach((v, i) => ctx.lineTo(i * step, height - v * height))
        ctx.lineTo(width, height)
        ctx.closePath()
        const g = ctx.createLinearGradient(0, 0, 0, height)
        g.addColorStop(0, "#80cba6f7"); g.addColorStop(1, "#00cba6f7")
        ctx.fillStyle = g
        ctx.fill()

        // line on top
        ctx.beginPath()
        samples.forEach((v, i) => i ? ctx.lineTo(i * step, height - v * height) : ctx.moveTo(0, height - v * height))
        ctx.strokeStyle = "#cba6f7"; ctx.lineWidth = 2; ctx.lineJoin = "round"
        ctx.stroke()
    }

    Timer {                            // demo data: push a random sample every second
        interval: 1000; running: true; repeat: true
        onTriggered: graph.samples = [...graph.samples.slice(-29), Math.random()]
    }
}
```

Context methods you'll use: `reset`, `clearRect`, `fillRect`, `strokeRect`, `beginPath`, `moveTo`, `lineTo`, `arc`, `quadraticCurveTo`, `bezierCurveTo`, `closePath`, `fill`, `stroke`, `fillText`, `createLinearGradient`, `createRadialGradient`, `save`, `restore`, `translate`, `rotate`, `scale`. Properties: `fillStyle`, `strokeStyle`, `lineWidth`, `lineCap`, `lineJoin`, `font`, `globalAlpha`.

Set `renderTarget: Canvas.FramebufferObject` and `renderStrategy: Canvas.Cooperative` for GPU-backed drawing on supported setups.

## Shape or Canvas?

| | Shape | Canvas |
|---|---|---|
| Rendering | GPU, resolution-independent | CPU bitmap (by default) |
| Animating | animate properties, smooth | must repaint each frame |
| Best for | static or animated geometry: corners, rings, outlines | data-driven drawings: graphs, visualizers |

## Practice

::: exercise warm | One inverted corner
Draw one inverted (concave) corner, 24×24, filled dark: a square minus a quarter circle.
--- solution
```qml
Shape { width: 24; height: 24; preferredRendererType: Shape.CurveRenderer
    ShapePath { fillColor: "#1e1e2e"; strokeColor: "transparent"; startX: 0; startY: 0
        PathLine { x: 24; y: 0 }
        PathArc { x: 0; y: 24; radiusX: 24; radiusY: 24; direction: PathArc.Counterclockwise }
        PathLine { x: 0; y: 0 } } }
```
Rotate copies by 90°, 180° and 270° for the other three corners.
:::

::: exercise practice | Battery ring
Build a ring gauge for `property real level` (0–1) with the percentage in the middle.
--- solution
```qml
Item { width: 80; height: 80
    Shape { anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
        ShapePath { strokeColor: "#313244"; strokeWidth: 8; fillColor: "transparent"
            PathAngleArc { centerX: 40; centerY: 40; radiusX: 34; radiusY: 34; startAngle: 0; sweepAngle: 360 } }
        ShapePath { strokeColor: "#a6e3a1"; strokeWidth: 8; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 40; centerY: 40; radiusX: 34; radiusY: 34; startAngle: -90; sweepAngle: 360 * level } } }
    Text { anchors.centerIn: parent; text: Math.round(level * 100) + "%"; color: "white" } }
```
:::

::: exercise challenge | Canvas graph
Make a `Canvas` line graph of the last 30 random values (0–1), adding one every 500 ms.
--- solution
```qml
Canvas { id: g; width: 200; height: 60
    property var values: []
    Timer { interval: 500; running: true; repeat: true
        onTriggered: { g.values = [...g.values, Math.random()].slice(-30); g.requestPaint() } }
    onPaint: { const c = getContext("2d"); c.reset(); c.strokeStyle = "#89b4fa"; c.lineWidth = 2; c.beginPath()
        values.forEach((v, i) => { const x = i * width / 29, y = height - v * height; i ? c.lineTo(x, y) : c.moveTo(x, y) }); c.stroke() } }
```
After [[ch:37-processes]], feed it real CPU usage instead of `Math.random()`.
:::
