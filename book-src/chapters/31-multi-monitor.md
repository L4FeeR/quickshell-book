# Multiple Monitors with Variants

A single `PanelWindow` appears on one screen. Most people want a bar on **every** monitor, and they want it to appear and disappear as monitors are plugged in. Quickshell's [[Variants]] does exactly that.

## Screens

[[Quickshell.screens]] is the list of connected monitors, each a [[ShellScreen]]:

| ShellScreen property | Example |
|---|---|
| `name` | `"eDP-1"`, `"DP-2"`, `"HDMI-A-1"` |
| `model` | `"DELL U2720Q"` |
| `serialNumber` | |
| `x`, `y` | position in the global layout |
| `width`, `height` | logical size |
| `devicePixelRatio` | scale factor (1.0, 1.25, 1.5, 2.0…) |
| `physicalPixelDensity`, `logicalPixelDensity` | pixels per mm |
| `orientation`, `primaryOrientation` | rotation |

```qml
Component.onCompleted: Quickshell.screens.forEach(s => console.log(s.name, s.width + "x" + s.height, "@" + s.devicePixelRatio))
```

## Variants: one copy per model entry

```qml file="Bar.qml"
import Quickshell
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens          // one entry per monitor

        PanelWindow {                      // the delegate: created once per screen
            required property ShellScreen modelData
            screen: modelData              // put this copy on that screen

            anchors { top: true; left: true; right: true }
            implicitHeight: 32

            Text {
                anchors.centerIn: parent
                text: modelData.name + "  ·  " + modelData.width + "×" + modelData.height
            }
        }
    }
}
```

When you plug in a monitor, `Quickshell.screens` changes and Variants creates a new bar. Unplug it and that bar is destroyed.

### Variants vs Repeater
| | Variants | Repeater |
|---|---|---|
| Creates | any objects, including **windows** | **Items** inside a parent item |
| Lives in | a Scope (non-visual) | an Item |
| Typical model | `Quickshell.screens` | lists of data to draw |

Variants' members: `model`, `delegate`, `instances` (the created objects). The delegate receives `modelData`; declare it as `required property`.

## Only some monitors

```qml
Variants {
    model: Quickshell.screens.filter(s => s.name !== "HDMI-A-1")   // skip the TV
}
```

Better: make it configurable ([[ch:38-files-json]]):

```qml
model: Config.bar.screens.length
       ? Quickshell.screens.filter(s => Config.bar.screens.includes(s.name))
       : Quickshell.screens
```

## Per-monitor differences

Inside the delegate, `modelData` tells you which screen you're on:

```qml
PanelWindow {
    required property ShellScreen modelData
    screen: modelData
    readonly property bool isLaptop: modelData.name.startsWith("eDP")
    implicitHeight: isLaptop ? 30 : 36
    // show the tray only on the main monitor:
    Loader { active: modelData.name === Config.primaryMonitor; sourceComponent: Tray {} }
}
```

## Per-screen compositor data

Each compositor module can map a ShellScreen to its own monitor object:

```qml
import Quickshell.Hyprland
readonly property HyprlandMonitor hyprMon: Hyprland.monitorFor(modelData)
// hyprMon.activeWorkspace, hyprMon.focused, hyprMon.scale …

import Quickshell.I3
readonly property I3Monitor swayMon: I3.monitorFor(modelData)
```

This is how each monitor's bar shows **its own** active workspace.

## A single window on the focused monitor

Launchers, OSDs and notifications usually appear only on the monitor you're using, not on all of them:

```qml
import Quickshell.Hyprland

PanelWindow {
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    // …
}
```

Or keep one window per screen and show only the focused one:

```qml
Variants {
    model: Quickshell.screens
    PanelWindow {
        required property ShellScreen modelData
        screen: modelData
        visible: GlobalStates.launcherOpen && Hyprland.focusedMonitor?.name === modelData.name
    }
}
```

The first approach uses one window (less memory). The second avoids recreating the surface when focus moves.

## HiDPI notes

- Qt works in **logical pixels**: `implicitHeight: 32` is 32 logical px, which is 48 physical px at 1.5× scale.
- For crisp images, set `sourceSize` to the display size × `screen.devicePixelRatio`.
- Fractional scales can blur 1 px lines; stick to whole logical pixels for borders.

## Practice

::: exercise warm | Name and scale
Show each monitor's name and scale factor in its own bar.
--- solution
```qml
Variants { model: Quickshell.screens
    PanelWindow { required property ShellScreen modelData; screen: modelData
        anchors { top: true; left: true; right: true }; implicitHeight: 30
        Text { anchors.centerIn: parent; text: modelData.name + " @" + modelData.devicePixelRatio } } }
```
:::

::: exercise practice | Thinner on the laptop
Make the bar thinner on your laptop's built-in screen (usually named `eDP-1`).
--- solution
```qml
implicitHeight: modelData.name.startsWith("eDP") ? 28 : 38
```
:::

::: exercise challenge | Only on the focused monitor
Show a centered "Hello" overlay only on the focused monitor (Hyprland).
--- solution
```qml
Variants { model: Quickshell.screens
    PanelWindow { required property ShellScreen modelData; screen: modelData
        visible: Hyprland.focusedMonitor?.name === modelData.name
        implicitWidth: 200; implicitHeight: 80; exclusionMode: ExclusionMode.Ignore
        Text { anchors.centerIn: parent; text: "Hello" } } }
```
:::
