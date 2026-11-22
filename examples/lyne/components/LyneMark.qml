import QtQuick
import QtQuick.Shapes
import qs.config

// The rebuild's logo: a line and a dot (lyne-dots' own logo is drawn the
// same way in its LyneLogo.qml). Two numbers drive the animation:
// `lift` raises the dot, `stretch` makes it tall and thin (+) or flat (-).
Item {
    id: root

    property color dotColor: Config.accentColor
    // the line: the same hue as the dot, less saturated and a bit darker
    property color lineColor: Qt.hsla(Math.max(0, dotColor.hslHue), dotColor.hslSaturation * 0.6, dotColor.hslLightness * 0.85, 1)
    property real lift: 0
    property real stretch: 0

    implicitHeight: Config.fontSizeIcon
    implicitWidth: implicitHeight * 1.2

    // drawn in a 120 × 100 box, scaled to fit
    Shape {
        width: 120
        height: 100
        scale: Math.min(root.width / 120, root.height / 100)
        transformOrigin: Item.TopLeft
        x: (root.width - 120 * scale) / 2
        y: (root.height - 100 * scale) / 2
        preferredRendererType: Shape.CurveRenderer

        ShapePath {                                   // the line: an "L" with a soft corner
            fillColor: "transparent"
            strokeColor: root.lineColor
            strokeWidth: 16
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 22
            startY: 14
            PathLine { x: 22; y: 58 }
            PathQuad { x: 50; y: 86; controlX: 22; controlY: 86 }
            PathLine { x: 104; y: 86 }
        }
        ShapePath {                                   // the dot: two half-ellipse arcs
            id: dot
            readonly property real r: 15
            readonly property real rx: r * (1 - root.stretch * 0.5)
            readonly property real ry: r * (1 + root.stretch)
            readonly property real cy: 40 - root.lift
            fillColor: root.dotColor
            strokeColor: "transparent"
            startX: 86 - rx
            startY: cy
            PathArc { x: 86 + dot.rx; y: dot.cy; radiusX: dot.rx; radiusY: dot.ry }
            PathArc { x: 86 - dot.rx; y: dot.cy; radiusX: dot.rx; radiusY: dot.ry }
        }
    }
}
