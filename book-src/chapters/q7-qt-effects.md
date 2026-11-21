# Qt Reference: Effects, Shapes, Canvas

## MultiEffect (`import QtQuick.Effects`)

| Group | Property | Range / type |
|---|---|---|
| Source | `source` | Item |
| | `autoPaddingEnabled` | bool (let effects extend beyond the item) |
| | `paddingRect` | rect |
| Color | `brightness` | −1 … 1 |
| | `contrast` | −1 … 1 |
| | `saturation` | −1 … 1 |
| | `colorization` | 0 … 1 |
| | `colorizationColor` | color |
| Blur | `blurEnabled` | bool |
| | `blur` | 0 … 1 |
| | `blurMax` | int px (2–64 typical) |
| | `blurMultiplier` | real |
| Shadow | `shadowEnabled` | bool |
| | `shadowColor` | color |
| | `shadowOpacity` | 0 … 1 |
| | `shadowBlur` | 0 … 1 |
| | `shadowHorizontalOffset`, `shadowVerticalOffset` | px |
| | `shadowScale` | real |
| Mask | `maskEnabled` | bool |
| | `maskSource` | Item (must be layered or a texture) |
| | `maskInverted` | bool |
| | `maskThresholdMin`, `maskThresholdMax` | 0 … 1 |
| | `maskSpreadAtMin`, `maskSpreadAtMax` | 0 … 1 |
| Read-only | `itemRect`, `fragmentShader`, `vertexShader`, `hasProxySource` | |

## RectangularShadow (Qt 6.9+)

A fast, analytic shadow for rounded rectangles: `radius`, `blur`, `spread`, `offset`, `color`, `cached`. Much cheaper than MultiEffect for card shadows if your Qt is new enough.

## Shape (`import QtQuick.Shapes`)

| Member | Description |
|---|---|
| `preferredRendererType` | `Shape.GeometryRenderer`, `Shape.CurveRenderer` (smooth, Qt 6.6+) |
| `rendererType` | read-only |
| `asynchronous` | triangulate on a thread |
| `containsMode` | `Shape.BoundingRectContains` / `FillContains` for hit testing |
| `fillMode` | how the shape scales (Qt 6.7+) |
| `status` | `Shape.Null`, `Ready`, `Processing` |

### ShapePath
`fillColor`, `fillGradient`, `fillRule` (`ShapePath.OddEvenFill`, `WindingFill`), `strokeColor`, `strokeWidth` (−1 = none), `strokeStyle` (`SolidLine`, `DashLine`), `dashPattern`, `dashOffset`, `capStyle` (`FlatCap`, `SquareCap`, `RoundCap`), `joinStyle` (`MiterJoin`, `BevelJoin`, `RoundJoin`), `miterLimit`, `startX`, `startY`, `pathHints`, `scale`.

### Path elements
| Element | Properties |
|---|---|
| `PathLine` | `x`, `y`, `relativeX`, `relativeY` |
| `PathMove` | `x`, `y` |
| `PathArc` | `x`, `y`, `radiusX`, `radiusY`, `useLargeArc`, `direction` (`PathArc.Clockwise`, `Counterclockwise`), `xAxisRotation` |
| `PathAngleArc` | `centerX`, `centerY`, `radiusX`, `radiusY`, `startAngle`, `sweepAngle`, `moveToStart` |
| `PathQuad` | `x`, `y`, `controlX`, `controlY` |
| `PathCubic` | `x`, `y`, `control1X`, `control1Y`, `control2X`, `control2Y` |
| `PathCurve` | Catmull-Rom points |
| `PathSvg` | `path` (SVG path data string) |
| `PathRectangle` (6.8+) | `x`, `y`, `width`, `height`, `radius`, per-corner radii |
| `PathPolyline`, `PathMultiline` | point lists |
| `PathText` | text as a path |

### Gradients for shapes
`LinearGradient { x1; y1; x2; y2; GradientStop {…} }`, `RadialGradient { centerX; centerY; centerRadius; focalX; focalY; focalRadius }`, `ConicalGradient { centerX; centerY; angle }`; `spread: ShapeGradient.PadSpread | RepeatSpread | ReflectSpread`.

## Canvas 2D context (`getContext("2d")`)

| Category | Members |
|---|---|
| State | `save()`, `restore()`, `reset()`, `globalAlpha`, `globalCompositeOperation` |
| Transform | `translate()`, `rotate()`, `scale()`, `transform()`, `setTransform()`, `resetTransform()` |
| Style | `fillStyle`, `strokeStyle`, `lineWidth`, `lineCap`, `lineJoin`, `miterLimit`, `setLineDash()`, `lineDashOffset` |
| Shadow | `shadowColor`, `shadowBlur`, `shadowOffsetX`, `shadowOffsetY` |
| Rects | `clearRect()`, `fillRect()`, `strokeRect()` |
| Paths | `beginPath()`, `closePath()`, `moveTo()`, `lineTo()`, `arc()`, `arcTo()`, `quadraticCurveTo()`, `bezierCurveTo()`, `rect()`, `roundedRect()`, `ellipse()`, `fill()`, `stroke()`, `clip()`, `isPointInPath()` |
| Gradients | `createLinearGradient()`, `createRadialGradient()`, `createConicalGradient()`, `addColorStop()` |
| Text | `font`, `textAlign`, `textBaseline`, `fillText()`, `strokeText()`, `measureText()` |
| Images | `drawImage()`, `createImageData()`, `getImageData()`, `putImageData()` |

## Legacy: Qt5Compat.GraphicalEffects

`DropShadow`, `InnerShadow`, `Glow`, `RectangularGlow`, `FastBlur`, `GaussianBlur`, `MaskedBlur`, `OpacityMask`, `ThresholdMask`, `ColorOverlay`, `Colorize`, `HueSaturation`, `BrightnessContrast`, `Desaturate`, `LevelAdjust`, `LinearGradient`, `RadialGradient`, `ConicalGradient`, `Displace`, `Blend`. Prefer MultiEffect in new code.

## Quickshell visual helpers

[[ClippingRectangle]] (rounded clipping), [[ClippingWrapperRectangle]], [[WrapperRectangle]], [[IconImage]], [[ScreencopyView]], [[BackgroundEffect]] (compositor blur behind).
