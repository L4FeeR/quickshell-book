import Quickshell
import Quickshell.Hyprland
import QtQuick

Rectangle {
    id: root
    property int count: 8
    readonly property int active: Hyprland.focusedWorkspace?.id ?? 1

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    Rectangle {                                         // the sliding pill
        readonly property Item target: rep.itemAt(root.active - 1)
        x: row.x + (target?.x ?? 0)
        width: target?.width ?? 0
        height: 10; radius: 5
        anchors.verticalCenter: parent.verticalCenter
        color: "#cba6f7"
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
        Behavior on width { NumberAnimation { duration: 250 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Repeater {
            id: rep
            model: root.count
            Item {
                required property int index
                readonly property int wsId: index + 1
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                width: wsId === root.active ? 24 : 8
                height: 10
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Rectangle {
                    anchors.centerIn: parent
                    visible: parent.wsId !== root.active
                    width: 8; height: 8; radius: 4
                    color: parent.ws?.urgent ? "#f38ba8"
                         : (parent.ws?.toplevels.values.length ?? 0) > 0 ? "#a6adc8" : "#585b70"
                }
                MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: Hyprland.dispatch("workspace " + parent.wsId) }
            }
        }
    }
    WheelHandler { onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1") }
}
