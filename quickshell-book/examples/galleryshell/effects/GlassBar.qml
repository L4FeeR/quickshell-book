import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 10; right: 10 }
    implicitHeight: 40
    color: "transparent"
    WlrLayershell.namespace: "quickshell:glass"          // matched by the layerrule below
    // compositor-independent alternative where supported:
    BackgroundEffect.blurRegion: Region { item: glass; radius: 14 }

    Rectangle {
        id: glass
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(0.12, 0.12, 0.18, 0.45)           // translucent: the blur shows through
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)             // light rim
        Rectangle {                                      // subtle top highlight
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: parent.height / 2; radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.08) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Text { anchors.centerIn: parent; text: "glass"; color: "white"; font.bold: true }
    }
}
