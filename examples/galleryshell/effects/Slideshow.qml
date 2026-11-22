import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property int minutes: 15
    property var files: []
    property int index: 0
    readonly property string current: files.length ? "file://" + files[index % files.length] : ""

    Process {
        running: true
        command: ["sh", "-c", `find "$1" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \\) | shuf`, "sh", root.folder]
        stdout: StdioCollector { onStreamFinished: root.files = text.trim().split("\n").filter(f => f) }
    }
    Timer { interval: root.minutes * 60000; running: root.files.length > 1; repeat: true; onTriggered: root.index++ }
    IpcHandler { target: "slideshow"; function next(): void { root.index++ } }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bg
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.layer: WlrLayer.Background

            property bool aOnTop: true
            Connections {
                target: root
                function onCurrentChanged() { (bg.aOnTop ? b : a).source = root.current }   // load into the hidden one
            }
            component Wall: Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; cache: false
                sourceSize: Qt.size(bg.width * bg.modelData.devicePixelRatio, bg.height * bg.modelData.devicePixelRatio)
                Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
            }
            Wall { id: a; opacity: bg.aOnTop ? 1 : 0; onStatusChanged: if (status === Image.Ready && source == root.current) bg.aOnTop = true }
            Wall { id: b; opacity: bg.aOnTop ? 0 : 1; onStatusChanged: if (status === Image.Ready && source == root.current) bg.aOnTop = false }
            Component.onCompleted: a.source = root.current
        }
    }
}
