# Project: Workspace Overview

An end-4-style overview: a grid of workspaces, each showing **live thumbnails** of its windows at their real positions and sizes. Click a window to focus it, click a workspace to switch, drag a window to another workspace to move it, type to filter by title.

This project is Hyprland-specific because it needs window geometry ([[HyprlandToplevel.lastIpcObject]]) and live capture ([[ScreencopyView]]).

## How it works

1. On open, call [[Hyprland.refreshToplevels()]] so every window's `lastIpcObject` has fresh `at` (position) and `size`.
2. Scale the monitor down (e.g. 0.16) to make a workspace cell.
3. For each window on a workspace, place a [[ScreencopyView]] at `(x − monitor.x) × scale`, `(y − monitor.y) × scale` with `width × scale`, `height × scale`.
4. Drag uses Qt's Drag/DropArea; drop dispatches `movetoworkspacesilent`.

```qml file="modules/overview/Overview.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    IpcHandler { target: "overview"; function toggle(): void { GlobalStates.toggle("overview") } }

    LazyLoader {
        active: GlobalStates.overviewOpen

        PanelWindow {
            id: win
            readonly property HyprlandMonitor mon: Hyprland.focusedMonitor
            screen: Quickshell.screens.find(s => s.name === mon?.name) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:overview"

            readonly property int columns: 5
            readonly property int rows: 2
            readonly property real scale: 0.16
            readonly property real monW: (mon?.width ?? 1920) / (mon?.scale ?? 1)
            readonly property real monH: (mon?.height ?? 1080) / (mon?.scale ?? 1)
            readonly property real cellW: monW * scale
            readonly property real cellH: monH * scale
            property string filter: ""

            Component.onCompleted: { Hyprland.refreshToplevels(); Hyprland.refreshMonitors() }
            Connections {
                target: Hyprland
                function onRawEvent(e) {
                    if (["openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode"].includes(e.name))
                        Hyprland.refreshToplevels()
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Colors.alpha("#000000", 0.45)
                MouseArea { anchors.fill: parent; onClicked: GlobalStates.overviewOpen = false }
            }

            Item {
                focus: true
                Keys.onEscapePressed: GlobalStates.overviewOpen = false
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Backspace) win.filter = win.filter.slice(0, -1)
                    else if (e.text.length === 1 && e.text >= " ") win.filter += e.text
                }
            }

            StyledRect {
                anchors.centerIn: parent
                width: grid.implicitWidth + 32
                height: grid.implicitHeight + 32 + (win.filter ? 40 : 0)
                level: 3
                color: Colors.surface

                StyledText {
                    visible: win.filter !== ""
                    anchors { top: parent.top; topMargin: 14; horizontalCenter: parent.horizontalCenter }
                    text: "Filter: " + win.filter
                    color: Colors.primary
                }

                GridLayout {
                    id: grid
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
                    columns: win.columns
                    rowSpacing: 10; columnSpacing: 10

                    Repeater {
                        model: win.columns * win.rows

                        Rectangle {
                            id: wsCell
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                            readonly property bool isActive: win.mon?.activeWorkspace?.id === wsId

                            implicitWidth: win.cellW
                            implicitHeight: win.cellH
                            radius: Appearance.rounding.normal
                            color: drop.containsDrag ? Colors.primaryContainer : Colors.surfaceContainer
                            border.width: isActive ? 2 : 0
                            border.color: Colors.primary
                            clip: true

                            StyledText {
                                anchors.centerIn: parent
                                text: wsCell.wsId
                                font.pixelSize: 32
                                opacity: 0.2
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { Hyprland.dispatch("workspace " + wsCell.wsId); GlobalStates.overviewOpen = false }
                            }
                            DropArea {
                                id: drop
                                anchors.fill: parent
                                keys: ["window"]
                                onDropped: d => Hyprland.dispatch(`movetoworkspacesilent ${wsCell.wsId},address:0x${d.source.address}`)
                            }

                            Repeater {
                                model: wsCell.ws?.toplevels ?? []

                                Item {
                                    id: winItem
                                    required property HyprlandToplevel modelData
                                    readonly property var ipc: modelData.lastIpcObject
                                    readonly property string address: modelData.address
                                    readonly property bool matches: win.filter === ""
                                        || (modelData.title + " " + (ipc?.class ?? "")).toLowerCase().includes(win.filter.toLowerCase())

                                    function homeX() { return ((ipc?.at?.[0] ?? 0) - (win.mon?.x ?? 0)) * win.scale }
                                    function homeY() { return ((ipc?.at?.[1] ?? 0) - (win.mon?.y ?? 0)) * win.scale }
                                    x: homeX(); y: homeY()
                                    width: Math.max(10, (ipc?.size?.[0] ?? 100) * win.scale)
                                    height: Math.max(10, (ipc?.size?.[1] ?? 100) * win.scale)
                                    opacity: matches ? 1 : 0.25
                                    z: dragArea.drag.active ? 10 : (ipc?.floating ? 2 : 1)

                                    Drag.active: dragArea.drag.active
                                    Drag.source: winItem
                                    Drag.keys: ["window"]
                                    Drag.hotSpot: Qt.point(width / 2, height / 2)

                                    ClippingRectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: Colors.surfaceContainerHighest
                                        border.width: hov.hovered ? 2 : 0
                                        border.color: Colors.primary

                                        ScreencopyView {
                                            anchors.fill: parent
                                            captureSource: winItem.modelData.wayland
                                            live: true
                                            constraintSize: Qt.size(width, height)
                                        }
                                        IconImage {
                                            anchors { right: parent.right; bottom: parent.bottom; margins: 3 }
                                            implicitSize: Math.min(24, parent.height / 2)
                                            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(winItem.ipc?.class ?? "")?.icon ?? "", "application-x-executable")
                                        }
                                    }
                                    HoverHandler { id: hov }
                                    MouseArea {
                                        id: dragArea
                                        anchors.fill: parent
                                        drag.target: parent
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        onClicked: m => {
                                            if (m.button === Qt.MiddleButton) Hyprland.dispatch("closewindow address:0x" + winItem.address)
                                            else { Hyprland.dispatch("focuswindow address:0x" + winItem.address); GlobalStates.overviewOpen = false }
                                        }
                                        onReleased: {
                                            parent.Drag.drop()
                                            parent.x = Qt.binding(() => winItem.homeX())   // snap back (the move happens via IPC)
                                            parent.y = Qt.binding(() => winItem.homeY())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

> [!NOTE] Address format
> `HyprlandToplevel.address` is the hex address **without** `0x`; dispatchers want `address:0x…`.

## Performance

Ten workspaces with many live previews can cost GPU time. Options:

- `live: false` and call `captureFrame()` once when opening (still images).
- Only make previews live for the hovered workspace.
- Lower `win.scale`.

## Keybind

```ini file="hyprland.conf"
bind  = SUPER, Tab, global, quickshell:overview
# or open on releasing Super alone, like end-4:
bindr = SUPER, SUPER_L, global, quickshell:overview
```

> [!TRY] Exercises
> 1. Arrow keys to move a selection between windows, Enter to focus.
> 2. Add a search box that also lists matching apps (combine with the launcher).
> 3. Show special workspaces (negative ids) in an extra row.
