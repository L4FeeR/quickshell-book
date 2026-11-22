pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which windows are open.
Singleton {
    property bool pickerOpen: false

    IpcHandler {
        target: "picker"
        function toggle(): void { pickerOpen = !pickerOpen }
    }
}
