import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

Scope {
    id: root
    property string dev: "intel_backlight"          // ls /sys/class/backlight
    property real max: 1
    property real cur: 0
    readonly property real value: cur / max
    property bool shown: false
    property bool armed: false

    FileView { path: `/sys/class/backlight/${root.dev}/max_brightness`; onLoaded: root.max = parseInt(text()) }
    FileView {
        path: `/sys/class/backlight/${root.dev}/brightness`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.cur = parseInt(text()); if (root.armed) { root.shown = true; hide.restart() } }
    }
    Timer { interval: 1500; running: true; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1400; onTriggered: root.shown = false }

    PanelWindow {
        anchors.bottom: true
        margins.bottom: 100
        implicitWidth: 140; implicitHeight: 140
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        visible: root.shown || pop.running
        WlrLayershell.layer: WlrLayer.Overlay

        Item {
            anchors.fill: parent
            scale: root.shown ? 1 : 0.6
            opacity: root.shown ? 1 : 0
            Behavior on scale { NumberAnimation { id: pop; duration: 250; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle { anchors.fill: parent; radius: width / 2; color: "#1e1e2e" }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "transparent"; strokeColor: "#313244"; strokeWidth: 10
                    PathAngleArc { centerX: 70; centerY: 70; radiusX: 52; radiusY: 52; sweepAngle: 360 }
                }
                ShapePath {
                    fillColor: "transparent"; strokeColor: "#f9e2af"; strokeWidth: 10; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 70; centerY: 70; radiusX: 52; radiusY: 52; startAngle: -90; sweepAngle: 360 * root.value }
                }
            }
            Column {
                anchors.centerIn: parent
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "light_mode"; font.family: "Material Symbols Rounded"
                       font.pixelSize: 28; color: "#f9e2af" }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.value * 100); color: "#cdd6f4"
                       font.pixelSize: 16; font.bold: true }
            }
        }
    }
}
