import Quickshell
import QtQuick
import QtQuick.Shapes

// A round clock: the time in the middle, the seconds as a ring that fills up every minute.
Item {
    id: root
    property int size: 30
    implicitWidth: size; implicitHeight: size
    SystemClock { id: clock; precision: SystemClock.Seconds }
    readonly property real progress: clock.seconds / 60

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer          // smooth, antialiased arcs
        ShapePath {                                          // the track
            strokeColor: "#313244"; strokeWidth: 3; fillColor: "transparent"
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size / 2 - 2; radiusY: root.size / 2 - 2; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {                                          // the progress
            strokeColor: "#cba6f7"; strokeWidth: 3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2; centerY: root.size / 2
                radiusX: root.size / 2 - 2; radiusY: root.size / 2 - 2
                startAngle: -90                              // 12 o'clock
                sweepAngle: 360 * root.progress
            }
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: -3
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clock.date, "hh"); color: "#cdd6f4"; font.pixelSize: 9; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clock.date, "mm"); color: "#a6adc8"; font.pixelSize: 9 }
    }
}
