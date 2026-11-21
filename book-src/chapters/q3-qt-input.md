# Qt Reference: Input Types

## MouseArea

| Property | Type | Description |
|---|---|---|
| `acceptedButtons` | flags | `Qt.LeftButton`, `RightButton`, `MiddleButton`, `BackButton`, `ForwardButton`, `Qt.AllButtons` |
| `hoverEnabled` | bool | hover tracking without a press |
| `containsMouse`, `containsPress` | bool | read-only |
| `pressed`, `pressedButtons` | | read-only |
| `mouseX`, `mouseY` | real | pointer position |
| `cursorShape` | enum | `Qt.ArrowCursor`, `PointingHandCursor`, `IBeamCursor`, `SizeHorCursor`, `SizeVerCursor`, `OpenHandCursor`, `ClosedHandCursor`, `BusyCursor`, `BlankCursor`… |
| `enabled` | bool | |
| `pressAndHoldInterval` | int | ms |
| `propagateComposedEvents` | bool | let clicks fall through |
| `preventStealing` | bool | keep the grab |
| `scrollGestureEnabled` | bool | touchpad scroll gestures |
| `drag.target`, `drag.axis`, `drag.minimumX/maximumX/minimumY/maximumY`, `drag.threshold`, `drag.filterChildren`, `drag.smoothed`, `drag.active` | | built-in dragging |

Signals: `clicked(mouse)`, `doubleClicked(mouse)`, `pressed(mouse)`, `released(mouse)`, `pressAndHold(mouse)`, `positionChanged(mouse)`, `entered()`, `exited()`, `wheel(wheel)`, `canceled()`.

**MouseEvent**: `button`, `buttons`, `modifiers`, `x`, `y`, `wasHeld`, `isClick`, `accepted`.
**WheelEvent**: `angleDelta` (point, 120 per notch), `pixelDelta`, `buttons`, `modifiers`, `inverted`, `x`, `y`, `accepted`.

## Pointer handlers

### HoverHandler
`hovered`, `point` (`position`, `scenePosition`…), `cursorShape`, `acceptedDevices` (`PointerDevice.Mouse | TouchPad | Stylus`), `acceptedModifiers`, `blocking`, `enabled`, `margin`.

### TapHandler
| Member | Description |
|---|---|
| `acceptedButtons` | which buttons |
| `pressed` | read-only |
| `tapCount` | consecutive taps |
| `longPressThreshold` | seconds |
| `gesturePolicy` | `TapHandler.DragThreshold`, `WithinBounds`, `ReleaseWithinBounds`, `DragWithinBounds` |
| `acceptedModifiers` | require modifiers |
| signals | `tapped(eventPoint, button)`, `singleTapped`, `doubleTapped`, `longPressed()`, `canceled` |

### WheelHandler
`orientation`, `property` + `target` (adjust a property automatically), `rotationScale`, `targetScaleMultiplier`, `invertible`, `acceptedDevices`, signal `wheel(event)`.

### DragHandler
`target`, `xAxis.enabled/minimum/maximum`, `yAxis.*`, `active`, `translation`, `persistentTranslation`, `dragThreshold`, `snapMode`, signals `activeChanged`, `translationChanged`.

### PinchHandler, PointHandler
Pinch zoom/rotate (`minimumScale`, `maximumScale`, `rotationAxis`), and raw point tracking.

## Keyboard

### Keys (attached)
| Member | Description |
|---|---|
| `Keys.enabled` | |
| `Keys.priority` | `Keys.BeforeItem` / `AfterItem` |
| `Keys.forwardTo` | list of items to forward keys to |
| `Keys.onPressed(event)`, `onReleased(event)` | any key |
| `Keys.onReturnPressed`, `onEnterPressed`, `onEscapePressed`, `onTabPressed`, `onBacktabPressed`, `onSpacePressed`, `onDeletePressed`, `onBackPressed`, `onUpPressed`, `onDownPressed`, `onLeftPressed`, `onRightPressed`, `onDigit0Pressed`…`onDigit9Pressed`, `onShortcutOverride` | specific keys |

**KeyEvent**: `key` (`Qt.Key_*`), `text`, `modifiers` (`Qt.ShiftModifier`, `ControlModifier`, `AltModifier`, `MetaModifier`, `KeypadModifier`), `isAutoRepeat`, `count`, `nativeScanCode`, `accepted`.

### KeyNavigation (attached)
`KeyNavigation.left/right/up/down/tab/backtab: item`, `KeyNavigation.priority`.

### FocusScope
Groups items so focus is managed locally; `focus: true` inside a scope applies within it.

### Shortcut
`Shortcut { sequence: "Ctrl+K"; onActivated: … }`, works only while the window has keyboard focus. Properties `sequences`, `context` (`Qt.WindowShortcut`, `ApplicationShortcut`), `autoRepeat`, `enabled`.

## Drag and drop

### Drag (attached)
`Drag.active`, `Drag.source`, `Drag.target`, `Drag.hotSpot`, `Drag.keys`, `Drag.mimeData`, `Drag.supportedActions`, `Drag.proposedAction`, `Drag.dragType` (`Drag.Internal`, `Automatic`), methods `start()`, `drop()`, `cancel()`.

### DropArea
`keys`, `containsDrag`, `drag.x/y/source`, signals `entered(drag)`, `exited()`, `positionChanged(drag)`, `dropped(drop)`.

## Validators

| Type | Properties |
|---|---|
| `IntValidator` | `bottom`, `top` |
| `DoubleValidator` | `bottom`, `top`, `decimals`, `notation` |
| `RegularExpressionValidator` | `regularExpression: /^[a-z]+$/` |
