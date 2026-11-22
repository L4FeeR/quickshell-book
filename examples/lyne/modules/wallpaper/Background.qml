import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// The wallpaper, drawn by the shell on the background layer of every screen.
// A new wallpaper fades in over the old one.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "lyne_wallpaper"
        color: Config.backgroundColor                     // shown until an image loads

        // two images take turns: the new file loads into the hidden one, which then fades in
        property bool showA: true
        component Layer: Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(win.width, win.height)      // decode at screen size, not file size
            Behavior on opacity { NumberAnimation { duration: Config.animDurationLong * 2 } }
        }
        Layer {
            id: a
            opacity: win.showA ? 1 : 0
            onStatusChanged: if (status === Image.Ready) win.showA = true
        }
        Layer {
            id: b
            opacity: win.showA ? 0 : 1
            onStatusChanged: if (status === Image.Ready) win.showA = false
        }

        function load(path) {
            if (path)
                (showA && a.source.toString() !== "" ? b : a).source = "file://" + path;
        }
        Component.onCompleted: load(WallpaperService.current)
        Connections {
            target: WallpaperService
            function onCurrentChanged() { win.load(WallpaperService.current); }
        }
    }
}
