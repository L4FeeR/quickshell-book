import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Clipboard history from cliphist: type to search, Enter to copy, Delete to remove an entry.
// Needs: cliphist, wl-clipboard, and `exec-once = wl-paste --watch cliphist store` in Hyprland.
Scope {
    id: root
    property bool open: false
    property var entries: []                       // [{ id, text }]
    IpcHandler { target: "clipboard"; function toggle(): void { root.open = !root.open } }

    // `cliphist list` prints "ID<TAB>preview" lines, newest first
    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => l.includes("\t")).map(l => {
                const tab = l.indexOf("\t")
                return { id: l.slice(0, tab), text: l.slice(tab + 1) }
            })
        }
    }
    onOpenChanged: if (open) list.running = true

    // the id and the full line are passed as arguments, never pasted into the shell command
    function copy(e: var): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\t%s" "$1" "$2" | cliphist decode | wl-copy', "sh", e.id, e.text])
        open = false
    }
    function remove(e: var): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\t%s" "$1" "$2" | cliphist delete', "sh", e.id, e.text])
        entries = entries.filter(x => x.id !== e.id)
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            id: win
            implicitWidth: 520; implicitHeight: 460
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            readonly property var shown: root.entries.filter(e => e.text.toLowerCase().includes(search.text.toLowerCase()))

            Rectangle {
                anchors.fill: parent
                radius: 20; color: "#1e1e2e"; border.color: "#313244"
                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 40; radius: 20; color: "#313244"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            Text { text: "content_paste_search"; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: "#a6adc8" }
                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                color: "#cdd6f4"; font.pixelSize: 14; focus: true
                                onTextChanged: view.currentIndex = 0
                                Keys.onEscapePressed: root.open = false
                                Keys.onDownPressed: view.incrementCurrentIndex()
                                Keys.onUpPressed: view.decrementCurrentIndex()
                                Keys.onReturnPressed: if (view.currentItem) root.copy(view.currentItem.modelData)
                                Keys.onDeletePressed: if (view.currentItem) root.remove(view.currentItem.modelData)
                            }
                        }
                    }
                    ListView {
                        id: view
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 4
                        model: win.shown
                        highlightMoveDuration: 100
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            implicitHeight: 40; radius: 10
                            color: ListView.isCurrentItem ? "#45365e" : rowHover.hovered ? "#313244" : "transparent"
                            readonly property bool isImage: modelData.text.startsWith("[[ binary data")
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                Text {
                                    text: row.isImage ? "image" : "notes"
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#6c7086"
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.text
                                    color: "#cdd6f4"; font.pixelSize: 13
                                    elide: Text.ElideRight; maximumLineCount: 1
                                }
                            }
                            HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.copy(row.modelData) }
                        }
                    }
                    Text {
                        text: "↑↓ move   Enter copy   Del remove   Esc close"
                        color: "#6c7086"; font.pixelSize: 11
                    }
                }
            }
        }
    }
}
