pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io

// Idle settings, caffeine, and the actions the idle monitors in shell.qml run.
Singleton {
    id: root

    readonly property int lockTimeout: StateService.get("idle.lockTimeout", 300)   // seconds, 0 = never
    readonly property int dpmsTimeout: StateService.get("idle.dpmsTimeout", 600)
    readonly property bool caffeine: StateService.get("idle.caffeine", false)

    function toggleCaffeine() { StateService.set("idle.caffeine", !caffeine); }
    function lock() { LockService.lock(); }
    function dpmsOff() { Hypr.dpms(false); }
    function dpmsOn() { Hypr.dpms(true); }

    IpcHandler {
        target: "idle"
        function toggleCaffeine(): void { root.toggleCaffeine(); }
    }
}
