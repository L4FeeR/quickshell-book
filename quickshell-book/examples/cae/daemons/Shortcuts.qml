import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.modules.settings

// Global shortcuts (bind them in Hyprland as `global, cae:<name>`) and IPC for the drawers.
// Both act on the screen that has focus.
Scope {
    id: root

    function toggle(drawer: string): void {
        const s = Visibilities.forFocused();
        if (s && drawer in s) s[drawer] = !s[drawer];
    }

    GShortcut { name: "dashboard"; onPressed: root.toggle("dashboard") }
    GShortcut { name: "launcher"; onPressed: root.toggle("launcher") }
    GShortcut { name: "session"; onPressed: root.toggle("session") }
    GShortcut { name: "sidebar"; onPressed: root.toggle("sidebar") }
    GShortcut { name: "utilities"; onPressed: root.toggle("utilities") }
    GShortcut { name: "settings"; onPressed: Settings.open() }
    GShortcut { name: "showall"; onPressed: { root.toggle("dashboard"); root.toggle("utilities"); root.toggle("osd") } }

    IpcHandler {
        target: "drawers"
        function toggle(drawer: string): void { root.toggle(drawer) }
        function list(): string { return "dashboard launcher session sidebar osd utilities" }
    }

    IpcHandler {
        target: "settings"
        function open(): void { Settings.open() }
    }

    component GShortcut: GlobalShortcut {
        appid: "cae"
    }
}
