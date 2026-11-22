# Signals, Handlers and Connections

Bindings describe *what things are*. **Signals** describe *what happens*: a click, a timer firing, a command finishing, a notification arriving. This chapter covers how to react to them.

## Signals and handlers

A **signal** is an event an object announces. You react by writing a **handler**: `on` + the signal name with a capital first letter.

```qml
MouseArea {
    anchors.fill: parent
    onClicked: console.log("clicked!")       // signal: clicked → handler: onClicked
    onDoubleClicked: console.log("double!")
    onPressAndHold: console.log("long press")
}
```

```qml
Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: console.log("tick")         // signal: triggered
}
```

Every type documents its signals. In this book's API reference each signal is listed with its handler name, e.g. [[Process]] has `started` → `onStarted` and `exited(exitCode, exitStatus)` → `onExited`.

## Signal arguments

Many signals carry data. Receive it by writing the handler as an **arrow function** (recommended) or a function:

```qml
MouseArea {
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {                          // arrow function with a parameter
        if (mouse.button === Qt.RightButton) console.log("right click at", mouse.x, mouse.y)
    }
}

Process {
    command: ["ls"]
    onExited: (code, status) => console.log("ls finished with code", code)   // two arguments
}
```

You can name the parameters whatever you like; their position is what matters.

> [!NOTE] Old style
> Older code accesses arguments by their declared names without listing them, like `onClicked: console.log(mouse.x)`. This is deprecated in Qt 6 and prints a warning. Always use the arrow form.

## Property change signals

**Every property automatically has a change signal** named `<property>Changed`, so you can react to any value changing:

```qml
Rectangle {
    property int volume: 50
    onVolumeChanged: console.log("volume is now", volume)
    onWidthChanged: console.log("resized to", width)
    onVisibleChanged: if (visible) console.log("shown!")
}
```

This is how an OSD knows to pop up when the volume changes, no matter what changed it:

```qml
Connections {
    target: Pipewire.defaultAudioSink?.audio ?? null
    function onVolumeChanged() { osd.show() }
}
```

## Declaring your own signals

```qml file="IconButton.qml"
import QtQuick

Rectangle {
    id: root
    signal clicked()                           // no arguments
    signal scrolled(int direction)             // one typed argument
    signal picked(string name, int index)      // several

    width: 32; height: 32; radius: 16
    color: "#45475a"
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()                             // emit by calling it like a function
        onWheel: w => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
```

Users of the component handle them like built-in signals:

```qml
IconButton {
    onClicked: console.log("button clicked")
    onScrolled: dir => volume += dir * 5
}
```

## Component.onCompleted and onDestruction

Every object has the attached `Component` signals:

```qml
Item {
    Component.onCompleted: console.log("I was created and all my properties are set")
    Component.onDestruction: console.log("I'm about to be destroyed")
}
```

`onCompleted` is the place for one-time setup. Don't overuse it for things a binding could express.

## Connections: handling another object's signals

A handler like `onClicked` must live inside the object that emits the signal. To react to signals of an object somewhere else, especially singletons and services, use **Connections**:

```qml
import Quickshell.Hyprland

Connections {
    target: Hyprland                           // whose signals
    function onRawEvent(event) {               // function form: on + SignalName
        console.log("hyprland event:", event.name, event.data)
    }
}
```

Connections properties:

| Property | Meaning |
|---|---|
| `target` | The object to listen to. Can be a binding, so it switches automatically when the target changes. |
| `enabled` | Set `false` to temporarily stop listening. |
| `ignoreUnknownSignals` | Don't warn if the target doesn't have one of the handlers. |

```qml
Connections {
    target: Media.active            // follows whichever player is active
    enabled: target !== null
    function onTrackChanged() { coverAnim.restart() }
}
```

## Connecting in JavaScript

You can also connect signals to functions in code. This is rarely needed, but useful for one-off listeners:

```qml
Component.onCompleted: {
    button.clicked.connect(onButton)          // connect
    // button.clicked.disconnect(onButton)    // disconnect later
}
function onButton() { console.log("connected handler ran") }
```

## Signals vs bindings: which to use?

| Situation | Use |
|---|---|
| "X should always equal / depend on Y" | **binding** |
| "When X happens, do something once" (click, finish, arrive) | **signal handler** |
| "When X changes, start an animation / show a popup / run a command" | **change handler** (`onXChanged`) or **Connections** |
| "Many files need to know" | a **singleton** property they all bind to |

> [!TIP] Avoid "handler soup"
> A beginner often writes `onVolumeChanged: label.text = volume + "%"`. That's a binding written the hard way. If a handler only assigns a value derived from other properties, replace it with a binding.

## Complete example

```qml file="~/.config/quickshell/playground/shell.qml"
import Quickshell
import QtQuick

PanelWindow {
    id: win
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "#11111b"

    property int clicks: 0
    signal milestone(int value)

    onClicksChanged: if (clicks % 5 === 0) milestone(clicks)    // emit our own signal
    onMilestone: value => flash.restart()                        // handle it

    Rectangle {
        id: button
        anchors.centerIn: parent
        width: 160; height: 28; radius: 14
        color: area.pressed ? "#585b70" : area.containsMouse ? "#45475a" : "#313244"

        Text { anchors.centerIn: parent; color: "#cdd6f4"; text: "clicked " + win.clicks + "×" }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => win.clicks += (m.button === Qt.RightButton ? -1 : 1)
        }

        SequentialAnimation on scale {         // plays when we call flash.restart()
            id: flash
            running: false
            NumberAnimation { to: 1.25; duration: 120 }
            NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.OutBack }
        }
    }
}
```

## Practice

::: exercise warm | Log a signal
Log "hovered!" every time the mouse enters a rectangle, using a `HoverHandler` and its `hoveredChanged` signal.
--- solution
```qml
HoverHandler { onHoveredChanged: if (hovered) console.log("hovered!") }
```
:::

::: exercise practice | Reset after a pause
Count clicks, but reset `clicks` to 0 if you don't click for 3 seconds.
--- hint
`restart()` a `Timer` in `onClicked`.
--- solution
```qml
property int clicks: 0
Timer { id: idle; interval: 3000; onTriggered: clicks = 0 }
MouseArea { anchors.fill: parent; onClicked: { clicks++; idle.restart() } }
```
:::

::: exercise practice | Your own signal
Create `Toggle.qml` with `property bool checked` and `signal toggled(bool checked)`, and use it in the bar to log the new state.
--- solution
```qml
// Toggle.qml
import QtQuick
Rectangle {
    id: t
    property bool checked: false
    signal toggled(bool checked)
    width: 40; height: 22; radius: 11
    color: checked ? "#a6e3a1" : "#45475a"
    MouseArea { anchors.fill: parent; onClicked: { t.checked = !t.checked; t.toggled(t.checked) } }
}
```
```qml
Toggle { onToggled: checked => console.log("now", checked) }
```
:::

::: exercise challenge | Connections
Use `Connections` to log every time the window's `width` changes (target: the window's id).
--- solution
```qml
Connections {
    target: win
    function onWidthChanged() { console.log("width is now", win.width) }
}
```
:::
