import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Numbered workspaces, each showing the icons of the windows on it.
RowLayout {
    id: root
    property var screen: null                              // the bar's screen: show only its monitor's workspaces
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && (!root.monitor || w.monitor === root.monitor))   // id < 0 = special workspaces
        .sort((a, b) => a.id - b.id)
    spacing: 4

    function iconFor(t: var): string {
        const appId = t.wayland?.appId ?? t.lastIpcObject?.class ?? ""
        return Quickshell.iconPath(DesktopEntries.heuristicLookup(appId)?.icon ?? appId, "application-x-executable")
    }

    Repeater {
        model: root.workspaces
        Rectangle {
            id: ws
            required property HyprlandWorkspace modelData
            readonly property var windows: modelData.toplevels.values
            implicitHeight: 26
            implicitWidth: content.implicitWidth + 16
            radius: 9
            color: modelData.focused ? "#cba6f7" : modelData.urgent ? "#f38ba8" : wsHover.hovered ? "#45475a" : "#313244"
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: ws.modelData.name
                    color: ws.modelData.focused ? "#1e1e2e" : "#cdd6f4"
                    font.pixelSize: 12; font.bold: true
                }
                Repeater {
                    model: ws.windows.slice(0, 4)                  // at most four icons per workspace
                    IconImage {
                        required property var modelData
                        implicitSize: 14
                        source: root.iconFor(modelData)
                    }
                }
                Text {
                    visible: ws.windows.length > 4
                    text: "+" + (ws.windows.length - 4)
                    color: ws.modelData.focused ? "#1e1e2e" : "#a6adc8"; font.pixelSize: 10
                }
            }
            HoverHandler { id: wsHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: ws.modelData.activate() }
        }
    }
}
