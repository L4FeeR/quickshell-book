pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io
import Quickshell.Hyprland

// Which screen's Quick Settings panel is open, and on which page.
Singleton {
    id: root

    property bool visible: false
    property string screenName: ""
    property string page: "main"              // "main" | "wifi" | "bluetooth" | "sound"

    function toggle(screen) {
        if (visible && screenName === screen) { close(); return; }
        WindowManagerService.openExclusive("QuickSettings", () => {
            screenName = screen;
            page = "main";
            visible = true;
        });
    }
    function close() { visible = false; }
    function openPage(p) { page = p; }

    Connections {
        target: WindowManagerService
        function onCloseRequested(except) { if (except !== "QuickSettings") root.close(); }
    }
    onVisibleChanged: visible ? WindowManagerService.registerOpen("QuickSettings") : WindowManagerService.registerClose("QuickSettings")

    IpcHandler {
        target: "quicksettings"
        function toggle(): void { root.toggle(Hyprland.focusedMonitor?.name ?? Quickshell.screens[0].name); }
    }
}
