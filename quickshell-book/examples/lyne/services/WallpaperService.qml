pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io

// The wallpaper library (~/.local/wallpapers by default), the current one,
// and the picker's open state. The shell draws the wallpaper itself.
Singleton {
    id: root

    readonly property string folder: StateService.get("wallpaper.folder", "~/.local/wallpapers").replace(/^~/, Quickshell.env("HOME"))
    readonly property string current: StateService.get("wallpaper.current", "")
    property var files: []
    property bool pickerVisible: false

    function set(path) { StateService.set("wallpaper.current", path); }

    function togglePicker() {
        if (pickerVisible) { pickerVisible = false; return; }
        WindowManagerService.openExclusive("WallpaperPicker", () => { scan.running = true; pickerVisible = true; });
    }

    // every image in the folder (and its sub-folders), sorted by name
    Process {
        id: scan
        running: true
        command: ["sh", "-c", 'find "$1" -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | sort', "sh", root.folder]
        stdout: StdioCollector { onStreamFinished: root.files = text.split("\n").filter(l => l !== "") }
    }

    Connections {
        target: WindowManagerService
        function onCloseRequested(except) { if (except !== "WallpaperPicker") root.pickerVisible = false; }
    }
    onPickerVisibleChanged: pickerVisible ? WindowManagerService.registerOpen("WallpaperPicker") : WindowManagerService.registerClose("WallpaperPicker")

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void { root.set(path); }
        function get(): string { return root.current; }
        function picker(): void { root.togglePicker(); }
    }
}
