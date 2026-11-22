pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

// Which panels are open, shared by the whole shell. Holding Super shows workspace numbers.
Singleton {
    id: root

    property bool barOpen: true
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool overviewOpen: false
    property bool sessionOpen: false
    property bool osdVolumeOpen: false
    property bool osdBrightnessOpen: false
    property bool screenLocked: false
    property bool superDown: false

    GlobalShortcut {
        appid: "impulse"
        name: "workspaceNumber"
        description: "Hold to show workspace numbers"
        onPressed: root.superDown = true
        onReleased: root.superDown = false
    }
}
