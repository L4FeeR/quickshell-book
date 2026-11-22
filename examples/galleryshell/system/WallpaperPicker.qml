import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// A grid of thumbnails from a folder; click one (or Enter) to make it the wallpaper.
// Set `target` to your Wallpaper object to use it; without one, it falls back to swww.
Scope {
    id: root
    property bool open: false
    property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var target: null                         // the Wallpaper object (has set(path) and path)
    property var files: []

    IpcHandler { target: "wallpicker"; function toggle(): void { root.open = !root.open } }

    // list images (newest first); the folder is an argument, not part of the command text
    Process {
        id: scan
        command: ["sh", "-c", 'find "$1" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) -printf "%T@ %p\\n" | sort -rn | cut -d" " -f2-', "sh", root.folder]
        stdout: StdioCollector { onStreamFinished: root.files = text.split("\n").filter(l => l !== "") }
    }
    onOpenChanged: if (open) scan.running = true

    function apply(path: string): void {
        if (target) target.set(path)
        else Quickshell.execDetached(["swww", "img", path, "--transition-type", "grow"])   // fallback
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            anchors.bottom: true
            margins.bottom: 40
            implicitWidth: Math.min(screen.width - 80, 1000); implicitHeight: 300
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                radius: 24; color: "#1e1e2e"; border.color: "#313244"

                Text {
                    visible: root.files.length === 0
                    anchors.centerIn: parent
                    text: "No images in " + root.folder; color: "#6c7086"
                }
                ListView {
                    id: view
                    anchors { fill: parent; margins: 16 }
                    orientation: ListView.Horizontal
                    spacing: 12; clip: true
                    focus: true
                    model: root.files
                    highlightMoveDuration: 150
                    preferredHighlightBegin: width / 2 - 170; preferredHighlightEnd: width / 2 + 170
                    highlightRangeMode: ListView.ApplyRange
                    Component.onCompleted: currentIndex = Math.max(0, root.files.indexOf(root.target?.path ?? ""))
                    Keys.onEscapePressed: root.open = false
                    Keys.onReturnPressed: root.apply(root.files[currentIndex])

                    delegate: Item {
                        id: thumb
                        required property string modelData
                        required property int index
                        readonly property bool current: ListView.isCurrentItem
                        readonly property bool inUse: root.target?.path === modelData
                        width: 340; height: view.height

                        Rectangle {
                            anchors.fill: parent
                            radius: 16; color: "#313244"
                            border.color: thumb.current ? "#cba6f7" : "transparent"; border.width: 3
                            scale: thumb.current ? 1 : 0.94
                            Behavior on scale { NumberAnimation { duration: 150 } }
                            Image {
                                anchors { fill: parent; margins: 3 }
                                source: "file://" + thumb.modelData
                                sourceSize.width: 340                 // thumbnails: decode small, it's much faster
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Rectangle {
                                visible: thumb.inUse
                                anchors { right: parent.right; top: parent.top; margins: 10 }
                                width: 28; height: 28; radius: 14; color: "#cba6f7"
                                Text { anchors.centerIn: parent; text: "check"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#1e1e2e" }
                            }
                        }
                        HoverHandler { onHoveredChanged: if (hovered) view.currentIndex = thumb.index }
                        TapHandler { onTapped: root.apply(thumb.modelData) }
                    }
                }
            }
        }
    }
}
