import QtQuick
import QtQuick.Shapes

// One concave corner: a square minus a quarter circle. Used under the bar and at screen corners
// so flat surfaces look like they melt into the screen edge.
Shape {
    id: root

    enum CornerEnum { TopLeft, TopRight, BottomLeft, BottomRight }
    property int corner: RoundCorner.CornerEnum.TopLeft
    property real size: 25
    property color color: "black"

    width: size
    height: size
    preferredRendererType: Shape.CurveRenderer
    // draw the top-left version, then mirror it for the others
    transform: Scale {
        origin.x: root.size / 2
        origin.y: root.size / 2
        xScale: root.corner === RoundCorner.CornerEnum.TopRight || root.corner === RoundCorner.CornerEnum.BottomRight ? -1 : 1
        yScale: root.corner === RoundCorner.CornerEnum.BottomLeft || root.corner === RoundCorner.CornerEnum.BottomRight ? -1 : 1
    }

    ShapePath {
        fillColor: root.color
        strokeWidth: -1
        startX: 0
        startY: 0
        PathLine { x: root.size; y: 0 }
        PathArc { x: 0; y: root.size; radiusX: root.size; radiusY: root.size; direction: PathArc.Counterclockwise }
        PathLine { x: 0; y: 0 }
    }
}
