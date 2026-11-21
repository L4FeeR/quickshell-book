# Attached, Grouped and Enum Properties

Three bits of syntax look odd at first: `anchors.fill`, `Layout.fillWidth` and `Text.AlignHCenter`. They're **grouped properties**, **attached properties** and **enums**. Once you can tell them apart, upstream docs and other people's rices become easy to read.

## Grouped properties

Some properties are **groups** of related sub-properties, written with a dot:

```qml
Text {
    font.family: "Inter"
    font.pixelSize: 14
    font.bold: true
    anchors.left: parent.left
    anchors.leftMargin: 10
}
```

Or in **block form**, same meaning:

```qml
Text {
    font { family: "Inter"; pixelSize: 14; bold: true }
    anchors { left: parent.left; leftMargin: 10 }
}
```

Common groups:

| Group | On | Members |
|---|---|---|
| `anchors` | Items | `left right top bottom horizontalCenter verticalCenter baseline fill centerIn margins leftMargin …` |
| `font` | Text, TextInput… | `family pixelSize pointSize bold weight italic letterSpacing capitalization variableAxes …` |
| `border` | Rectangle | `width color pixelAligned` |
| `anchors` | Quickshell PanelWindow | `top bottom left right` (booleans: which screen edges) |
| `margins` | Quickshell PanelWindow | `top bottom left right` |
| `easing` | animations | `type amplitude overshoot period bezierCurve` |
| `layer` | Items | `enabled smooth samples effect …` |

## Attached properties

An **attached property** is set *on* an object but **belongs to another type**. It's written `TypeName.property`:

```qml
RowLayout {
    Rectangle {
        Layout.fillWidth: true          // the RowLayout reads this from its child
        Layout.preferredHeight: 30
    }
}
```

`Rectangle` has no `fillWidth`. The `Layout` type *attaches* that property to every item so the parent layout can ask "how do you want to be sized?".

Attached properties you'll use:

| Attached | Purpose | Example |
|---|---|---|
| `Layout.*` | Size hints inside RowLayout/ColumnLayout/GridLayout | `Layout.fillWidth: true` |
| `Keys.*` | Keyboard handlers | `Keys.onEscapePressed: close()` |
| `Component.*` | Lifecycle signals | `Component.onCompleted: init()` |
| `ListView.*` | Info about a delegate inside a ListView | `ListView.isCurrentItem` |
| `Drag.*` | Make an item draggable data | `Drag.active: dragArea.drag.active` |
| `ToolTip.*` | Quick tooltip on Controls | `ToolTip.text: "Wi-Fi"` |
| **`WlrLayershell.*`** | Layer-shell settings on a Quickshell window | `WlrLayershell.layer: WlrLayer.Overlay` |
| **`QsWindow.*`** | Which window an item is in | `QsWindow.window` |
| **`HyprlandWindow.*`** | Hyprland-specific window settings | `HyprlandWindow.opacity: 0.9` |

Attached **signals** work the same way: `Keys.onPressed: e => …`, `Component.onDestruction: …`.

> [!NOTE] Reading attached values
> You can read attached properties too. Inside a ListView delegate, `ListView.isCurrentItem` tells you if this delegate is selected. Inside any item in a Quickshell window, `QsWindow.window` gives you the window, which is handy for opening popups relative to it.

## Enums

An **enum** is a named set of fixed values, written `TypeName.ValueName`:

```qml
Text {
    horizontalAlignment: Text.AlignHCenter     // enum value defined on Text
    elide: Text.ElideRight
    wrapMode: Text.WordWrap
}
Image { fillMode: Image.PreserveAspectCrop }
NumberAnimation { easing.type: Easing.OutCubic }
MouseArea { cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton }
```

Under the hood an enum value is just a number, but **always use the name**. It's readable and survives version changes.

### Quickshell's enums

Quickshell puts enums on small dedicated types, which have their own pages in the API reference:

```qml
import Quickshell.Services.UPower
import Quickshell.Wayland

visible: bat.state === UPowerDeviceState.Charging
WlrLayershell.layer: WlrLayer.Overlay
WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
exclusionMode: ExclusionMode.Ignore
anchor.edges: Edges.Bottom | Edges.Left      // flags: combine with |
```

Many Quickshell enum types also have a `toString()` function for display:

```qml
Text { text: UPowerDeviceState.toString(bat.state) }   // "Charging"
Text { text: PowerProfile.toString(PowerProfiles.profile) }
```

### Flags: combining enum values

Some enums are **flags** that can be combined with `|` (bitwise OR) and tested with `&`:

```qml
acceptedButtons: Qt.LeftButton | Qt.RightButton
onClicked: m => { if (m.modifiers & Qt.ControlModifier) console.log("ctrl-click") }
anchor.edges: Edges.Top | Edges.Right
```

### Your own enums

Declare enums in your own components (enum and value names start with a capital):

```qml file="Bar.qml"
import QtQuick

Item {
    enum Position { Top, Bottom, Left, Right }
    property int position: Bar.Top          // refer to it through the file's type name
}
```

## Telling them apart

| You see | It's a | Because |
|---|---|---|
| `font.bold: true` | grouped property | lowercase first part, a property of this object |
| `Layout.fillWidth: true` | attached property | **capitalized** first part, and you're *setting* it |
| `Text.AlignHCenter` | enum value | capitalized type + capitalized value, used as a *value* |
| `Keys.onPressed:` | attached signal handler | capitalized type + `on…` |
| `Hyprland.focusedMonitor` | singleton property | capitalized name that is a singleton |

> [!TRY] Exercises
> 1. In a `RowLayout`, make three rectangles where the middle one fills the leftover width (`Layout.fillWidth`) and the others are 40 px wide.
> 2. Set a `Text`'s `elide` to `Text.ElideMiddle` with a narrow width and a long string.
> 3. Make a `MouseArea` that logs "shift+click" only when <kbd>Shift</kbd> is held.
