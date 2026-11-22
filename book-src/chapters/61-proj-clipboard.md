# Project: Clipboard Manager

A searchable clipboard history with image previews, built on **cliphist**: open it with a key, type to filter, press Enter to copy an entry back, Delete to remove it, and pin favorites.

## Setup

```bash
sudo pacman -S cliphist wl-clipboard
```

```ini file="hyprland.conf"
exec-once = wl-paste --type text  --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
bind = SUPER, V, exec, qs -c myshell ipc call clipboard toggle
```

`cliphist list` prints `ID<TAB>preview` lines, newest first; `cliphist decode ID` outputs the original content; `cliphist delete` removes an entry (it reads the `ID<TAB>…` line from stdin).

## The service

```qml file="services/Clipboard.qml"
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var entries: []                     // [{ id, text, isImage }]
    property var pinned: pins.items              // list of ids

    function refresh(): void { listProc.running = true }

    function copy(e): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id])
    }
    function remove(e): void {
        delProc.command = ["sh", "-c", 'printf "%s\\t%s" "$1" "$2" | cliphist delete', "sh", e.id, e.text]
        delProc.running = true
    }
    function wipe(): void { Quickshell.execDetached(["cliphist", "wipe"]); entries = [] }
    function togglePin(e): void {
        pins.items = pins.items.includes(e.id) ? pins.items.filter(i => i !== e.id) : [...pins.items, e.id]
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => l).map(l => {
                const tab = l.indexOf("\t")
                const t = l.slice(tab + 1)
                return { id: l.slice(0, tab), text: t, isImage: t.startsWith("[[ binary data") }
            })
        }
    }
    Process { id: delProc; onExited: root.refresh() }

    FileView {
        path: Quickshell.statePath("clipboard-pins.json")
        onAdapterUpdated: writeAdapter()
        printErrors: false
        JsonAdapter { id: pins; property list<string> items: [] }
    }
}
```

## Image previews

cliphist stores images too. Decode one to a temporary file to preview it:

```qml file="modules/clipboard/ImagePreview.qml"
import Quickshell
import Quickshell.Io
import QtQuick

Image {
    id: root
    required property string entryId
    readonly property string tmp: Quickshell.cachePath("clip-" + entryId + ".png")
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: false

    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$(dirname "$2")"; [ -f "$2" ] || cliphist decode "$1" > "$2"', "sh", root.entryId, root.tmp]
        onExited: root.source = "file://" + root.tmp
    }
}
```

## The window

```qml file="modules/clipboard/ClipboardWindow.qml"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.widgets

Scope {
    IpcHandler { target: "clipboard"; function toggle(): void { GlobalStates.toggle("clipboard") } }

    LazyLoader {
        active: GlobalStates.clipboardOpen

        PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === GlobalStates.activeScreen) ?? null
            implicitWidth: 560
            implicitHeight: 600
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell:clipboard"
            HyprlandFocusGrab { windows: [win]; active: true; onCleared: GlobalStates.clipboardOpen = false }

            Component.onCompleted: Clipboard.refresh()

            readonly property var filtered: {
                const q = search.text.toLowerCase()
                const items = Clipboard.entries.filter(e => !q || e.text.toLowerCase().includes(q))
                return [...items.filter(e => Clipboard.pinned.includes(e.id)), ...items.filter(e => !Clipboard.pinned.includes(e.id))]
            }

            function pick(): void {
                const e = filtered[list.currentIndex]
                if (e) Clipboard.copy(e)
                GlobalStates.clipboardOpen = false
            }

            StyledRect {
                anchors.fill: parent
                anchors.margins: 8
                level: 3
                color: Colors.surface

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    RowLayout {
                        TextField {
                            id: search
                            Layout.fillWidth: true
                            placeholderText: "Search clipboard…"
                            focus: true
                            onTextChanged: list.currentIndex = 0
                            Keys.onEscapePressed: GlobalStates.clipboardOpen = false
                            Keys.onReturnPressed: win.pick()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onDeletePressed: { const e = win.filtered[list.currentIndex]; if (e) Clipboard.remove(e) }
                            Keys.onPressed: ev => {
                                if (ev.key === Qt.Key_P && ev.modifiers & Qt.ControlModifier) {
                                    const e = win.filtered[list.currentIndex]; if (e) Clipboard.togglePin(e)
                                    ev.accepted = true
                                }
                            }
                        }
                        IconButton { icon: "delete_sweep"; onClicked: Clipboard.wipe() }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: ScriptModel { values: win.filtered; objectProp: "id" }
                        highlight: Rectangle { radius: Appearance.rounding.normal; color: Colors.secondaryContainer }
                        highlightMoveDuration: 100

                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            implicitHeight: modelData.isImage ? 120 : Math.min(76, txt.implicitHeight + 20)

                            RowLayout {
                                anchors { fill: parent; margins: 10 }
                                spacing: 10
                                MaterialIcon {
                                    visible: Clipboard.pinned.includes(row.modelData.id)
                                    icon: "keep"; size: 16; color: Colors.primary
                                }
                                ImagePreview {
                                    visible: row.modelData.isImage
                                    entryId: row.modelData.id
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    horizontalAlignment: Image.AlignLeft
                                }
                                StyledText {
                                    id: txt
                                    visible: !row.modelData.isImage
                                    Layout.fillWidth: true
                                    text: row.modelData.text
                                    wrapMode: Text.WrapAnywhere
                                    maximumLineCount: 3
                                    textFormat: Text.PlainText              // never interpret clipboard as markup
                                    font.family: Appearance.font.mono
                                    font.pixelSize: Appearance.font.size.small
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: list.currentIndex = row.index
                                onClicked: m => m.button === Qt.RightButton ? Clipboard.togglePin(row.modelData) : win.pick()
                            }
                        }
                    }

                    StyledText {
                        text: "Enter copy · Del remove · Ctrl+P pin · Esc close"
                        color: Colors.outline
                        font.pixelSize: Appearance.font.size.small
                    }
                }
            }
        }
    }
}
```

> [!WARN] Privacy
> Clipboard history stores passwords you copy. Many password managers set a "sensitive" hint; cliphist can be told to skip some content (`wl-paste --watch cliphist -max-items 200 store`). Consider a `wipe` keybind and don't show the history on the lock screen.

## Practice

::: exercise warm | Count in the bar
Show the number of clipboard entries in the bar.
:::

::: exercise practice | Paste action
Add a paste action that copies the entry, closes the picker, then sends <kbd>Ctrl</kbd>+<kbd>V</kbd>.
--- solution
```js
Quickshell.execDetached(["sh", "-c", `cliphist decode ${id} | wl-copy && sleep 0.15 && wtype -M ctrl v -m ctrl`])
```
The short sleep lets focus return to the app first.
:::

::: exercise challenge | Launcher mode
Integrate the clipboard as a `#` mode in the launcher.
:::
