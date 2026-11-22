import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real value: sink?.audio?.muted ? 0 : Math.min(1, sink?.audio?.volume ?? 0)
    property bool shown: false
    property bool armed: false

    PwObjectTracker { objects: [root.sink] }
    Timer { interval: 1500; running: true; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { if (root.armed) { root.shown = true; hide.restart() } }
        function onMutedChanged() { if (root.armed) { root.shown = true; hide.restart() } }
    }

    PanelWindow {
        anchors.right: true
        margins.right: 16
        implicitWidth: 60; implicitHeight: 220
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        visible: root.shown || fade.running
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.centerIn: parent
            width: 44; height: 200; radius: 22
            color: "#1e1e2e"; border.color: "#313244"
            opacity: root.shown ? 1 : 0
            x: root.shown ? 0 : 20
            Behavior on opacity { NumberAnimation { id: fade; duration: 200 } }

            Rectangle {                                   // the fill, growing from the bottom
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 6 }
                width: 32; radius: 16
                height: Math.max(width, (parent.height - 12) * root.value)
                color: root.sink?.audio?.muted ? "#585b70" : "#cba6f7"
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 12 }
                text: root.sink?.audio?.muted ? "volume_off" : "volume_up"
                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                color: "#1e1e2e"
            }
        }
    }
}
