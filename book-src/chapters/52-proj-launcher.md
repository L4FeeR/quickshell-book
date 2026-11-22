# Project: App Launcher

A keyboard-driven launcher that replaces rofi: fuzzy search over installed apps, sorted by how often you use them, with extra modes (`=` calculator, `>` run command, `:` emoji, `?` web search), desktop-action support (e.g. "New Private Window"), and smooth animations.

## Fuzzy matching

A small scorer that rewards prefix matches, word-start matches and consecutive characters:

```js file="utils/fuzzy.js"
.pragma library

// returns -1 for no match, higher = better
function score(text, query) {
    if (!query) return 1
    text = text.toLowerCase(); query = query.toLowerCase()
    if (text === query) return 1000
    if (text.startsWith(query)) return 800 - text.length
    const idx = text.indexOf(query)
    if (idx >= 0) return (text[idx - 1] === " " || text[idx - 1] === "-" ? 600 : 400) - idx
    // subsequence: every query char appears in order
    let ti = 0, s = 0, streak = 0
    for (const c of query) {
        const found = text.indexOf(c, ti)
        if (found < 0) return -1
        streak = found === ti ? streak + 1 : 0
        s += 10 + streak * 5 - (found - ti)
        ti = found + 1
    }
    return s
}
```

## Usage-frequency service

```qml file="services/Apps.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/fuzzy.js" as Fuzzy

Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay)

    function search(query: string): var {
        return all
            .map(a => {
                const s = Math.max(Fuzzy.score(a.name, query),
                                   Fuzzy.score(a.genericName ?? "", query) - 100,
                                   (a.keywords ?? []).some(k => Fuzzy.score(k, query) > 0) ? 150 : -1)
                return { app: a, score: s < 0 ? -1 : s + (counts.counts[a.id] ?? 0) * 20 }
            })
            .filter(x => x.score >= 0)
            .sort((x, y) => y.score - x.score || x.app.name.localeCompare(y.app.name))
            .slice(0, 60)
            .map(x => x.app)
    }

    function launch(entry: DesktopEntry): void {
        counts.counts = Object.assign({}, counts.counts, { [entry.id]: (counts.counts[entry.id] ?? 0) + 1 })
        if (entry.runInTerminal)
            Quickshell.execDetached([Config.terminal, "-e", ...entry.command])
        else
            Quickshell.execDetached(entry.command)          // detached: survives shell reloads
    }

    FileView {
        path: Quickshell.statePath("app-counts.json")
        onAdapterUpdated: writeAdapter()
        printErrors: false
        JsonAdapter { id: counts; property var counts: ({}) }
    }
}
```

`entry.command` is the parsed `Exec` line (field codes like `%U` removed), safer than splitting `execString` yourself. `entry.execute()` also works; `execDetached` makes the app independent of the shell.

## The launcher window

```qml file="modules/launcher/Launcher.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Scope {
    IpcHandler {
        target: "launcher"
        function toggle(): void { GlobalStates.toggle("launcher") }
        function open(query: string): void { GlobalStates.launcherQuery = query; GlobalStates.open("launcher") }
    }

    LazyLoader {
        active: GlobalStates.launcherOpen

        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            implicitWidth: 640
            implicitHeight: 500
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:launcher"

            HyprlandFocusGrab { windows: [win]; active: true; onCleared: GlobalStates.launcherOpen = false }

            readonly property string query: input.text
            readonly property string mode: query.startsWith("=") ? "calc"
                                         : query.startsWith(">") ? "run"
                                         : query.startsWith("?") ? "web"
                                         : "apps"
            readonly property var results: mode === "apps" ? Apps.search(query) : []

            function close(): void { GlobalStates.launcherOpen = false }
            function accept(): void {
                if (mode === "calc") Quickshell.execDetached(["wl-copy", calcResult.text])
                else if (mode === "run") Quickshell.execDetached(["sh", "-c", query.slice(1)])
                else if (mode === "web") Qt.openUrlExternally("https://duckduckgo.com/?q=" + encodeURIComponent(query.slice(1).trim()))
                else if (list.currentItem) Apps.launch(results[list.currentIndex])
                close()
            }

            StyledRect {
                id: card
                anchors.fill: parent
                anchors.margins: 10
                level: 3
                radius: Appearance.rounding.large
                color: Colors.surface

                // entrance animation
                scale: 0.94; opacity: 0
                Component.onCompleted: { scale = 1; opacity = 1 }
                Behavior on scale { Anim {} }
                Behavior on opacity { Anim { duration: Appearance.anim.fast } }

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    // search field
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 50
                        radius: 25
                        color: Colors.surfaceContainerHigh
                        RowLayout {
                            anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                            spacing: 12
                            MaterialIcon {
                                icon: ({ calc: "calculate", run: "terminal", web: "travel_explore", apps: "search" })[win.mode]
                                color: Colors.primary
                                size: 22
                            }
                            TextInput {
                                id: input
                                Layout.fillWidth: true
                                focus: true
                                text: GlobalStates.launcherQuery
                                color: Colors.onSurface
                                font.family: Appearance.font.family
                                font.pixelSize: Appearance.font.size.large
                                selectionColor: Colors.primary
                                selectedTextColor: Colors.onPrimary
                                clip: true
                                StyledText {
                                    anchors.fill: parent
                                    visible: !parent.text
                                    text: "Search apps   = math   > command   ? web"
                                    color: Colors.outline
                                    font: parent.font
                                }
                                onTextChanged: list.currentIndex = 0
                                Keys.onEscapePressed: win.close()
                                Keys.onReturnPressed: win.accept()
                                Keys.onEnterPressed: win.accept()
                                Keys.onDownPressed: list.incrementCurrentIndex()
                                Keys.onUpPressed: list.decrementCurrentIndex()
                                Keys.onTabPressed: list.incrementCurrentIndex()
                                Keys.onBacktabPressed: list.decrementCurrentIndex()
                                Component.onDestruction: GlobalStates.launcherQuery = ""
                            }
                        }
                    }

                    // calculator (needs libqalculate's `qalc`)
                    StyledText {
                        id: calcResult
                        visible: win.mode === "calc"
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.size.huge
                        font.bold: true
                        color: Colors.primary
                        Process {
                            command: ["qalc", "-t", win.query.slice(1)]
                            running: win.mode === "calc" && win.query.length > 1
                            stdout: StdioCollector { onStreamFinished: calcResult.text = text.trim() }
                        }
                    }

                    StyledText {
                        visible: win.mode === "run" || win.mode === "web"
                        text: win.mode === "run" ? "Run: " + win.query.slice(1) : "Search the web for: " + win.query.slice(1)
                        color: Colors.onSurfaceVariant
                    }

                    // app list
                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: win.mode === "apps"
                        clip: true
                        spacing: 2
                        model: ScriptModel { values: win.results }
                        highlight: Rectangle { radius: Appearance.rounding.normal; color: Colors.secondaryContainer }
                        highlightMoveDuration: 120
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: AppItem {
                            required property DesktopEntry modelData
                            required property int index
                            entry: modelData
                            width: ListView.view.width
                            selected: ListView.isCurrentItem
                            onActivated: { list.currentIndex = index; win.accept() }
                            onHovered: list.currentIndex = index
                        }
                        StyledText {
                            anchors.centerIn: parent
                            visible: list.count === 0
                            text: "No matching apps"
                            color: Colors.outline
                        }
                    }
                }
            }
        }
    }
}
```

## One result row, with desktop actions

```qml file="modules/launcher/AppItem.qml"
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
    signal activated()
    signal hovered()
    implicitHeight: 56

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 12
        IconImage {
            implicitSize: 34
            source: Quickshell.iconPath(root.entry.icon, "application-x-executable")
            asynchronous: true
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                text: root.entry.name
                font.bold: true
                color: root.selected ? Colors.onSecondaryContainer : Colors.onSurface
                Layout.fillWidth: true
            }
            StyledText {
                text: root.entry.comment || root.entry.genericName || ""
                visible: text !== ""
                color: Colors.onSurfaceVariant
                font.pixelSize: Appearance.font.size.small
                Layout.fillWidth: true
            }
        }
        // desktop actions (e.g. "New Window", "New Private Window") shown for the selected row
        Repeater {
            model: root.selected ? root.entry.actions.slice(0, 3) : []
            Rectangle {
                required property DesktopAction modelData
                implicitWidth: actionText.implicitWidth + 16
                implicitHeight: 26
                radius: 13
                color: Colors.surfaceContainerHighest
                StyledText { id: actionText; anchors.centerIn: parent; text: modelData.name; font.pixelSize: Appearance.font.size.small }
                StateLayer { onClicked: { modelData.execute(); GlobalStates.launcherOpen = false } }
            }
        }
    }
    HoverHandler { onHoveredChanged: if (hovered) root.hovered() }
    TapHandler { onTapped: root.activated() }
}
```

## Keybinds

```ini file="hyprland.conf"
bind = SUPER, Space, exec, qs -c myshell ipc call launcher toggle
bind = SUPER, equal, exec, qs -c myshell ipc call launcher open "="     # open in calculator mode
```

(Or a `GlobalShortcut`, as in [[ch:46-state]].)

## Ideas for more modes

| Prefix | Mode | How |
|---|---|---|
| `:` | emoji picker | a bundled JSON of emoji + names, fuzzy search, `wl-copy` |
| `#` | clipboard | `cliphist list` ([[ch:61-proj-clipboard]]) |
| `/` | files | `fd --max-results 50 query ~` via Process |
| `!` | windows | `ToplevelManager.toplevels`, `activate()` |
| `@` | power | lock / logout / reboot entries |

> [!WILD] In the wild
> end-4's launcher ("overview search") combines apps, calculator, web search, commands and clipboard with `fuzzysort`. Caelestia's launcher sorts by frequency, supports actions, and slides out of the bar as a drawer.

## Practice

::: exercise warm | Grid when empty
Show a `GridView` of apps when the query is empty and the list when typing.
--- solution
`visible: query === ""` on the GridView and `visible: query !== ""` on the ListView, sharing the same model.
:::

::: exercise practice | Recent apps
Add a "recent apps" row from the launch-counts file: the top 6 by count.
--- solution
```qml
readonly property var recent: Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 6)
    .map(([id]) => DesktopEntries.byId(id)).filter(e => e)
```
:::

::: exercise challenge | Window switcher mode
Add a `!` prefix mode that lists open windows and focuses the chosen one.
--- hint
When `query.startsWith("!")`, use `ToplevelManager.toplevels.values` filtered by title, and call `activate()` on Enter.
:::
