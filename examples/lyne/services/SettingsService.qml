pragma Singleton
import QtQuick
import Quickshell
import qs.services
import Quickshell.Io

Singleton {
    id: root
    property bool visible: false
    property string page: "appearance"

    function open(p) { if (p) page = p; visible = true; }
    function close() { visible = false; }

    IpcHandler {
        target: "settings"
        function open(page: string): void { root.open(page); }
        function toggle(): void { root.visible ? root.close() : root.open(""); }
    }
}
