# Project: System Tray with Custom Menus

Apps like Discord, Steam, nm-applet and Telegram put icons in the tray. This project shows them, handles left/middle/right clicks and scrolling, fixes broken icon paths, and draws **fully custom-styled menus** with submenus, checkboxes and separators.

## The tray row

```qml file="modules/bar/Tray.qml"
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Rectangle {
    id: root
    required property var bar
    property bool expanded: true

    visible: SystemTray.items.values.length > 0
    implicitWidth: row.implicitWidth + 12
    implicitHeight: 28
    radius: height / 2
    color: Colors.surfaceContainerHigh
    clip: true
    Behavior on implicitWidth { Anim {} }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: ScriptModel {
                // hide passive items unless expanded; keep a stable order
                values: SystemTray.items.values.filter(i => root.expanded || i.status !== Status.Passive)
            }

            TrayIcon { bar: root.bar }
        }
    }
}
```

## One tray icon

```qml file="modules/bar/TrayIcon.qml"
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    required property SystemTrayItem modelData
    required property var bar
    implicitWidth: 20; implicitHeight: 20

    // Some apps send "name?path=/dir" icons. Rewrite them to a file URL.
    readonly property string iconSource: {
        const ic = modelData.icon
        if (ic.includes("?path=")) {
            const [name, path] = ic.split("?path=")
            const file = name.substring(name.lastIndexOf("/") + 1)
            return `file://${path}/${file}`
        }
        return ic
    }

    IconImage {
        id: img
        anchors.fill: parent
        source: root.iconSource
        asynchronous: true
        opacity: root.modelData.status === Status.NeedsAttention ? (blink.on ? 1 : 0.4) : 1
        scale: hover.hovered ? 1.12 : 1
        Behavior on scale { Anim { duration: Appearance.anim.fast } }
    }
    Timer { id: blink; property bool on: true; interval: 600; repeat: true
            running: root.modelData.status === Status.NeedsAttention; onTriggered: on = !on }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => {
            if (m.button === Qt.LeftButton && !root.modelData.onlyMenu) root.modelData.activate()
            else if (m.button === Qt.MiddleButton) root.modelData.secondaryActivate()
            else if (root.modelData.hasMenu) menu.open()
        }
        onWheel: w => root.modelData.scroll(w.angleDelta.y / 120, false)
    }

    Tooltip {
        target: root
        text: root.modelData.tooltipTitle || root.modelData.title
        show: hover.hovered && !menu.visible
    }

    TrayMenu {
        id: menu
        anchorItem: root
        menuHandle: root.modelData.menu
    }
}
```

`Tooltip` is the widget from [[ch:32-popups-menus]] (move it to `widgets/`).

## Option A: native-looking menu (one line)

If you don't care about styling:

```qml
QsMenuAnchor {
    id: menu
    menu: root.modelData.menu
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
}
// menu.open()
```

## Option B: a fully custom menu

[[QsMenuOpener]] exposes a menu's entries as [[QsMenuEntry]] objects, so you can draw them yourself. Submenus are handled by pushing another opener onto a stack.

```qml file="modules/bar/TrayMenu.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PopupWindow {
    id: root
    required property Item anchorItem
    property var menuHandle                        // QsMenuHandle from the tray item
    property var stack: []                         // submenu path (list of QsMenuEntry)
    readonly property var currentMenu: stack.length ? stack[stack.length - 1] : menuHandle

    function open(): void { stack = []; visible = true }
    function close(): void { visible = false }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    implicitWidth: 240
    implicitHeight: list.implicitHeight + 12
    color: "transparent"
    visible: false
    grabFocus: true

    QsMenuOpener { id: opener; menu: root.currentMenu }

    StyledRect {
        anchors.fill: parent
        level: 2
        radius: Appearance.rounding.normal

        ColumnLayout {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 2

            // back button inside submenus
            MenuRow {
                visible: root.stack.length > 0
                label: "Back"
                leadingIcon: "arrow_back"
                onActivated: root.stack = root.stack.slice(0, -1)
            }

            Repeater {
                model: opener.children
                MenuRow {
                    required property QsMenuEntry modelData
                    entry: modelData
                    onActivated: {
                        if (modelData.hasChildren) root.stack = [...root.stack, modelData]
                        else { modelData.triggered(); root.close() }
                    }
                }
            }
        }
    }
}
```

```qml file="modules/bar/MenuRow.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.widgets

Item {
    id: root
    property QsMenuEntry entry: null
    property string label: entry?.text ?? ""
    property string leadingIcon: ""
    signal activated()

    readonly property bool separator: entry?.isSeparator ?? false
    readonly property bool enabledEntry: entry ? entry.enabled : true

    Layout.fillWidth: true
    implicitHeight: separator ? 9 : 32

    Rectangle {                                    // separator line
        visible: root.separator
        anchors.centerIn: parent
        width: parent.width - 12; height: 1
        color: Colors.outlineVariant
    }

    Rectangle {
        visible: !root.separator
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: hov.hovered && root.enabledEntry ? Colors.surfaceContainerHighest : "transparent"

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 8

            // checkbox / radio indicator
            MaterialIcon {
                visible: (root.entry?.buttonType ?? QsMenuButtonType.None) !== QsMenuButtonType.None
                icon: root.entry?.buttonType === QsMenuButtonType.RadioButton
                      ? (root.entry?.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked")
                      : (root.entry?.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank")
                size: 18
                color: Colors.primary
            }
            MaterialIcon { visible: root.leadingIcon !== ""; icon: root.leadingIcon; size: 18 }
            IconImage {
                visible: (root.entry?.icon ?? "") !== ""
                source: root.entry?.icon ?? ""
                implicitSize: 16
            }
            StyledText {
                Layout.fillWidth: true
                text: root.label.replace(/_/g, "")       // strip mnemonic underscores like "_Quit"
                color: root.enabledEntry ? Colors.onSurface : Colors.alpha(Colors.onSurface, 0.38)
            }
            MaterialIcon { visible: root.entry?.hasChildren ?? false; icon: "chevron_right"; size: 18 }
        }
        HoverHandler { id: hov }
        TapHandler { enabled: root.enabledEntry; onTapped: root.activated() }
    }
}
```

## How it works

- `QsMenuOpener.menu` accepts the tray item's `menu` **or** any `QsMenuEntry` with children, which is how submenus work.
- `opener.children` is an ObjectModel of entries; it updates when the app changes its menu.
- `entry.triggered()` sends the click to the application.
- `checkState` uses Qt's `Qt.Unchecked / Qt.PartiallyChecked / Qt.Checked`.
- Some apps build menus lazily. If a menu is empty the first time, the underlying [[DBusMenuItem.updateLayout()]] can refresh it.

> [!WILD] In the wild
> Both end-4 and Caelestia render tray menus themselves with `QsMenuOpener` so they match the theme. Caelestia animates submenus sliding horizontally.

## Practice

::: exercise warm | Collapse passive icons
Add a chevron button that toggles `expanded` to hide passive tray icons.
--- solution
Filter the model: `model: ScriptModel { values: SystemTray.items.values.filter(i => expanded || i.status !== Status.Passive) }`, and add a chevron `Text` whose tap toggles `expanded`.
:::

::: exercise practice | Slide submenus
Animate submenu changes with a horizontal slide.
--- hint
Use a `StackView` (push/pop transitions) or animate `x` of the old and new menu columns in a `ParallelAnimation`.
:::

::: exercise challenge | Pinned ids
Keep a list of pinned tray ids in Config and sort those first.
--- solution
```qml
values: [...SystemTray.items.values].sort((a, b) => (Config.tray.pinned.includes(b.id) ? 1 : 0) - (Config.tray.pinned.includes(a.id) ? 1 : 0))
```
:::
