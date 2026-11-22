import QtQuick
import QtQuick.Shapes

// A square filled everywhere except a quarter circle. Under a docked bar it
// makes the bar flow into the screen with a curve instead of a hard edge.
//
//   ██████            By default it fills the top-left corner of its box.
//   ████              `mirrored` flips it left-right (for the right side),
//   ██                `flipped` upside down (for a bar at the bottom).
//   █
Shape {
    id: root

    property real size: 15
    property color color: "black"
    property bool mirrored: false
    property bool flipped: false

    width: size
    height: size
    preferredRendererType: Shape.CurveRenderer        // smooth, antialiased curve

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.mirrored ? -1 : 1
        yScale: root.flipped ? -1 : 1
    }

    ShapePath {
        fillColor: root.color
        strokeWidth: -1                                // no outline
        startX: 0
        startY: 0
        PathLine { x: root.size; y: 0 }                // along the top edge
        PathArc {                                      // the curve back to the left edge
            x: 0
            y: root.size
            radiusX: root.size
            radiusY: root.size
            direction: PathArc.Counterclockwise
        }
        PathLine { x: 0; y: 0 }                        // up the left edge, closing the shape
    }
}
