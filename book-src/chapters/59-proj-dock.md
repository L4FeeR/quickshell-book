# Project: Dock

A macOS-style dock that works on **any** compositor: pinned apps plus running apps, running indicators, focus or cycle windows on click, middle-click for a new instance, right-click menu with actions, magnification on hover, and auto-hide that reveals when the mouse touches the bottom edge.

## Pinned apps in config

```qml
// in services/Config.qml JsonAdapter
property JsonObject dock: JsonObject {
    property bool enabled: true
    property bool autoHide: true
    property list<string> pinned: ["firefox", "kitty", "org.gnome.Nautilus", "spotify", "code"]
}
```

## The dock

```qml file="modules/dock/Dock.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Scope {
    Variants {
        model: Config.dock.enabled ? Quickshell.screens : []

        PanelWindow {
            id: dock
            required property ShellScreen modelData
            screen: modelData

            anchors.bottom: true
            implicitWidth: Math.max(200, row.implicitWidth + 40)
            implicitHeight: 96                       // tall enough for magnified icons
            exclusionMode: Config.dock.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto
            exclusiveZone: Config.dock.autoHide ? 0 : 72
            color: "transparent"
            WlrLayershell.namespace: "quickshell:dock"

            // all windows on this screen
            readonly property var windows: ToplevelManager.toplevels.values.filter(t => t.screens.includes(modelData))
            // pinned first, then running apps not pinned
            readonly property var apps: {
                const ids = [...Config.dock.pinned]
                for (const w of windows) {
                    const id = w.appId
                    if (id && !ids.some(p => p.toLowerCase() === id.toLowerCase())) ids.push(id)
                }
                return ids
            }

            readonly property bool revealed: !Config.dock.autoHide || hover.hovered || menu.visible
                                             || (ToplevelManager.activeToplevel === null)        // show on empty desktop

            // when hidden, only a 3 px strip at the bottom catches the mouse
            mask: Region { item: dock.revealed ? body : trigger }
            Item { id: trigger; anchors.bottom: parent.bottom; width: parent.width; height: 3 }
            HoverHandler { id: hover }

            StyledRect {
                id: body
                anchors.horizontalCenter: parent.horizontalCenter
                width: row.implicitWidth + 20
                height: 64
                y: dock.revealed ? parent.height - height - 8 : parent.height + 4
                Behavior on y { Anim {} }
                level: 2
                radius: Appearance.rounding.large
                color: Colors.barBackground

                Row {
                    id: row
                    anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                    spacing: 6

                    Repeater {
                        model: ScriptModel { values: dock.apps }

                        Item {
                            id: app
                            required property string modelData
                            readonly property DesktopEntry entry: DesktopEntries.heuristicLookup(modelData)
                            readonly property var appWindows: dock.windows.filter(w => w.appId.toLowerCase() === modelData.toLowerCase()
                                                                          || w.appId.toLowerCase() === (entry?.startupClass ?? "").toLowerCase())
                            readonly property bool focused: appWindows.some(w => w.activated)
                            readonly property real mag: iconHover.hovered ? 1.35 : 1

                            width: 48 * mag
                            height: 48
                            Behavior on width { Anim { duration: Appearance.anim.fast } }

                            IconImage {
                                id: icon
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                                implicitSize: 44 * app.mag
                                Behavior on implicitSize { Anim { duration: Appearance.anim.fast } }
                                source: Quickshell.iconPath(app.entry?.icon ?? app.modelData, "application-x-executable")
                                asynchronous: true
                            }

                            // running indicators (one dot per window, max 3)
                            Row {
                                anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 2 }
                                spacing: 3
                                Repeater {
                                    model: Math.min(3, app.appWindows.length)
                                    Rectangle {
                                        width: app.focused ? 12 : 5; height: 4; radius: 2
                                        color: app.focused ? Colors.primary : Colors.onSurfaceVariant
                                        Behavior on width { Anim {} }
                                    }
                                }
                            }

                            Tooltip { target: app; text: app.entry?.name ?? app.modelData; show: iconHover.hovered && !menu.visible }
                            HoverHandler { id: iconHover }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: m => {
                                    if (m.button === Qt.RightButton) { menu.app = app; menu.visible = true; return }
                                    if (m.button === Qt.MiddleButton || app.appWindows.length === 0) {
                                        if (app.entry) Apps.launch(app.entry)
                                        return
                                    }
                                    // cycle through this app's windows; minimize if it's the only focused one
                                    const i = app.appWindows.findIndex(w => w.activated)
                                    if (i >= 0 && app.appWindows.length === 1) app.appWindows[0].minimized = true
                                    else app.appWindows[(i + 1) % app.appWindows.length].activate()
                                }
                            }
                        }
                    }
                }
            }

            DockMenu { id: menu; dockWindow: dock }
        }
    }
}
```

## Right-click menu

```qml file="modules/dock/DockMenu.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets
import qs.modules.bar          // MenuRow from the tray chapter

PopupWindow {
    id: root
    required property var dockWindow
    property Item app: null
    readonly property bool pinned: app ? Config.dock.pinned.includes(app.modelData) : false

    anchor.item: app ?? dockWindow.contentItem
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.margins.bottom: 8
    implicitWidth: 220
    implicitHeight: col.implicitHeight + 12
    color: "transparent"
    visible: false
    grabFocus: true

    StyledRect {
        anchors.fill: parent
        level: 2
        radius: Appearance.rounding.normal
        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 2

            StyledText { text: root.app?.entry?.name ?? ""; font.bold: true; Layout.margins: 8 }

            Repeater {                                    // desktop actions
                model: root.app?.entry?.actions ?? []
                MenuRow { required property DesktopAction modelData; label: modelData.name
                          onActivated: { modelData.execute(); root.visible = false } }
            }
            MenuRow {
                label: "New window"; leadingIcon: "add"
                onActivated: { Apps.launch(root.app.entry); root.visible = false }
            }
            MenuRow {
                label: root.pinned ? "Unpin" : "Pin to dock"
                leadingIcon: root.pinned ? "keep_off" : "keep"
                onActivated: {
                    const id = root.app.modelData
                    Config.dock.pinned = root.pinned ? Config.dock.pinned.filter(p => p !== id) : [...Config.dock.pinned, id]
                    root.visible = false
                }
            }
            MenuRow {
                visible: (root.app?.appWindows.length ?? 0) > 0
                label: "Close all"; leadingIcon: "close"
                onActivated: { root.app.appWindows.forEach(w => w.close()); root.visible = false }
            }
        }
    }
}
```

## Matching windows to apps

App ids aren't always the desktop file name: Firefox reports `firefox`, Nautilus `org.gnome.Nautilus`, Chromium apps `chrome-<id>-Default`, Electron apps sometimes their own names. [[DesktopEntries.heuristicLookup()]] handles most cases; [[DesktopEntry.startupClass]] (the `StartupWMClass` key) covers many others.

## Minimize animations

Tell the compositor where a window's dock icon is, so minimize animations fly to it:

```qml
Component.onCompleted: app.appWindows.forEach(w => w.setRectangle(dock, dock.itemRect(icon)))
```

> [!TRY] Exercises
> 1. Add drag-to-reorder for pinned apps (save the order to Config).
> 2. Add a separator between pinned and running-only apps.
> 3. Hide the dock while any window on this screen is fullscreen (`windows.some(w => w.fullscreen)`).
