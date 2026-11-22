import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// When you switch workspace, a row of numbered boxes appears briefly in the middle of that screen.
Scope {
    id: root
    property bool shown: false
    readonly property var current: Hyprland.focusedWorkspace
    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.map(w => w.id))

    // don't flash at startup: only react once the shell has settled
    property bool armed: false
    Timer { running: true; interval: 1500; onTriggered: root.armed = true }
    onCurrentChanged: if (armed) { shown = true; hide.restart() }
    Timer { id: hide; interval: 900; onTriggered: root.shown = false }

    LazyLoader {
        active: root.shown
        PanelWindow {
            // on the screen of the focused monitor
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            implicitWidth: row.implicitWidth + 32; implicitHeight: 84
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                anchors.fill: parent
                radius: 24; color: "#e61e1e2e"
                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: root.count
                        Rectangle {
                            id: box
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool active: root.current?.id === wsId
                            readonly property bool used: Hyprland.workspaces.values.some(w => w.id === wsId && w.toplevels.values.length > 0)
                            implicitWidth: active ? 64 : 44; implicitHeight: 52; radius: 14
                            color: active ? "#cba6f7" : used ? "#45475a" : "#313244"
                            Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            Text {
                                anchors.centerIn: parent
                                text: box.wsId
                                color: box.active ? "#1e1e2e" : box.used ? "#cdd6f4" : "#6c7086"
                                font.pixelSize: 18; font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
