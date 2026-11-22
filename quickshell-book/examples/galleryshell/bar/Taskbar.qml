import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property var screen: null                     // set to the bar's screen to show only its windows; null = all
    readonly property var windows: ToplevelManager.toplevels.values
        .filter(t => !root.screen || t.screens.includes(root.screen))

    function iconFor(appId: string): string {
        const entry = DesktopEntries.heuristicLookup(appId)
        return Quickshell.iconPath(entry?.icon ?? appId, "application-x-executable")
    }

    visible: windows.length > 0
    implicitWidth: row.implicitWidth + 8
    implicitHeight: 30
    radius: 10
    color: "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: root.windows
            Rectangle {
                id: btn
                required property var modelData
                implicitWidth: 26; implicitHeight: 26
                radius: 8
                color: modelData.activated ? "#45475a" : btnHover.hovered ? "#3b3d52" : "transparent"
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: root.iconFor(btn.modelData.appId)
                    opacity: btn.modelData.minimized ? 0.4 : 1
                }
                // the active window gets a small bar underneath
                Rectangle {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                    width: btn.modelData.activated ? 12 : 4; height: 3; radius: 2
                    color: btn.modelData.activated ? "#cba6f7" : "#6c7086"
                    Behavior on width { NumberAnimation { duration: 180 } }
                }
                HoverHandler { id: btnHover }
                TapHandler { onTapped: btn.modelData.activate() }
                TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: btn.modelData.close() }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: btn.modelData.minimized = !btn.modelData.minimized
                }
            }
        }
    }
}
