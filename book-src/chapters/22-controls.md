# Qt Quick Controls and Restyling Them

`import QtQuick.Controls` gives you ready-made widgets: sliders, switches, buttons, text fields, scroll bars, combo boxes, tooltips. Out of the box they look generic, and rices restyle them completely. This chapter shows how.

## Choosing a style

Controls have several built-in styles (Basic, Fusion, Material, Universal, Imagine). For heavy restyling, use **Basic**: it's the simplest to override and doesn't fight you.

```qml file="shell.qml"
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import Quickshell
```

The pragma sets the environment variable before Quickshell starts ([[ch:29-shell-structure]]).

## The anatomy of a control

Every control is made of replaceable parts:

| Part | What it is |
|---|---|
| `background` | Item drawn behind everything (the track, the box) |
| `contentItem` | The main visual (text of a button, track fill…) |
| `handle` / `indicator` | The knob of a slider, the dot of a switch, the box of a checkbox |
| `padding`, `leftPadding`… | Space between background and content |
| `implicitWidth/Height` | Natural size |

Override any part by assigning your own item.

## Slider

```qml
import QtQuick
import QtQuick.Controls

Slider {
    id: s
    from: 0; to: 1; value: 0.4
    stepSize: 0.01
    live: true                          // update `value` while dragging
    implicitWidth: 220; implicitHeight: 24

    onMoved: console.log("user moved to", value)    // only user interaction
    // onValueChanged fires on ANY change, including bindings

    background: Rectangle {
        x: s.leftPadding
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: s.availableWidth; height: 6; radius: 3
        color: "#45475a"
        Rectangle {                                         // filled part
            width: s.visualPosition * parent.width
            height: parent.height; radius: 3
            color: "#cba6f7"
        }
    }
    handle: Rectangle {
        x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
        y: s.topPadding + s.availableHeight / 2 - height / 2
        width: 18; height: 18; radius: 9
        color: s.pressed ? "#f5e0dc" : "#cdd6f4"
        scale: s.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: 100 } }
    }
}
```

Useful Slider members: `value`, `from`, `to`, `stepSize`, `visualPosition` (0–1), `position`, `pressed`, `orientation`, `snapMode`, `live`, `moved()`, `increase()`, `decrease()`.

> [!TIP] Binding a slider to system state
> `value: Audio.volume` plus `onMoved: Audio.setVolume(value)`. Dragging calls your setter; external changes update the slider through the binding. Because the user-driven change only happens in `onMoved`, the binding on `value` survives.

### A thick M3-style slider
```qml
Slider {
    id: big
    from: 0; to: 1; value: 0.6
    implicitHeight: 40
    background: Rectangle {
        anchors.fill: parent; radius: 20; color: "#313244"
        Rectangle { width: Math.max(height, big.visualPosition * parent.width); height: parent.height
                    radius: 20; color: "#cba6f7" }
    }
    handle: Item {}                                  // no knob at all
}
```

## Switch

```qml
Switch {
    id: sw
    checked: Bluetooth.defaultAdapter?.enabled ?? false
    onToggled: Bluetooth.defaultAdapter.enabled = checked
    indicator: Rectangle {
        implicitWidth: 46; implicitHeight: 26
        x: sw.leftPadding; y: parent.height / 2 - height / 2
        radius: 13
        color: sw.checked ? "#cba6f7" : "#45475a"
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            x: sw.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 20; height: 20; radius: 10
            color: sw.checked ? "#1e1e2e" : "#cdd6f4"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }
    contentItem: Item {}                            // no label
}
```

`checked`, `toggled()` (user), `checkedChanged` (any), `toggle()`.

## Button

```qml
Button {
    id: b
    text: "Apply"
    onClicked: apply()
    background: Rectangle {
        implicitWidth: 100; implicitHeight: 36; radius: 18
        color: b.down ? "#b4befe" : b.hovered ? "#cba6f7" : "#89b4fa"
    }
    contentItem: Text { text: b.text; color: "#1e1e2e"; font.bold: true
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
}
```

`down`, `hovered`, `pressed`, `checkable`, `checked`, `icon.name`, `icon.source`, `flat`, `clicked()`, `pressAndHold()`, `doubleClicked()`.

In shells most "buttons" are just a `Rectangle` + `MouseArea` or handlers, which is lighter and fully custom. Use `Button` when you want built-in keyboard activation and accessibility.

## TextField

```qml
TextField {
    id: tf
    placeholderText: "Search apps…"
    placeholderTextColor: "#6c7086"
    color: "#cdd6f4"
    font.pixelSize: 15
    leftPadding: 40
    background: Rectangle { implicitHeight: 44; radius: 22; color: "#313244"
                            border.width: tf.activeFocus ? 2 : 0; border.color: "#cba6f7" }
    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "search"
           font.family: "Material Symbols Rounded"; color: "#a6adc8" }
    onAccepted: console.log("enter:", text)
}
```

## Other controls you'll use

| Control | Use in shells | Key members |
|---|---|---|
| `CheckBox` | settings lists | `checked`, `checkState`, `tristate` |
| `RadioButton` + `ButtonGroup` | pick one of N | `checked`, `ButtonGroup.group` |
| `ComboBox` | dropdown (audio device picker) | `model`, `currentIndex`, `currentText`, `textRole`, `activated(index)` |
| `SpinBox` | numeric settings | `value`, `from`, `to`, `stepSize` |
| `ProgressBar` | download / progress | `value`, `from`, `to`, `indeterminate` |
| `BusyIndicator` | loading spinner | `running` |
| `ScrollView` | scrollable content | `contentWidth`, `ScrollBar.vertical.policy` |
| `ScrollBar` | attach to Flickable/ListView | `ScrollBar.vertical: ScrollBar { }` |
| `ToolTip` | hover hints | `ToolTip.visible`, `ToolTip.text`, `ToolTip.delay` |
| `TabBar` + `TabButton` | sidebar tabs | `currentIndex` |
| `StackView` | navigation stack (settings pages) | `push()`, `pop()`, `initialItem` |
| `SwipeView` + `PageIndicator` | swipeable pages | `currentIndex` |
| `Popup` / `Menu` | in-window popups | `open()`, `close()`, `modal` |
| `Dial`, `RangeSlider` | creative widgets | `value`, `first.value`/`second.value` |

> [!WARN] Controls' Popup/Menu vs Quickshell PopupWindow
> A Controls `Popup` or `Menu` lives **inside** its window and is clipped by the window's edges. In a 36 px bar, a Controls menu would be cut off! For anything that extends beyond the bar, use Quickshell's [[PopupWindow]] or [[QsMenuAnchor]], which create a real separate surface ([[ch:32-popups-menus]]).

## Make your own styled controls once

Write `StyledSlider.qml`, `StyledSwitch.qml`, `StyledTextField.qml` in `widgets/`, reading colors from your theme singleton, then use them everywhere. That's exactly what end-4 (`modules/common/widgets/`) and Caelestia (`components/`) do. [[ch:43-design-system]] builds this library.

## Practice

::: exercise warm | Restyled slider
Build a restyled `Slider` bound to `property real level`, with `Math.round(level*100)%` next to it.
--- solution
```qml
Row { spacing: 10
    Slider { id: s; width: 180; value: level; onMoved: level = value
        background: Rectangle { y: (s.height - 6) / 2; width: s.width; height: 6; radius: 3; color: "#313244"
            Rectangle { width: s.visualPosition * parent.width; height: 6; radius: 3; color: "#cba6f7" } }
        handle: Rectangle { x: s.visualPosition * (s.width - 16); y: (s.height - 16) / 2; width: 16; height: 16; radius: 8 } }
    Text { text: Math.round(level * 100) + "%"; color: "white" } }
```
:::

::: exercise practice | Animated switch
Build a restyled `Switch` with an animated knob.
--- solution
```qml
Switch { id: sw
    indicator: Rectangle { width: 44; height: 24; radius: 12; color: sw.checked ? "#a6e3a1" : "#45475a"
        Rectangle { width: 18; height: 18; radius: 9; y: 3; x: sw.checked ? 23 : 3
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } } }
    contentItem: Item {} }
```
:::

::: exercise challenge | Device picker
Build a `ComboBox` listing `["Speakers", "Headphones", "HDMI"]` and print the chosen one.
--- solution
```qml
ComboBox { model: ["Speakers", "Headphones", "HDMI"]; onActivated: i => console.log(model[i]) }
```
Set `//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic` so restyling works predictably.
:::
