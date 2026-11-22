import Quickshell.Io
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string mount: "/"
    property real used: 0              // 0..1
    property string free: ""
    property int size: 26

    Process {
        id: df
        command: ["df", "-B1", "--output=pcent,avail", root.mount]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")[1].trim().split(/\s+/)
                root.used = parseInt(l[0]) / 100
                root.free = (parseInt(l[1]) / 1073741824).toFixed(0) + "G free"
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: df.running = true }

    implicitWidth: size; implicitHeight: size
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"; strokeColor: "#45475a"; strokeWidth: 3
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size / 2 - 2; radiusY: radiusX; sweepAngle: 360 }
        }
        ShapePath {
            fillColor: "transparent"; strokeWidth: 3; capStyle: ShapePath.RoundCap
            strokeColor: root.used > 0.9 ? "#f38ba8" : "#f9e2af"
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size / 2 - 2; radiusY: radiusX
                           startAngle: -90; sweepAngle: 360 * root.used }
        }
    }
    Text { anchors.centerIn: parent; text: Math.round(root.used * 100); color: "#cdd6f4"; font.pixelSize: 9; font.bold: true }
    HoverHandler { id: hover }
    Text { visible: hover.hovered; anchors.left: parent.right; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter
           text: root.free; color: "#a6adc8"; font.pixelSize: 11 }
}
