import QtQuick
import QtQuick.Shapes
import qs.modules.common

// A small ring gauge, used by the bar's resource indicators.
Item {
    id: root

    property real value: 0
    property real size: 26
    property real lineWidth: 2.5
    property color colPrimary: Appearance.colors.colOnSecondaryContainer
    property color colSecondary: Appearance.colors.colSecondaryContainer
    default property alias content: inner.data

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.colSecondary; strokeWidth: root.lineWidth; fillColor: "transparent"
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size / 2 - root.lineWidth; radiusY: radiusX; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: root.colPrimary; strokeWidth: root.lineWidth; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: root.size / 2; centerY: root.size / 2; radiusX: root.size / 2 - root.lineWidth; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * Math.min(1, root.value) }
        }
    }
    Item { id: inner; anchors.fill: parent }
}
