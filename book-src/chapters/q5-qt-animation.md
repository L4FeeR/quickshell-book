# Qt Reference: Animation Types

## Common animation properties (Animation base)

| Member | Description |
|---|---|
| `running` | start/stop (bindable) |
| `paused` | pause/resume |
| `loops` | count or `Animation.Infinite` |
| `alwaysRunToEnd` | finish the cycle when stopped |
| `start()`, `stop()`, `restart()`, `pause()`, `resume()`, `complete()` | methods |
| `started()`, `stopped()`, `finished()` | signals |

## PropertyAnimation and friends

| Property | Description |
|---|---|
| `target`, `targets` | object(s) to animate |
| `property`, `properties` | property name(s), comma-separated |
| `from`, `to` | values (omit inside Behavior/Transition) |
| `duration` | ms (default 250) |
| `easing.type` | see below |
| `easing.amplitude`, `easing.overshoot`, `easing.period` | curve parameters |
| `easing.bezierCurve` | control points for `Easing.BezierSpline` |
| `exclude` | objects to skip |

Subtypes: `NumberAnimation`, `ColorAnimation`, `RotationAnimation` (`direction: RotationAnimation.Numerical | Clockwise | Counterclockwise | Shortest`), `Vector3dAnimation`.

## Easing types

`Linear`, `InQuad`, `OutQuad`, `InOutQuad`, `OutInQuad`, `InCubic`, `OutCubic`, `InOutCubic`, `InQuart`, `OutQuart`, `InOutQuart`, `InQuint`, `OutQuint`, `InOutQuint`, `InSine`, `OutSine`, `InOutSine`, `InExpo`, `OutExpo`, `InOutExpo`, `InCirc`, `OutCirc`, `InOutCirc`, `InElastic`, `OutElastic`, `InOutElastic`, `InBack`, `OutBack`, `InOutBack`, `InBounce`, `OutBounce`, `InOutBounce`, `BezierSpline`. Each also has `OutIn…` variants.

## Physics-like

| Type | Properties |
|---|---|
| `SmoothedAnimation` | `velocity`, `reversingMode`, `maximumEasingTime` |
| `SpringAnimation` | `spring`, `damping`, `mass`, `epsilon`, `modulus`, `velocity` |

## Grouping and helpers

| Type | Description |
|---|---|
| `SequentialAnimation` | children one after another |
| `ParallelAnimation` | children at the same time |
| `PauseAnimation` | `duration` wait |
| `ScriptAction` | `script: …` or `scriptName` (in transitions) |
| `PropertyAction` | set a property instantly in a sequence |
| `AnchorAnimation` | animate `AnchorChanges` in transitions |
| `ParentAnimation` | animate `ParentChange` |
| `PathAnimation` | move along a `Path` |

## Behavior

`Behavior on <property> { animation }`. Properties: `enabled`, `animation`, `targetValue`, `targetProperty`.

## Animators (render thread)

`OpacityAnimator`, `ScaleAnimator`, `RotationAnimator`, `XAnimator`, `YAnimator`, `UniformAnimator`: same `target`, `from`, `to`, `duration`, `easing`; smooth even when the GUI thread is busy.

## States and transitions

| Type | Members |
|---|---|
| `State` | `name`, `when`, `extend`, `changes` |
| `PropertyChanges` | `target.property: value` (Qt 6 syntax) or `target` + properties; `explicit`, `restoreEntryValues` |
| `AnchorChanges` | `target`, `anchors.left/right/…` |
| `ParentChange` | `target`, `parent`, `x`, `y`, `width`, `height` |
| `StateChangeScript` | `script`, `name` |
| `StateGroup` | states for non-Item objects |
| `Transition` | `from`, `to`, `reversible`, `enabled`, `animations`, `running` |

## View transitions (attached ViewTransition)

`ViewTransition.item`, `index`, `destination`, `targetIndexes`, `targetItems`: use for staggered delays in ListView/positioner transitions.

## Timing

| Type | Members |
|---|---|
| `Timer` | `interval`, `running`, `repeat`, `triggeredOnStart`, `start()`, `stop()`, `restart()`, `triggered()` |
| `FrameAnimation` | `running`, `frameTime`, `smoothFrameTime`, `currentFrame`, `triggered()`: runs code every frame (Qt 6.4+) |
| [[SystemClock]] | Quickshell: clock aligned to seconds/minutes/hours |
| [[ElapsedTimer]] | Quickshell: precise elapsed time |
| [[EasingCurve]] | Quickshell: evaluate easing curves in JS (`valueAt`, `interpolate`) |
