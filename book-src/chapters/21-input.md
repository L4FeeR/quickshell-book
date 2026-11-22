# Mouse, Touchpad and Keyboard Input

A rice that only *shows* things is a wallpaper. This chapter covers clicks, hover, scrolling, dragging and keyboard input, and the Quickshell-specific rule about keyboard focus.

## MouseArea: the classic

`MouseArea` is an invisible item that receives mouse events inside its bounds. Usually you fill a parent with it:

```qml
Rectangle {
    id: btn
    width: 120; height: 36; radius: 10
    color: area.pressed ? "#585b70" : area.containsMouse ? "#45475a" : "#313244"

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true                     // REQUIRED for containsMouse / onEntered without pressing
        cursorShape: Qt.PointingHandCursor     // hand cursor on hover
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) console.log("left")
            else if (mouse.button === Qt.RightButton) console.log("right")
            else console.log("middle")
        }
        onDoubleClicked: console.log("double")
        onPressAndHold: console.log("long press")       // after pressAndHoldInterval ms
        onEntered: console.log("mouse in")
        onExited: console.log("mouse out")
        onWheel: wheel => console.log("scroll", wheel.angleDelta.y)
    }
}
```

### MouseArea properties

| Property | Meaning |
|---|---|
| `hoverEnabled` | Track hover without a button pressed |
| `containsMouse` | Pointer is inside (needs `hoverEnabled` unless pressed) |
| `pressed`, `pressedButtons` | Currently held |
| `acceptedButtons` | Which buttons to react to |
| `cursorShape` | `Qt.PointingHandCursor`, `Qt.IBeamCursor`, `Qt.SizeHorCursor`… |
| `mouseX`, `mouseY` | Pointer position inside the area |
| `drag.target`, `drag.axis`, `drag.minimumX`… | Built-in dragging |
| `propagateComposedEvents` | Let clicks pass to areas underneath |
| `preventStealing` | Keep the grab during drags |
| `pressAndHoldInterval` | Long-press time in ms |
| `scrollGestureEnabled` | Accept touchpad scroll gestures |

### The event objects
- `MouseEvent` (clicked, pressed…): `button`, `buttons`, `modifiers`, `x`, `y`, `wasHeld`, `accepted`
- `WheelEvent` (wheel): `angleDelta.x/.y` (mouse wheel, 120 per notch), `pixelDelta` (touchpads), `modifiers`, `inverted`

### Scrolling to change a value (mouse and touchpad)
A wheel notch is `angleDelta.y = ±120`, while touchpads send many small values. Normalize:

```qml
MouseArea {
    anchors.fill: parent
    property real acc: 0
    onWheel: w => {
        acc += w.angleDelta.y
        while (Math.abs(acc) >= 120) {                 // one "step" per notch-equivalent
            Audio.setVolume(Audio.volume + (acc > 0 ? 0.05 : -0.05))
            acc -= 120 * Math.sign(acc)
        }
    }
}
```

## Pointer handlers: the modern way

Handlers are lighter than MouseArea and **combine**: several handlers on one item don't block each other.

```qml
Rectangle {
    width: 100; height: 40; radius: 8
    color: hover.hovered ? "#45475a" : "#313244"

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: console.log("left tap") }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: console.log("right tap") }
    TapHandler { onDoubleTapped: console.log("double"); onLongPressed: console.log("hold") }
    WheelHandler { onWheel: e => console.log(e.angleDelta.y) }
    DragHandler { target: parent }                    // drag the rectangle around
}
```

| Handler | Key properties / signals |
|---|---|
| `HoverHandler` | `hovered`, `point.position`, `cursorShape`, `acceptedDevices` |
| `TapHandler` | `onTapped(eventPoint, button)`, `onDoubleTapped`, `onLongPressed`, `pressed`, `acceptedButtons`, `gesturePolicy` |
| `WheelHandler` | `onWheel(event)`, `property`/`target` to auto-adjust a property, `rotationScale` |
| `DragHandler` | `target`, `xAxis.minimum/maximum`, `active`, `translation` |
| `PinchHandler` | touchpad/touch pinch zoom and rotate |
| `PointHandler` | low-level pointer tracking |

> [!TIP] Which to use?
> Use `HoverHandler` for hover effects (it never steals clicks), `TapHandler` for clicks, `WheelHandler` for scroll. Fall back to `MouseArea` when you need `containsMouse` and `pressed` together, propagation control, or the built-in `drag`.

## Drag and drop

```qml
Rectangle {
    id: card
    width: 80; height: 50; color: "#cba6f7"
    Drag.active: dragArea.drag.active
    Drag.hotSpot: Qt.point(width / 2, height / 2)
    Drag.keys: ["window"]
    property string payload: "0x55d1a2"
    MouseArea { id: dragArea; anchors.fill: parent; drag.target: parent
                onReleased: parent.Drag.drop() }
}

DropArea {
    width: 200; height: 120
    keys: ["window"]
    Rectangle { anchors.fill: parent; color: parent.containsDrag ? "#45475a" : "#313244" }
    onDropped: drop => console.log("dropped", drop.source.payload)
}
```

You'll use this to move windows between workspaces in the overview ([[ch:58-proj-overview]]).

## Keyboard input

Keys go to the item with **active focus**:

```qml
Item {
    focus: true                                     // ask for focus within this window
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) close()
        else if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) up()
        else return
        event.accepted = true                       // stop propagation
    }
    Keys.onReturnPressed: launch()
    Keys.onUpPressed: list.decrementCurrentIndex()
    Keys.onDownPressed: list.incrementCurrentIndex()
    Keys.onTabPressed: next()
}
```

Common keys: `Qt.Key_Escape`, `Key_Return`, `Key_Enter`, `Key_Tab`, `Key_Backtab`, `Key_Up/Down/Left/Right`, `Key_Backspace`, `Key_Delete`, `Key_Home`, `Key_End`, `Key_PageUp/PageDown`, `Key_Space`, `Key_A`…`Key_Z`, `Key_0`…`Key_9`, `Key_F1`… Modifiers: `Qt.ShiftModifier`, `ControlModifier`, `AltModifier`, `MetaModifier` (Super).

`event.text` gives the typed character, useful for "press the first letter" shortcuts.

### Focus
- `focus: true` requests focus **within its focus scope**; `activeFocus` is true when it actually has it.
- `forceActiveFocus()` grabs focus immediately (call it when a popup opens).
- `FocusScope` groups items so a component can manage focus internally.
- `KeyNavigation.tab: otherItem` / `KeyNavigation.down` define arrow and tab order.

## Text input

```qml
import QtQuick
import QtQuick.Controls

TextField {                           // styled, from Controls
    placeholderText: "Search…"
    onTextChanged: search(text)
    onAccepted: launch()              // Enter pressed
}

TextInput {                           // bare, unstyled (style it yourself)
    width: 300
    color: "white"
    font.pixelSize: 16
    focus: true
    echoMode: TextInput.Password      // Normal, Password, NoEcho, PasswordEchoOnEdit
    passwordCharacter: "●"
    selectByMouse: true
    validator: IntValidator { bottom: 0; top: 100 }   // only numbers 0–100
    Keys.onEscapePressed: text = ""
}
```

For multi-line input use `TextArea` (Controls) or `TextEdit`.

## Quickshell rule: windows need keyboard focus

This catches everyone once. **A layer-shell window doesn't receive keyboard input unless it asks for it.** Even with `focus: true` on a TextInput, typing goes to the app behind it until you set:

```qml
import Quickshell.Wayland

PanelWindow {
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive   // grab all keys while open (launchers, lock-like UIs)
    // or WlrKeyboardFocus.OnDemand: focus when clicked (search box in a sidebar)
    // default WlrKeyboardFocus.None: never takes keys (bars)
    TextInput { focus: true }
}
```

[[PanelWindow]] also has a simpler `focusable` property, and [[WlrLayershell]] documents the exact behavior of each mode.

> [!WARN] Don't leave Exclusive on
> A window with `Exclusive` keyboard focus blocks typing into every other app. Only use it while the window is visible and open (launchers, power menus), and make sure <kbd>Esc</kbd> closes it.

## Closing popups by clicking outside

Clicks outside your window go to other apps, so your window never sees them. Options:

- On Hyprland: [[HyprlandFocusGrab]] tells you when the user clicks outside a set of windows.
- Anywhere: a fullscreen transparent [[PanelWindow]] behind the popup that closes it on click.

## Practice

::: exercise warm | Handlers-only button
Make a button with hover, press and right-click behavior using handlers only (no `MouseArea`).
--- solution
```qml
Rectangle { width: 90; height: 32; radius: 8
    color: tap.pressed ? "#585b70" : hov.hovered ? "#45475a" : "#313244"
    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: console.log("left") }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: console.log("right") } }
```
:::

::: exercise practice | Scroll to change
Make a bar you can scroll to change a value, normalized so touchpads don't jump.
--- solution
```qml
WheelHandler {
    onWheel: e => level = Math.max(0, Math.min(1, level + e.angleDelta.y / 120 * 0.05))
}
```
Mouse wheels send steps of 120; touchpads send many small values. Dividing by 120 makes both feel the same.
:::

::: exercise challenge | Key viewer
Make a fullscreen overlay with `Exclusive` keyboard focus that shows the name of every key you press and closes on <kbd>Esc</kbd>.
--- solution
```qml
PanelWindow {
    id: w
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#cc000000"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    Text { id: shown; anchors.centerIn: parent; color: "white"; font.pixelSize: 48
        focus: true
        Keys.onPressed: e => { if (e.key === Qt.Key_Escape) w.visible = false; else shown.text = e.text || ("key " + e.key) } }
}
```
:::
