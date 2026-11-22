# Project: Desktop Widgets and Screen Corners

Decorations that make a rice feel finished: **rounded screen corners**, a **desktop clock** on the Bottom layer, a **system monitor** widget with rings and a graph, a **weather** card, and **draggable** widgets that remember their position.

## Rounded screen corners

```qml file="modules/decorations/ScreenCorners.qml"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import qs.services

Scope {
    component Corner: Shape {
        id: c
        property int r: Config.appearance.screenRounding ?? 18
        property int rot: 0                  // 0 TL, 90 TR, 180 BR, 270 BL
        width: r; height: r
        rotation: rot
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "black"
            strokeWidth: -1
            startX: 0; startY: 0
            PathLine { x: c.r; y: 0 }
            PathArc { x: 0; y: c.r; radiusX: c.r; radiusY: c.r; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: 0 }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}                                    // never blocks input
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:corners"

            Corner { anchors { top: parent.top; left: parent.left } rot: 0 }
            Corner { anchors { top: parent.top; right: parent.right } rot: 90 }
            Corner { anchors { bottom: parent.bottom; right: parent.right } rot: 180 }
            Corner { anchors { bottom: parent.bottom; left: parent.left } rot: 270 }
        }
    }
}
```

> [!TIP] Corners under the bar
> If the bar is attached to the top edge, draw the top corners *below* the bar (offset by the bar height) and color them like the bar for the "bar melts into the screen" look end-4 uses.

## A desktop widget base with dragging and saved position

```qml file="widgets/DesktopWidget.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.services

PanelWindow {
    id: root
    required property string widgetId
    default property alias content: body.data
    property int defaultX: 80
    property int defaultY: 80

    anchors { top: true; left: true }
    margins { left: pos.x; top: pos.y }
    implicitWidth: body.childrenRect.width
    implicitHeight: body.childrenRect.height
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom                       // above wallpaper, below windows
    WlrLayershell.namespace: "quickshell:desktop-" + widgetId

    Item { id: body; anchors.fill: parent }

    // drag with Super held to reposition; saved per widget
    MouseArea {
        anchors.fill: parent
        property point start
        acceptedButtons: Qt.LeftButton
        onPressed: m => { if (!(m.modifiers & Qt.MetaModifier)) { m.accepted = false; return } start = Qt.point(m.x, m.y) }
        onPositionChanged: m => {
            if (!pressed) return
            pos.x = Math.max(0, pos.x + m.x - start.x)
            pos.y = Math.max(0, pos.y + m.y - start.y)
        }
    }

    FileView {
        path: Quickshell.statePath("desktop-" + root.widgetId + ".json")
        onAdapterUpdated: writeAdapter()
        printErrors: false
        JsonAdapter { id: pos; property int x: root.defaultX; property int y: root.defaultY }
    }
}
```

## Desktop clock

```qml file="modules/decorations/DesktopClock.qml"
import Quickshell
import QtQuick
import QtQuick.Effects
import qs.services
import qs.widgets

Variants {
    model: Quickshell.screens
    DesktopWidget {
        required property ShellScreen modelData
        screen: modelData
        widgetId: "clock-" + modelData.name
        defaultX: 100; defaultY: 120

        Column {
            id: col
            spacing: -10
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowOpacity: 0.5; shadowVerticalOffset: 3 }

            StyledText {
                text: Qt.formatDateTime(Time.now, "hh:mm")
                font.pixelSize: Appearance.font.size.display * 1.6
                font.weight: Font.Black
                font.features: ({ "tnum": 1 })
                color: Colors.primary
            }
            StyledText {
                text: Qt.formatDateTime(Time.now, "dddd, d MMMM")
                font.pixelSize: Appearance.font.size.title
                color: Colors.onSurface
            }
        }
    }
}
```

## System monitor widget

Reuses the `SystemUsage` service from [[ch:37-processes]] and the ring from [[ch:26-shapes-canvas]]:

```qml file="widgets/Ring.qml"
import QtQuick
import QtQuick.Shapes
import qs.services

Item {
    id: root
    property real value: 0
    property string label: ""
    property color color: Colors.primary
    property real thickness: 7
    implicitWidth: 90; implicitHeight: 90

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"; strokeColor: Colors.surfaceContainerHighest
            strokeWidth: root.thickness; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2
                           radiusX: root.width / 2 - root.thickness; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.color
            strokeWidth: root.thickness; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.width / 2; centerY: root.height / 2
                           radiusX: root.width / 2 - root.thickness; radiusY: radiusX
                           startAngle: -90; sweepAngle: 360 * Math.min(1, root.value) }
        }
    }
    Column {
        anchors.centerIn: parent
        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.value * 100) + "%"; font.bold: true; font.pixelSize: 18 }
        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: root.label; color: Colors.onSurfaceVariant; font.pixelSize: 11 }
    }
    Behavior on value { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
}
```

```qml file="modules/decorations/SystemMonitor.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

DesktopWidget {
    screen: Quickshell.screens[0]
    widgetId: "sysmon"
    defaultX: 100; defaultY: 360

    StyledRect {
        width: 330; height: 200
        level: 1
        color: Colors.alpha(Colors.surface, 0.7)
        RowLayout {
            anchors.centerIn: parent
            spacing: 16
            Ring { value: SystemUsage.cpu; label: "CPU" }
            Ring { value: SystemUsage.ram; label: "RAM"; color: Colors.tertiary }
            Ring { value: Battery.percent; label: "BAT"; color: Battery.low ? Colors.error : Colors.secondary; visible: Battery.available }
        }
    }
}
```

## Weather card

```qml file="services/Weather.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string location: Config.weather?.location ?? ""        // "" = auto by IP
    property real tempC: NaN
    property string condition: ""
    property string icon: "cloud"

    function iconFor(code: int): string {                             // wttr.in weatherCode → Material Symbol
        if (code === 113) return "sunny"
        if ([116, 119].includes(code)) return "partly_cloudy_day"
        if (code === 122) return "cloud"
        if ([143, 248, 260].includes(code)) return "foggy"
        if (code >= 386) return "thunderstorm"
        if ([179, 227, 230].includes(code) || (code >= 323 && code <= 377)) return "weather_snowy"
        return "rainy"
    }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/" + encodeURIComponent(root.location) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const cur = JSON.parse(text).current_condition[0]
                    root.tempC = parseFloat(cur.temp_C)
                    root.condition = cur.weatherDesc[0].value
                    root.icon = root.iconFor(parseInt(cur.weatherCode))
                } catch (e) { console.warn("weather parse failed", e) }
            }
        }
    }
    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }
}
```

```qml
StyledRect {
    width: 220; height: 90
    RowLayout {
        anchors.centerIn: parent
        spacing: 12
        MaterialIcon { icon: Weather.icon; size: 44; fill: 1; color: Colors.primary }
        Column {
            StyledText { text: isNaN(Weather.tempC) ? "—" : Math.round(Weather.tempC) + "°C"; font.pixelSize: 28; font.bold: true }
            StyledText { text: Weather.condition; color: Colors.onSurfaceVariant }
        }
    }
}
```

## Practice

::: exercise warm | Toggle each widget
Add a Config toggle for each desktop widget (`LazyLoader { active: Config.desktop.clock; DesktopClock {} }`).
:::

::: exercise practice | Now playing widget
Add a "now playing" desktop widget that only shows while music plays.
--- hint
`visible: Media.active?.isPlaying ?? false`. The ricing guide's `DeskMedia` ([[ch:r8-desktop]]) is a full version.
:::

::: exercise challenge | CPU history graph
Add a CPU history graph (Canvas) to the system monitor.
--- hint
Reuse the Canvas graph from [[ch:26-shapes-canvas]]'s practice, appending `SystemUsage.cpu` in `onCpuChanged`.
:::
