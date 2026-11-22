pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import Quickshell.Hyprland

// The dashboard under the clock: open or closed, on which screen, which tab.
Singleton {
    id: root

    property bool visible: false
    property string screenName: ""
    property string tab: "overview"           // "overview" | "media" | "system"
    readonly property var tabs: ["overview", "media", "system"]

    function focusedScreen() { return Hyprland.focusedMonitor?.name ?? ""; }

    // toggle("media", "DP-1"): opens on that tab; again on the same tab closes
    function toggle(t, screen) {
        if (visible && screenName === screen && (t === "" || t === tab)) { close(); return; }
        WindowManagerService.openExclusive("Dashboard", () => {
            screenName = screen;
            if (t !== "")
                tab = t;
            visible = true;
        });
    }
    function close() { visible = false; }

    Connections {
        target: WindowManagerService
        function onCloseRequested(except) { if (except !== "Dashboard") root.close(); }
    }
    onVisibleChanged: visible ? WindowManagerService.registerOpen("Dashboard") : WindowManagerService.registerClose("Dashboard")

    IpcHandler {
        target: "dashboard"
        function toggle(tab: string): void { root.toggle(tab, root.focusedScreen() || Quickshell.screens[0].name); }
    }
}
