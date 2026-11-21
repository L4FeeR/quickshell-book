# Project: Edge Drawers (Caelestia Style)

The capstone. Instead of separate windows for the bar and every panel, build **one fullscreen, transparent window per monitor** holding a vertical bar on the left edge and "drawers" that grow out of the screen edges, connected to the bar by smooth concave curves, as if the whole UI were one continuous liquid shape. This is the architecture behind Caelestia.

Everything here uses techniques you already know: masks ([[ch:35-masks]]), shapes ([[ch:26-shapes-canvas]]), motion ([[ch:45-motion]]) and state ([[ch:46-state]]).

## Architecture

<div class="diagram"><svg viewBox="0 0 780 300" role="img" aria-label="drawer architecture">
<rect class="n" x="20" y="20" width="740" height="260" rx="10"/><text class="sm" x="30" y="38">Drawers window: fullscreen, transparent, ExclusionMode.Ignore, mask = visible shapes</text>
<rect class="a" x="20" y="20" width="44" height="260" rx="6"/><text class="sm" x="28" y="160">bar</text>
<path class="ln" d="M64 70 Q64 90 84 90 L300 90 Q320 90 320 110 L320 190 Q320 210 300 210 L84 210 Q64 210 64 230"/><text x="120" y="155">launcher drawer</text>
<rect class="g" x="560" y="20" width="200" height="110" rx="10"/><text x="575" y="80">dashboard drawer (top)</text>
<rect class="g" x="600" y="200" width="160" height="70" rx="10"/><text x="612" y="240">OSD drawer (right)</text>
</svg></div>

Per screen:

1. **Exclusion window**: an invisible PanelWindow that reserves the bar's width (`exclusiveZone`).
2. **Drawers window**: fullscreen, transparent, `ExclusionMode.Ignore`, Top layer. Contains:
   - a **background Shape** that draws bar + all open drawers as one filled path with concave joints,
   - the **content** of the bar and each drawer on top of it,
   - a **mask** that covers only the bar and open drawers.
3. **State**: `GlobalStates` flags plus "hover to peek" logic.

## The exclusion window

```qml file="modules/drawers/Exclusion.qml"
import Quickshell
import QtQuick
import qs.services

PanelWindow {
    required property ShellScreen screenRef
    screen: screenRef
    anchors { left: true; top: true; bottom: true }
    implicitWidth: 1
    exclusiveZone: Appearance.sizes.barHeight          // reserve the bar's width
    color: "transparent"
    mask: Region {}
}
```

## A drawer = a size that animates

Each drawer is just an `Item` whose width/height animate between 0 and its content size. The content is clipped, so it appears to grow out of the edge.

```qml file="modules/drawers/Drawer.qml"
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property bool open: false
    property int edge: Qt.LeftEdge          // which screen edge it grows from
    default property alias content: inner.data
    readonly property real contentW: inner.childrenRect.width
    readonly property real contentH: inner.childrenRect.height

    // horizontal drawers animate width, vertical ones animate height
    readonly property bool horizontal: edge === Qt.LeftEdge || edge === Qt.RightEdge
    width: horizontal ? (open ? contentW : 0) : contentW
    height: horizontal ? contentH : (open ? contentH : 0)
    clip: true
    visible: width > 0 && height > 0

    Behavior on width { enabled: root.horizontal; Anim { duration: Appearance.anim.slow } }
    Behavior on height { enabled: !root.horizontal; Anim { duration: Appearance.anim.slow } }

    Item {
        id: inner
        // keep content pinned to the edge it grows from
        x: root.edge === Qt.RightEdge ? root.width - root.contentW : (root.edge === Qt.LeftEdge ? root.width - root.contentW : 0)
        y: root.edge === Qt.BottomEdge ? root.height - root.contentH : (root.edge === Qt.TopEdge ? root.height - root.contentH : 0)
        width: root.contentW; height: root.contentH
        opacity: root.open ? 1 : 0
        Behavior on opacity { Anim { duration: root.open ? Appearance.anim.slow : Appearance.anim.fast } }
    }
}
```

The content slides in from the edge because it's positioned relative to the growing side.

## The connecting background shape

The trick that makes it look liquid: the **background is drawn separately** from the content, as one `Shape` per drawer. Each shape is a rounded rectangle attached to an edge, with **concave flares** where it meets the bar or screen edge.

```qml file="modules/drawers/DrawerBackground.qml"
import QtQuick
import QtQuick.Shapes
import qs.services

// background for a drawer attached to the LEFT (bar) side.
Shape {
    id: bg
    required property Item drawer            // the Drawer it decorates
    property real r: Appearance.rounding.large
    readonly property real w: drawer.width
    readonly property real h: drawer.height

    x: drawer.x
    y: drawer.y - r                          // flares extend above and below
    width: w + r
    height: h + 2 * r
    visible: w > 1 && h > 1
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: Colors.surface
        strokeWidth: -1
        startX: 0; startY: 0
        // concave flare at the top, curving from the bar into the drawer
        PathArc { x: Math.min(bg.r, bg.w); y: bg.r; radiusX: Math.min(bg.r, bg.w); radiusY: bg.r }
        PathLine { x: bg.w - bg.r; y: bg.r }
        // convex top-right corner
        PathArc { x: bg.w; y: bg.r * 2; radiusX: bg.r; radiusY: bg.r }
        PathLine { x: bg.w; y: bg.h }
        // convex bottom-right corner
        PathArc { x: bg.w - bg.r; y: bg.h + bg.r; radiusX: bg.r; radiusY: bg.r }
        PathLine { x: Math.min(bg.r, bg.w); y: bg.h + bg.r }
        // concave flare at the bottom
        PathArc { x: 0; y: bg.h + 2 * bg.r; radiusX: Math.min(bg.r, bg.w); radiusY: bg.r }
        PathLine { x: 0; y: 0 }
    }
}
```

Because `w` and `h` follow the drawer's animated size, the background reshapes every frame of the animation.

## The drawers window

```qml file="modules/drawers/Drawers.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets
import qs.modules.bar

Scope {
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property ShellScreen modelData
            readonly property bool focusedScreen: GlobalStates.activeScreen === modelData.name

            Exclusion { screenRef: perScreen.modelData }

            PanelWindow {
                id: win
                screen: perScreen.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell:drawers"
                WlrLayershell.keyboardFocus: launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                // input only where something is visible
                mask: Region {
                    item: bar
                    Region { item: launcher }
                    Region { item: dashboard }
                    Region { item: osd }
                    Region { item: launcherHot }
                }
                // hint Hyprland to skip transparent areas
                HyprlandWindow.visibleMask: Region {
                    item: bar
                    Region { item: launcher }
                    Region { item: dashboard }
                    Region { item: osd }
                }

                // ---------------- the bar ----------------
                Rectangle {
                    id: bar
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: Appearance.sizes.barHeight
                    color: Colors.surface

                    ColumnLayout {
                        anchors { fill: parent; topMargin: 10; bottomMargin: 10 }
                        spacing: 10
                        IconButton {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "apps"
                            toggled: GlobalStates.launcherOpen
                            onClicked: GlobalStates.toggle("launcher")
                        }
                        Item { Layout.fillHeight: true }
                        StyledText {                                   // vertical clock
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.formatDateTime(Time.now, "hh\nmm")
                            font.bold: true
                            lineHeight: 0.9
                        }
                        Item { Layout.fillHeight: true }
                        IconButton {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "power_settings_new"
                            onClicked: GlobalStates.toggle("session")
                        }
                    }
                }

                // ---------------- drawers (content) ----------------
                Drawer {
                    id: launcher
                    edge: Qt.LeftEdge
                    open: GlobalStates.launcherOpen && perScreen.focusedScreen
                    anchors.left: bar.right
                    anchors.verticalCenter: parent.verticalCenter
                    LauncherContent { width: 460; height: 520 }      // your launcher UI from Chapter 52, as an Item
                }

                Drawer {
                    id: dashboard
                    edge: Qt.TopEdge
                    open: (GlobalStates.controlCenterOpen || dashHover.hovered) && perScreen.focusedScreen
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    DashboardContent { width: 640; height: 260 }
                    HoverHandler { id: dashHover }
                }

                Drawer {
                    id: osd
                    edge: Qt.RightEdge
                    open: OsdState.shown && perScreen.focusedScreen
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    OsdContent { width: 64; height: 240 }
                }

                // hot zone: hovering the top edge peeks the dashboard
                Item {
                    id: launcherHot
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                    width: 300; height: 2
                    HoverHandler { onHoveredChanged: if (hovered) GlobalStates.open("controlCenter") }
                }

                // ---------------- backgrounds (behind content) ----------------
                DrawerBackground { drawer: launcher; z: -1 }
                TopDrawerBackground { drawer: dashboard; z: -1 }
                RightDrawerBackground { drawer: osd; z: -1 }

                Keys.onEscapePressed: GlobalStates.closeAll()
            }
        }
    }
}
```

`TopDrawerBackground` and `RightDrawerBackground` are the same shape as `DrawerBackground`, rotated: write the path for the top edge (flares on the left and right of the drawer, convex corners at the bottom), or wrap one shape in an `Item` with `rotation: 90`/`-90` and swap width/height.

## Making content components

Turn each module's UI into a plain `Item` (no window) so it can live inside a drawer: `LauncherContent.qml`, `DashboardContent.qml`, `OsdContent.qml`. The logic is identical to Part VI; only the outer `PanelWindow` goes away. Keyboard focus is handled by the drawers window (`WlrKeyboardFocus.Exclusive` while the launcher drawer is open).

## Why this architecture is powerful

- **Seamless shapes:** bar and drawers share one coordinate space, so their outlines join perfectly.
- **No popup positioning:** every drawer is just an Item anchored in the same window.
- **Peek interactions:** hovering an edge can open a drawer without any extra window.
- **One mask** controls all input.

Costs: a fullscreen surface per monitor (keep it transparent and use `HyprlandWindow.visibleMask` so the compositor skips empty areas), and you manage keyboard focus yourself.

> [!WILD] In the wild
> Caelestia's `modules/drawers/` implements exactly this: `Drawers.qml` (the window, mask and exclusion), `Backgrounds.qml` (the shape paths), `Interactions.qml` (hover/peek logic) and `Panels.qml` (content). Read it now: you'll recognize every piece.

> [!TRY] Exercises
> 1. Get the launcher drawer working with the background shape.
> 2. Add the top dashboard drawer with hover-to-peek and a 300 ms close delay when the mouse leaves.
> 3. Add a 1 px outline to the combined shape (`strokeColor`) for a crisp edge.
