# Project: Workspace Indicators (All Compositors)

Workspaces are the heart of a tiling-WM bar. This project builds a polished indicator with a sliding pill, occupied/empty/urgent states, scroll-to-switch, and optional app icons. We first build it for Hyprland, then make a compositor-neutral service so the same UI works on Sway and niri.

## Design

- Always show workspaces **1–10** (configurable), even when they don't exist yet.
- **Active** workspace: a wide pill in `primary` that slides between positions.
- **Occupied**: a solid dot. **Empty**: a faint dot. **Urgent**: an `error`-colored dot that pulses.
- Scroll on the widget to move between workspaces; click to jump.

## A compositor-neutral service

```qml file="services/Workspaces.qml"
pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.I3
import QtQuick

Singleton {
    id: root

    readonly property string backend: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "hyprland"
                                    : Quickshell.env("SWAYSOCK") ? "sway"
                                    : Quickshell.env("NIRI_SOCKET") ? "niri" : "none"

    // id of the active workspace on a given screen
    function activeOn(screen: ShellScreen): int {
        if (backend === "hyprland") return Hyprland.monitorFor(screen)?.activeWorkspace?.id ?? 1
        if (backend === "sway") return I3.monitorFor(screen)?.activeWorkspace?.number ?? 1
        return 1
    }
    // true if workspace `id` has windows
    function occupied(id: int): bool {
        if (backend === "hyprland")
            return Hyprland.workspaces.values.some(w => w.id === id && w.toplevels.values.length > 0)
        if (backend === "sway")
            return I3.workspaces.values.some(w => w.number === id)       // sway only lists non-empty workspaces
        return false
    }
    function urgent(id: int): bool {
        if (backend === "hyprland") return Hyprland.workspaces.values.some(w => w.id === id && w.urgent)
        if (backend === "sway") return I3.workspaces.values.some(w => w.number === id && w.urgent)
        return false
    }
    function focus(id: int): void {
        if (backend === "hyprland") Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = "${id}" })` : `workspace ${id}`)
        else if (backend === "sway") I3.dispatch(`workspace number ${id}`)
        else if (backend === "niri") Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(id)])
    }
    function relative(delta: int, screen: ShellScreen): void {
        const next = Math.max(1, Math.min(Config.bar.workspaceCount ?? 10, activeOn(screen) + delta))
        focus(next)
    }
}
```

> [!NOTE] Bindings through functions
> `Workspaces.activeOn(screen)` used in a binding still updates: QML tracks the properties the function reads (`activeWorkspace.id`, `workspaces.values`…).

## The widget

```qml file="modules/bar/Workspaces.qml"
import Quickshell
import QtQuick
import qs.services
import qs.widgets

Rectangle {
    id: root
    required property ShellScreen screen
    readonly property int count: Config.bar.workspaceCount ?? 10
    readonly property int active: Workspaces.activeOn(screen)
    readonly property int dot: 8
    readonly property int pillWidth: 26
    readonly property int gap: 6

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    radius: height / 2
    color: Colors.surfaceContainerHigh

    // the sliding active pill (behind the dots)
    Rectangle {
        readonly property Item target: rep.itemAt(root.active - 1)
        x: row.x + (target?.x ?? 0)
        width: target?.width ?? 0
        height: root.dot + 4
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Colors.primary
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on width { Anim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            id: rep
            model: root.count
            Item {
                id: cell
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: wsId === root.active
                readonly property bool isOccupied: Workspaces.occupied(wsId)
                readonly property bool isUrgent: Workspaces.urgent(wsId)

                width: isActive ? root.pillWidth : root.dot + 4
                height: root.dot + 4
                Behavior on width { Anim {} }

                Rectangle {
                    anchors.centerIn: parent
                    visible: !cell.isActive
                    width: root.dot; height: root.dot; radius: root.dot / 2
                    color: cell.isUrgent ? Colors.error
                         : cell.isOccupied ? Colors.onSurfaceVariant
                         : Colors.alpha(Colors.onSurfaceVariant, 0.3)
                    Behavior on color { CAnim {} }

                    SequentialAnimation on opacity {           // urgent pulse
                        running: cell.isUrgent
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                        onStopped: parent.opacity = 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3                      // bigger click target
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Workspaces.focus(cell.wsId)
                }
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real acc: 0
        onWheel: e => {
            acc += e.angleDelta.y
            if (Math.abs(acc) >= 120) {
                Workspaces.relative(acc > 0 ? -1 : 1, root.screen)
                acc = 0
            }
        }
    }
}
```

## Variant: numbered workspaces

Replace the dot with a `StyledText { text: cell.wsId }`, colored `Colors.onPrimary` when active and `Colors.onSurfaceVariant` otherwise. Make the pill a fixed 24 px circle.

## Variant: app icons per workspace (Hyprland)

```qml
Row {
    spacing: 2
    Repeater {
        model: Hyprland.workspaces.values.find(w => w.id === cell.wsId)?.toplevels ?? []
        IconImage {
            required property HyprlandToplevel modelData
            implicitSize: 14
            source: Quickshell.iconPath(
                DesktopEntries.heuristicLookup(modelData.lastIpcObject?.class ?? modelData.wayland?.appId ?? "")?.icon ?? "",
                "application-x-executable")
        }
    }
}
```

`lastIpcObject` may be empty until refreshed; listen to `openwindow`/`closewindow` raw events and call `Hyprland.refreshToplevels()`.

## Variant: niri with the fork module

```qml
// in Workspaces service
if (backend === "niri") return Niri.workspaces.values.find(w => w.focused && w.output === screen.name)?.idx ?? 1
```

`import Quickshell.Niri` requires the noctalia-qs build ([[ch:40-compositors]]).

## Special workspaces (Hyprland scratchpads)

Special workspaces have negative ids and names like `special:magic`. Show an indicator when one is open on this monitor:

```qml
MaterialIcon {
    readonly property var mon: Hyprland.monitorFor(root.screen)
    visible: (mon?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
    icon: "visibility"
}
```

(`lastIpcObject` for monitors needs `Hyprland.refreshMonitors()` on the `activespecial` event.)

> [!TRY] Exercises
> 1. Make the workspace count configurable from `config.json`.
> 2. Add a tooltip showing the window titles on hover.
> 3. Hide empty workspaces above the highest occupied one (dynamic count).
