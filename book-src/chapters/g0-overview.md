# Widget Gallery: Overview and Test Harness

A catalog of the things people put in rices, each with a **preview**, an **explanation**, **complete code** you can paste, **how it works**, and **ideas to customize it**. Click any card to jump to it.

> [!NOTE] About the previews
> The pictures are illustrations of what the code produces with the default colors (Catppuccin Mocha). Some are animated to show the behavior, like the island expanding or the speed numbers changing. Your result looks the same once your fonts and colors match.

## How to try any widget

Every example is self-contained and uses plain colors, so it runs without the design system from Part V. Create a test config once:

```bash
mkdir -p ~/.config/quickshell/gallery
```

Put the widget's code in a file (e.g. `NetSpeed.qml`) in that folder, and use this harness to show it in a test bar:

```qml file="~/.config/quickshell/gallery/shell.qml"
//@ pragma UseQApplication
import Quickshell
import QtQuick

ShellRoot {
    PanelWindow {
        id: bar
        anchors { top: true; left: true; right: true }
        margins { top: 8; left: 10; right: 10 }
        implicitHeight: 40
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#1e1e2e"
            border.color: "#313244"

            // ↓ put the widget you're testing here
            NetSpeed { anchors.centerIn: parent }
        }
    }
}
```

```bash
qs -c gallery
```

Widgets that are their own window (islands, OSDs, desktop widgets, panels) go straight into `ShellRoot { }` instead of inside the bar. Each section says which kind it is.

> [!TIP] Moving a widget into your real shell
> Copy the file into `modules/bar/` (or wherever it belongs), replace the hard-coded colors with your `Colors.*` tokens and the durations with `Appearance.anim.*` ([[ch:43-design-system]]), and move any `Process`/`FileView` logic into a service singleton ([[ch:33-singletons]]).

## Shared color palette

The examples use these colors. Define them once in your own shell as a `Colors` singleton:

| Name | Hex | Used for |
|---|---|---|
| base | `#1e1e2e` | backgrounds |
| surface | `#313244` | chips, tracks |
| overlay | `#45475a` | hover, borders |
| text | `#cdd6f4` | main text |
| subtext | `#a6adc8` | secondary text |
| mauve | `#cba6f7` | accent |
| blue | `#89b4fa` | info, download |
| green | `#a6e3a1` | good, charging, upload |
| yellow | `#f9e2af` | warning |
| red | `#f38ba8` | error, recording |
| peach | `#fab387` | highlights |

## All widgets

{{GALLERY_INDEX}}
