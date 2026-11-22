import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// A keyboard-first app launcher. Matches names, generic names and keywords,
// ranks prefix matches first, and remembers how often you launch each app.
Scope {
    id: root
    property bool open: false
    IpcHandler { target: "launcher"; function toggle(): void { root.open = !root.open } }

    // launch counts, saved between sessions: { "firefox.desktop": 12, … }
    FileView {
        path: Quickshell.statePath("launcher.json")
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()
        JsonAdapter { id: stats; property var counts: ({}) }
    }

    function score(e: var, q: string): int {
        const name = e.name.toLowerCase()
        if (q === "") return 1
        if (name.startsWith(q)) return 100
        if (name.split(/[\s-]/).some(w => w.startsWith(q))) return 60
        if (name.includes(q)) return 40
        if ((e.genericName ?? "").toLowerCase().includes(q)) return 20
        if (e.keywords.some(k => k.toLowerCase().startsWith(q))) return 15
        return 0
    }
    function results(q: string): var {
        q = q.trim().toLowerCase()
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => ({ e, s: score(e, q) + Math.min(30, (stats.counts[e.id] ?? 0) * 3) }))   // frequent apps float up
            .filter(r => r.s > Math.min(30, (stats.counts[r.e.id] ?? 0) * 3))                   // must match the query itself
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .slice(0, 50)
            .map(r => r.e)
    }
    function launch(e: var): void {
        const c = Object.assign({}, stats.counts)        // copy, change, assign: so the adapter notices
        c[e.id] = (c[e.id] ?? 0) + 1
        stats.counts = c
        e.execute()
        open = false
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            id: win
            implicitWidth: 560; implicitHeight: 480
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            readonly property var shown: root.results(search.text)

            Rectangle {
                anchors.fill: parent
                radius: 24; color: "#1e1e2e"; border.color: "#313244"
                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 48; radius: 24; color: "#313244"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                            spacing: 10
                            Text { text: "search"; font.family: "Material Symbols Rounded"; font.pixelSize: 22; color: "#a6adc8" }
                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                color: "#cdd6f4"; font.pixelSize: 16; focus: true
                                onTextChanged: list.currentIndex = 0
                                Keys.onEscapePressed: root.open = false
                                Keys.onDownPressed: list.incrementCurrentIndex()
                                Keys.onUpPressed: list.decrementCurrentIndex()
                                Keys.onTabPressed: list.incrementCurrentIndex()
                                Keys.onReturnPressed: if (win.shown.length) root.launch(win.shown[list.currentIndex])
                                Text {
                                    visible: parent.text === ""
                                    text: "Search apps"; color: "#6c7086"; font.pixelSize: 16
                                }
                            }
                        }
                    }
                    ListView {
                        id: list
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 2
                        model: win.shown
                        highlightMoveDuration: 80
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            implicitHeight: 52; radius: 14
                            color: ListView.isCurrentItem ? "#45365e" : rowHover.hovered ? "#313244" : "transparent"
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                IconImage { implicitSize: 32; source: Quickshell.iconPath(row.modelData.icon, "application-x-executable") }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text { Layout.fillWidth: true; text: row.modelData.name; color: "#cdd6f4"; font.pixelSize: 14; elide: Text.ElideRight }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: row.modelData.comment || row.modelData.genericName
                                        color: "#6c7086"; font.pixelSize: 11; elide: Text.ElideRight
                                    }
                                }
                            }
                            HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.launch(row.modelData) }
                        }
                    }
                }
            }
        }
    }
}
