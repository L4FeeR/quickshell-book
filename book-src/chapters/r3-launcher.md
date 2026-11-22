# Ricing the Launcher, Module by Module

The launcher is where you spend split seconds dozens of times a day, so it must feel **instant** and look sharp. This guide builds it from modules (window, search field, result row, grid tile, mode chips, footer, empty state) and shows three layouts: a Spotlight-style list, a full-screen grid, and a compact dmenu-style strip.

**Search logic** (fuzzy matching, frequency sorting, launching) comes from the `Apps` service in [[ch:52-proj-launcher]]. This guide is about how it looks.

## Anatomy

<div class="preview"><svg width="520" height="300" viewBox="0 0 520 300"><rect x="60" y="20" width="400" height="260" rx="22" fill="#1e1e2e" stroke="#313244"/><rect x="80" y="38" width="360" height="42" rx="21" fill="#313244"/><text x="104" y="64" fill="#cba6f7" font-size="15">⌕</text><text x="124" y="64" fill="#cdd6f4" font-size="13">fir|</text><g font-size="10"><rect x="82" y="90" width="50" height="20" rx="10" fill="#cba6f7"/><text x="107" y="104" fill="#1e1e2e" text-anchor="middle">Apps</text><rect x="138" y="90" width="50" height="20" rx="10" fill="#313244"/><text x="163" y="104" fill="#cdd6f4" text-anchor="middle">Calc</text><rect x="194" y="90" width="50" height="20" rx="10" fill="#313244"/><text x="219" y="104" fill="#cdd6f4" text-anchor="middle">Run</text></g><rect x="80" y="120" width="360" height="44" rx="14" fill="#45365e"/><rect x="92" y="128" width="28" height="28" rx="8" fill="#fab387"/><text x="132" y="140" fill="#cdd6f4" font-size="12" font-weight="700">Firefox</text><text x="132" y="155" fill="#a6adc8" font-size="10">Web Browser</text><text x="420" y="146" fill="#a6adc8" font-size="10" text-anchor="end">↵</text><rect x="92" y="174" width="28" height="28" rx="8" fill="#89b4fa"/><text x="132" y="186" fill="#cdd6f4" font-size="12">Files</text><text x="132" y="200" fill="#a6adc8" font-size="10">File manager</text><rect x="92" y="214" width="28" height="28" rx="8" fill="#a6e3a1"/><text x="132" y="226" fill="#cdd6f4" font-size="12">Firewall</text><line x1="80" y1="256" x2="440" y2="256" stroke="#313244"/><text x="80" y="272" fill="#6c7086" font-size="10">↑↓ move  ↵ open  Tab mode  Esc close</text></svg></div>

| Module | File | Job |
|---|---|---|
| Window | `LauncherWindow.qml` | the overlay, keyboard focus, open/close animation, layout |
| Search field | `SearchField.qml` | input with mode icon, placeholder, clear button |
| Mode chips | `ModeChips.qml` | Apps / Calc / Run / Web tabs |
| Result row | `ResultRow.qml` | icon, name, description, shortcut hint (list layout) |
| Grid tile | `GridTile.qml` | big icon + label (grid layout) |
| Footer | `Footer.qml` | keyboard hints |
| Empty state | `EmptyState.qml` | "no results" with a suggestion |

## Module 1: Search field

```qml file="rice/launcher/SearchField.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    property alias text: input.text
    property string modeIcon: "search"
    property string placeholder: "Search apps…"
    signal accepted()
    signal moveUp()
    signal moveDown()
    signal nextMode()
    signal cancel()

    implicitHeight: 48
    radius: Theme.style === "neon" ? 0 : height / 2
    color: Theme.surface
    border.width: input.activeFocus ? Math.max(1, Theme.border) : Theme.border
    border.color: input.activeFocus ? Theme.accent : Theme.borderColor

    RowLayout {
        anchors { fill: parent; leftMargin: 18; rightMargin: 12 }
        spacing: 12
        TIcon { icon: root.modeIcon; color: Theme.accent; size: 22 }
        TextInput {
            id: input
            Layout.fillWidth: true
            focus: true
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.textLarge
            selectionColor: Theme.accent
            selectedTextColor: Theme.onAccent
            clip: true
            TText { anchors.verticalCenter: parent.verticalCenter; visible: !parent.text; text: root.placeholder
                    color: Theme.alpha(Theme.fgDim, 0.6); font: parent.font }
            Keys.onReturnPressed: root.accepted()
            Keys.onEnterPressed: root.accepted()
            Keys.onUpPressed: root.moveUp()
            Keys.onDownPressed: root.moveDown()
            Keys.onTabPressed: root.nextMode()
            Keys.onEscapePressed: input.text ? input.text = "" : root.cancel()   // first Esc clears, second closes
        }
        TButton { visible: input.text !== ""; icon: "close"; size: 26; onClicked: input.text = "" }
    }
}
```

**Ricing choices:** a pill field for soft styles, a square one with an accent border for neon. "First Esc clears, second closes" is small UX that feels great.

<!-- ex:## Module 1 -->
::: exercise warm | Calculator mode icon
Change `modeIcon` to `calculate` when the text starts with `=`.
--- solution
```qml
SearchField { modeIcon: text.startsWith("=") ? "calculate" : "search" }
```
:::


## Module 2: Mode chips

```qml file="rice/launcher/ModeChips.qml"
import QtQuick
import qs.services
import qs.widgets

Row {
    id: root
    property var modes: [{ id: "apps", label: "Apps", icon: "apps" }, { id: "calc", label: "Calc", icon: "calculate" },
                         { id: "run", label: "Run", icon: "terminal" }, { id: "web", label: "Web", icon: "travel_explore" }]
    property string current: "apps"
    spacing: 6
    Repeater {
        model: root.modes
        Rectangle {
            required property var modelData
            readonly property bool on: root.current === modelData.id
            implicitWidth: lbl.implicitWidth + 36; implicitHeight: 28
            radius: Theme.style === "neon" ? 0 : 14
            color: on ? Theme.accent : hover.hovered ? Theme.surfaceHi : Theme.surface
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Row {
                anchors.centerIn: parent; spacing: 4
                TIcon { icon: modelData.icon; size: 14; color: parent.parent.on ? Theme.onAccent : Theme.fgDim }
                TText { id: lbl; text: modelData.label; font.pixelSize: Theme.textSmall; color: parent.parent.on ? Theme.onAccent : Theme.fg }
            }
            HoverHandler { id: hover }
            TapHandler { onTapped: root.current = modelData.id }
        }
    }
    function next() { const i = modes.findIndex(m => m.id === current); current = modes[(i + 1) % modes.length].id }
}
```

<!-- ex:## Module 2 -->
::: exercise practice | Shortcut numbers
Show `1`, `2`, `3`, `4` hints on the chips and let <kbd>Alt</kbd>+number switch modes.
:::


## Module 3: Result row (list layout)

```qml file="rice/launcher/ResultRow.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    required property DesktopEntry entry
    property bool selected: false
    property string query: ""
    signal activated()
    implicitHeight: 54

    Rectangle {                                     // selection background (the ListView highlight can be used instead)
        anchors.fill: parent
        radius: Theme.radiusSmall + 4
        color: root.selected ? Theme.alpha(Theme.accent, 0.18) : hover.hovered ? Theme.surface : "transparent"
        border.width: root.selected && Theme.style === "neon" ? 1 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 14 }
        spacing: 12
        IconImage { implicitSize: 32; source: Quickshell.iconPath(root.entry.icon, "application-x-executable"); asynchronous: true }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            TText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                // highlight the matched part of the name in the accent color
                text: {
                    const n = root.entry.name, q = root.query.toLowerCase(), i = n.toLowerCase().indexOf(q)
                    if (!q || i < 0) return n
                    return n.slice(0, i) + `<font color="${Theme.accent}"><b>` + n.slice(i, i + q.length) + "</b></font>" + n.slice(i + q.length)
                }
                font.bold: root.selected
            }
            TText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry.comment || root.entry.genericName || ""
                color: Theme.fgDim; font.pixelSize: Theme.textSmall
            }
        }
        TIcon { visible: root.selected; icon: "keyboard_return"; size: 16; color: Theme.fgDim }
    }
    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }
}
```

**Ricing choices:** highlighting the matched letters tells users *why* a result appears. A small ↵ on the selected row shows what Enter will do.

<!-- ex:## Module 3 -->
::: exercise practice | Category tag
Show the app's first category (`entry.categories[0]`) as a small tag at the right of the row.
:::


## Module 4: Grid tile (grid layout)

```qml file="rice/launcher/GridTile.qml"
import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    required property DesktopEntry entry
    property bool selected: false
    signal activated()
    implicitWidth: 112; implicitHeight: 112

    Rectangle {
        anchors.fill: parent; anchors.margins: 4
        radius: Theme.radius
        color: root.selected ? Theme.alpha(Theme.accent, 0.2) : hover.hovered ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    Column {
        anchors.centerIn: parent
        spacing: 8
        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: 52
            source: Quickshell.iconPath(root.entry.icon, "application-x-executable")
            asynchronous: true
            scale: hover.hovered || root.selected ? 1.1 : 1
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
        }
        TText { width: 100; horizontalAlignment: Text.AlignHCenter; text: root.entry.name; font.pixelSize: Theme.textSmall }
    }
    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }
}
```

<!-- ex:## Module 4 -->
::: exercise practice | Running dot
Show a small dot under grid tiles whose app has an open window.
--- hint
`ToplevelManager.toplevels.values.some(t => t.appId.toLowerCase() === entry.id.toLowerCase())`
:::


## Module 5: Footer and empty state

```qml file="rice/launcher/Footer.qml"
import QtQuick
import qs.services
import qs.widgets

Row {
    spacing: 16
    Repeater {
        model: [["↑↓", "move"], ["↵", "open"], ["Tab", "mode"], ["Esc", "close"]]
        Row {
            required property var modelData
            spacing: 5
            Rectangle { implicitWidth: k.implicitWidth + 10; implicitHeight: 18; radius: 4; color: Theme.surface
                        TText { id: k; anchors.centerIn: parent; text: modelData[0]; font.family: Theme.mono; font.pixelSize: 10 } }
            TText { text: modelData[1]; color: Theme.fgDim; font.pixelSize: Theme.textSmall }
        }
    }
}
```

```qml file="rice/launcher/EmptyState.qml"
import QtQuick
import qs.services
import qs.widgets

Column {
    property string query: ""
    spacing: 8
    TIcon { anchors.horizontalCenter: parent.horizontalCenter; icon: "search_off"; size: 44; color: Theme.alpha(Theme.fgDim, 0.5) }
    TText { anchors.horizontalCenter: parent.horizontalCenter; text: "No apps match “" + parent.query + "”"; color: Theme.fgDim }
    TText { anchors.horizontalCenter: parent.horizontalCenter; text: "Press Tab to search the web instead"; color: Theme.alpha(Theme.fgDim, 0.6)
            font.pixelSize: Theme.textSmall }
}
```

<!-- ex:## Module 5 -->
::: exercise practice | Result count
Add the number of results to the footer ("12 results").
:::


## Assembly: the window with three layouts

```qml file="rice/launcher/LauncherWindow.qml"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    id: root
    property string layout: "spotlight"        // "spotlight" | "grid" | "strip"

    LazyLoader {
        active: GlobalStates.launcherOpen
        PanelWindow {
            id: win
            readonly property bool grid: root.layout === "grid"
            readonly property bool strip: root.layout === "strip"
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            anchors { top: win.strip || win.grid; left: win.strip || win.grid; right: win.strip || win.grid; bottom: win.grid }
            implicitWidth: 620
            implicitHeight: win.strip ? 44 : 520
            exclusionMode: ExclusionMode.Ignore
            color: win.grid ? Theme.alpha(Theme.bg, 0.85) : "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:launcher"
            HyprlandFocusGrab { windows: [win]; active: !win.grid; onCleared: GlobalStates.launcherOpen = false }

            property string query: ""
            readonly property var results: Apps.search(query)
            property int sel: 0
            function close() { GlobalStates.launcherOpen = false }
            function launch(i) { if (results[i]) { Apps.launch(results[i]); close() } }

            TSurface {
                id: card
                // spotlight: floating card; grid: content area; strip: full-width bar
                anchors.fill: parent
                anchors.margins: win.grid ? 80 : 0
                color: win.grid ? "transparent" : Theme.bg
                radius: win.strip ? 0 : Theme.radius + 6
                border.width: win.grid ? 0 : Theme.border
                raised: !win.grid
                // open animation
                opacity: 0; scale: win.strip ? 1 : 0.96
                Component.onCompleted: { opacity = 1; scale = 1 }
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

                // ---------- strip layout: one row, dmenu-like ----------
                RowLayout {
                    visible: win.strip
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    spacing: 10
                    SearchField {
                        Layout.preferredWidth: 280; implicitHeight: 32
                        onTextChanged: { win.query = text; win.sel = 0 }
                        onAccepted: win.launch(win.sel); onCancel: win.close()
                        onMoveDown: win.sel = Math.min(win.results.length - 1, win.sel + 1)
                        onMoveUp: win.sel = Math.max(0, win.sel - 1)
                    }
                    Repeater {
                        model: win.results.slice(0, 8)
                        TText {
                            required property var modelData
                            required property int index
                            text: modelData.name
                            color: index === win.sel ? Theme.onAccent : Theme.fg
                            leftPadding: 8; rightPadding: 8
                            Rectangle { anchors.fill: parent; z: -1; radius: 4; color: parent.index === win.sel ? Theme.accent : "transparent" }
                        }
                    }
                }

                // ---------- spotlight and grid layouts ----------
                ColumnLayout {
                    visible: !win.strip
                    anchors { fill: parent; margins: 18 }
                    spacing: 12
                    SearchField {
                        id: field
                        Layout.fillWidth: true
                        Layout.maximumWidth: win.grid ? 560 : -1
                        Layout.alignment: Qt.AlignHCenter
                        onTextChanged: { win.query = text; win.sel = 0 }
                        onAccepted: win.launch(win.sel)
                        onCancel: win.close()
                        onMoveDown: win.sel = Math.min(win.results.length - 1, win.sel + (win.grid ? 6 : 1))
                        onMoveUp: win.sel = Math.max(0, win.sel - (win.grid ? 6 : 1))
                        onNextMode: modes.next()
                    }
                    ModeChips { id: modes; Layout.alignment: win.grid ? Qt.AlignHCenter : Qt.AlignLeft; visible: !win.grid }

                    ListView {
                        id: list
                        visible: !win.grid
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 2
                        currentIndex: win.sel
                        model: ScriptModel { values: win.results }
                        delegate: ResultRow {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            entry: modelData; query: win.query; selected: index === win.sel
                            onActivated: win.launch(index)
                        }
                    }
                    GridView {
                        visible: win.grid
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true
                        cellWidth: 120; cellHeight: 120
                        currentIndex: win.sel
                        model: ScriptModel { values: win.results }
                        delegate: GridTile {
                            required property var modelData
                            required property int index
                            entry: modelData; selected: index === win.sel
                            onActivated: win.launch(index)
                        }
                    }
                    EmptyState { Layout.alignment: Qt.AlignHCenter; visible: win.results.length === 0; query: win.query }
                    Footer { Layout.alignment: Qt.AlignHCenter; visible: !win.grid }
                }
            }
            MouseArea { anchors.fill: parent; z: -1; enabled: win.grid; onClicked: win.close() }   // grid: click outside closes
        }
    }
}
```

<div class="preview"><svg width="660" height="200" viewBox="0 0 660 200"><g font-size="10"><g transform="translate(5 5)"><rect width="210" height="170" rx="8" fill="#26233a"/><rect x="30" y="25" width="150" height="120" rx="14" fill="#1e1e2e"/><rect x="40" y="35" width="130" height="18" rx="9" fill="#313244"/><rect x="40" y="62" width="130" height="18" rx="6" fill="#45365e"/><rect x="40" y="84" width="130" height="18" rx="6" fill="#1e1e2e"/><rect x="40" y="106" width="130" height="18" rx="6" fill="#1e1e2e"/><text x="105" y="190" fill="#a6adc8" text-anchor="middle">spotlight</text></g><g transform="translate(225 5)"><rect width="210" height="170" rx="8" fill="#1e1e2edd"/><rect x="50" y="15" width="110" height="16" rx="8" fill="#313244"/><g fill="#cba6f7"><rect x="30" y="45" width="26" height="26" rx="8"/><rect x="70" y="45" width="26" height="26" rx="8" fill="#89b4fa"/><rect x="110" y="45" width="26" height="26" rx="8" fill="#a6e3a1"/><rect x="150" y="45" width="26" height="26" rx="8" fill="#f38ba8"/><rect x="30" y="90" width="26" height="26" rx="8" fill="#fab387"/><rect x="70" y="90" width="26" height="26" rx="8" fill="#94e2d5"/><rect x="110" y="90" width="26" height="26" rx="8" fill="#f9e2af"/></g><text x="105" y="190" fill="#a6adc8" text-anchor="middle">grid</text></g><g transform="translate(445 5)"><rect width="210" height="170" rx="8" fill="#26233a"/><rect x="0" y="0" width="210" height="22" fill="#1e1e2e"/><rect x="6" y="5" width="60" height="12" rx="6" fill="#313244"/><rect x="72" y="5" width="34" height="12" rx="3" fill="#cba6f7"/><text x="112" y="15" fill="#cdd6f4">Files  Fish  Figma</text><text x="105" y="190" fill="#a6adc8" text-anchor="middle">strip (dmenu-style)</text></g></g></svg></div>

<!-- ex:## Assembly -->
::: exercise challenge | Calculator results
When the query starts with `=`, show one result row with the evaluated expression, copied with `wl-copy` on Enter.
--- hint
Only allow digits and `+-*/().%` before evaluating: `/^[\d+\-*/().%\s]+$/.test(expr)`, then `Function("return " + expr)()`.
:::


## Polish checklist

- [ ] Opens in under ~100 ms (use `LazyLoader { loading: true }` to pre-build it).
- [ ] Typing works immediately; arrow keys move the selection without leaving the field.
- [ ] The best match is selected by default; Enter launches it.
- [ ] Matched letters are highlighted.
- [ ] Esc clears the query first, then closes.
- [ ] Opens on the focused monitor.
- [ ] Results animate smoothly as you type ([[ScriptModel]] keeps rows alive).
- [ ] Empty state suggests what to do next.

<!-- ex:## Polish checklist -->
## Practice

::: exercise project | A fourth layout
Add a `"sidebar"` layout: a full-height panel on the left with the search field on top and the list below.
:::

