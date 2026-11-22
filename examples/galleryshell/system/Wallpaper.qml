import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Draws the wallpaper itself (no swww/hyprpaper needed), with a crossfade when it changes.
// The chosen file is remembered in the shell's state folder.
Scope {
    id: root
    property string defaultPath: Quickshell.env("HOME") + "/Pictures/wallpaper.jpg"
    readonly property string path: saved.path || defaultPath

    function set(p: string): void { saved.path = p }

    FileView {
        path: Quickshell.statePath("wallpaper.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()                  // first run: create the file
        JsonAdapter { id: saved; property string path: "" }
    }

    IpcHandler {
        target: "wallpaper"
        function set(p: string): void { root.set(p) }
        function get(): string { return root.path }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:wallpaper"
            color: "#11111b"

            // Two images take turns: the new file loads into the hidden one,
            // and once it's ready the two swap opacity, a 600 ms crossfade.
            property bool showA: true

            component Layer: Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(win.width, win.height)     // decode at screen size, not file size
                Behavior on opacity { NumberAnimation { duration: 600 } }
            }
            Layer {
                id: a
                Component.onCompleted: source = "file://" + root.path    // set once, not bound: see below
                opacity: win.showA ? 1 : 0
                onStatusChanged: if (status === Image.Ready) win.showA = true
            }
            Layer {
                id: b
                opacity: win.showA ? 0 : 1
                onStatusChanged: if (status === Image.Ready) win.showA = false
            }

            Connections {
                target: root
                function onPathChanged(): void {
                    const next = win.showA ? b : a
                    next.source = "file://" + root.path
                }
            }
        }
    }
}
