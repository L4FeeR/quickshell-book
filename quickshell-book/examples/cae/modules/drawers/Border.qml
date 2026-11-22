import QtQuick
import QtQuick.Shapes

// The frame around the screen: the whole window minus a rounded "hole".
// The left side is as wide as the bar, so the bar sits inside the frame.
Shape {
    id: root

    property real thickness: 10
    property real leftThickness: 50     // = bar width
    property real rounding: 25
    property color colour: "black"

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.colour
        strokeWidth: -1
        fillRule: ShapePath.OddEvenFill   // the inner rectangle cuts a hole in the outer one

        PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
        PathRectangle {
            x: root.leftThickness
            y: root.thickness
            width: root.width - root.leftThickness - root.thickness
            height: root.height - root.thickness * 2
            radius: root.rounding
        }
    }
}
