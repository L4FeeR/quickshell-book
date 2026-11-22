import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Drag a rectangle on any screen; the region is then screenshotted (or handed to any command).
// A slurp replacement that matches your shell.  qs ipc call region screenshot
Scope {
    id: root
    property bool active: false
    property string mode: "screenshot"                // "screenshot" | "record" | "geometry"

    IpcHandler {
        target: "region"
        function screenshot(): void { root.mode = "screenshot"; root.active = true }
        function record(): void { root.mode = "record"; root.active = true }
        function geometry(): void { root.mode = "geometry"; root.active = true }
    }

    // geometry in grim/slurp format: "X,Y WxH" in global (all-monitors) coordinates
    function finish(x: real, y: real, w: real, h: real): void {
        active = false
        const geo = `${Math.round(x)},${Math.round(y)} ${Math.round(w)}x${Math.round(h)}`
        if (mode === "screenshot")
            Quickshell.execDetached(["sh", "-c", 'sleep 0.2; f="$HOME/Pictures/Screenshots/$(date +%F_%T).png"; mkdir -p "${f%/*}"; grim -g "$1" "$f" && wl-copy < "$f" && notify-send -i "$f" Screenshot "$f"', "sh", geo])
        else if (mode === "record")
            Quickshell.execDetached(["sh", "-c", 'f="$HOME/Videos/$(date +%F_%T).mp4"; mkdir -p "${f%/*}"; wf-recorder -g "$1" -f "$f"', "sh", geo])
        else
            console.log(geo)
    }

    Variants {
        model: root.active ? Quickshell.screens : []
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            property point start: Qt.point(0, 0)
            property point end: Qt.point(0, 0)
            property bool dragging: false
            readonly property rect sel: Qt.rect(Math.min(start.x, end.x), Math.min(start.y, end.y),
                                                Math.abs(end.x - start.x), Math.abs(end.y - start.y))

            // darken everything except the selection: four rectangles around it
            readonly property color shade: "#88000000"
            Rectangle { color: win.shade; x: 0; y: 0; width: parent.width; height: win.dragging ? win.sel.y : parent.height }
            Rectangle { visible: win.dragging; color: win.shade; x: 0; y: win.sel.y + win.sel.height; width: parent.width; height: parent.height - y }
            Rectangle { visible: win.dragging; color: win.shade; x: 0; y: win.sel.y; width: win.sel.x; height: win.sel.height }
            Rectangle { visible: win.dragging; color: win.shade; x: win.sel.x + win.sel.width; y: win.sel.y; width: parent.width - x; height: win.sel.height }

            Rectangle {                                   // the selection outline
                visible: win.dragging
                x: win.sel.x; y: win.sel.y; width: win.sel.width; height: win.sel.height
                color: "transparent"; border.color: "#cba6f7"; border.width: 2
                Rectangle {                               // size label
                    anchors { top: parent.bottom; topMargin: 6; right: parent.right }
                    width: size.implicitWidth + 12; height: 22; radius: 6; color: "#1e1e2e"
                    Text { id: size; anchors.centerIn: parent; text: Math.round(win.sel.width) + " × " + Math.round(win.sel.height); color: "#cdd6f4"; font.pixelSize: 11 }
                }
            }

            Text {
                visible: !win.dragging
                anchors.centerIn: parent
                text: "Drag to select · Esc to cancel"
                color: "white"; font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                focus: true
                Keys.onEscapePressed: root.active = false
                onPressed: m => { win.start = Qt.point(m.x, m.y); win.end = win.start; win.dragging = true }
                onPositionChanged: m => win.end = Qt.point(m.x, m.y)
                onReleased: {
                    win.dragging = false
                    if (win.sel.width < 4 || win.sel.height < 4) { root.active = false; return }   // a click, not a drag
                    // window coordinates + this screen's position = global coordinates
                    root.finish(win.screen.x + win.sel.x, win.screen.y + win.sel.y, win.sel.width, win.sel.height)
                }
            }
        }
    }
}
