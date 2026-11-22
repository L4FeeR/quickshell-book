pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Window positions and sizes for the overview, from `hyprctl clients -j`, refreshed on every
// Hyprland event that could move a window.
Singleton {
    id: root

    property var windowList: []
    property var monitors: []

    function refresh(): void {
        clients.running = true;
        mons.running = true;
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland
        function onRawEvent(event: HyprlandEvent): void {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitle", "workspace", "changefloatingmode", "fullscreen"].includes(event.name))
                root.refresh();
        }
    }

    Process {
        id: clients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { onStreamFinished: root.windowList = JSON.parse(text) }
    }
    Process {
        id: mons
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { onStreamFinished: root.monitors = JSON.parse(text) }
    }
}
