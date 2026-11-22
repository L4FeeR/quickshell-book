pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import qs.services

// The wallpaper list and the current wallpaper. Setting one also regenerates the colour
// scheme with matugen, which rewrites scheme.json; Colours reloads it automatically.
Singleton {
    id: root

    property list<string> list: []
    property alias current: saved.path

    function set(path: string): void {
        saved.path = path;
        Quickshell.execDetached(["matugen", "image", path, "-m", Config.appearance.mode]);
    }

    // regenerate colours for the current wallpaper (e.g. after switching light/dark)
    function regenerate(): void {
        if (current) set(current);
    }

    function rescan(): void {
        scan.running = true;
    }

    Component.onCompleted: rescan()

    Process {
        id: scan
        command: ["sh", "-c", 'find "$1" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | sort', "sh", Config.paths.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: root.list = text.trim().split("\n").filter(f => f)
        }
    }

    FileView {
        path: Colours.stateDir + "/wallpaper.json"
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: saved
            property string path: ""
        }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void { root.set(path) }
        function get(): string { return root.current }
    }
}
