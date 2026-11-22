pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Small shared state for session things: is the screen locked, should idle be ignored.
Singleton {
    id: root
    property bool locked: false
    property bool caffeine: false                    // true = never dim, lock or suspend on idle

    function lock(): void { locked = true }

    IpcHandler {
        target: "session"
        function lock(): void { root.lock() }
        function toggleCaffeine(): void { root.caffeine = !root.caffeine }
    }
}
