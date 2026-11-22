pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io
import qs.config

// The power menu: a list of actions, each with its own key, and a short
// countdown before the dangerous ones run (any key or click cancels it).
Singleton {
    id: root

    property bool visible: false
    property int selected: 0
    property int countdown: 0                 // seconds left, 0 = not counting
    property int pending: -1                  // action waiting for the countdown

    readonly property int countdownLength: StateService.get("power.countdown", 3)
    readonly property var actions: [
        { id: "lock",     key: "L", label: "Lock",      icon: Icons.lock,    confirm: false, command: [] },
        { id: "suspend",  key: "S", label: "Suspend",   icon: Icons.sleep,   confirm: false, command: ["systemctl", "suspend"] },
        { id: "logout",   key: "E", label: "Log out",   icon: Icons.logout,  confirm: true,  command: [] },
        { id: "reboot",   key: "R", label: "Restart",   icon: Icons.restart, confirm: true,  command: ["systemctl", "reboot"] },
        { id: "shutdown", key: "P", label: "Shut down", icon: Icons.power,   confirm: true,  command: ["systemctl", "poweroff"] }
    ]

    function open() {
        WindowManagerService.openExclusive("Power", () => {
            selected = 0;
            cancel();
            visible = true;
        });
    }
    function close() { cancel(); visible = false; }
    function toggle() { visible ? close() : open(); }

    function run(index) {
        const a = actions[index];
        if (!a)
            return;
        if (a.confirm && countdownLength > 0) {   // start the countdown first
            pending = index;
            selected = index;
            countdown = countdownLength;
            tick.restart();
            return;
        }
        _execute(a);
    }
    function cancel() { tick.stop(); countdown = 0; pending = -1; }

    function _execute(a) {
        visible = false;
        cancel();
        if (a.id === "lock")
            LockService.lock();
        else if (a.id === "logout")
            Hypr.exit();                          // Lua or classic, see Hypr.qml
        else
            Quickshell.execDetached(a.command);
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            if (--root.countdown <= 0)
                root._execute(root.actions[root.pending]);
        }
    }

    Connections {
        target: WindowManagerService
        function onCloseRequested(except) { if (except !== "Power") root.close(); }
    }
    onVisibleChanged: visible ? WindowManagerService.registerOpen("Power") : WindowManagerService.registerClose("Power")

    IpcHandler {
        target: "power"
        function toggle(): void { root.toggle(); }
    }
}
