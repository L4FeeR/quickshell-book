import QtQuick
import QtQuick.Shapes

// The surface behind one drawer: a rounded panel glued to a screen edge, with two concave
// "ears" where it meets the frame, so frame and drawer read as one continuous shape.
// It follows the drawer's wrapper item, so it grows as the drawer slides out.
Shape {
    id: root

    required property Item panel        // the drawer wrapper (its size = the visible part)
    property string edge: "top"         // which frame edge the drawer comes out of
    property real offsetX: 0            // where `panel`'s parent sits inside the window
    property real offsetY: 0
    property real radius: 28            // corners of the panel body
    property real earRadius: 25         // the concave joints (match the frame rounding)
    property color colour: "black"

    readonly property bool horizontal: edge === "top" || edge === "bottom"
    readonly property real along: horizontal ? panel.width : panel.height
    readonly property real depth: horizontal ? panel.height : panel.width
    readonly property real r: Math.max(0, Math.min(earRadius, depth / 2))
    readonly property real cr: Math.max(0, Math.min(radius, depth - r, along / 2))
    // Mirrored edges (bottom, left) draw the same path reflected, which reverses arc direction.
    readonly property bool mirrored: edge === "bottom" || edge === "left"
    readonly property int concave: mirrored ? PathArc.Counterclockwise : PathArc.Clockwise
    readonly property int convex: mirrored ? PathArc.Clockwise : PathArc.Counterclockwise

    // canonical coordinates: u runs along the edge (0 .. along + 2r), v goes into the screen (0 .. depth)
    function px(u: real, v: real): real {
        return edge === "left" ? v : edge === "right" ? width - v : u;
    }
    function py(u: real, v: real): real {
        return edge === "top" ? v : edge === "bottom" ? height - v : u;
    }

    visible: depth > 0.5 && along > 0
    preferredRendererType: Shape.CurveRenderer

    x: offsetX + panel.x - (edge === "left" || edge === "right" ? 0 : r)
    y: offsetY + panel.y - (horizontal ? 0 : r)
    width: horizontal ? along + 2 * r : depth
    height: horizontal ? depth : along + 2 * r

    ShapePath {
        fillColor: root.colour
        strokeWidth: -1
        startX: root.px(0, 0)
        startY: root.py(0, 0)

        // left/top ear: from the frame edge, curving into the panel's side
        PathArc { x: root.px(root.r, root.r); y: root.py(root.r, root.r); radiusX: root.r; radiusY: root.r; direction: root.concave }
        PathLine { x: root.px(root.r, root.depth - root.cr); y: root.py(root.r, root.depth - root.cr) }
        // rounded far corners of the panel body
        PathArc { x: root.px(root.r + root.cr, root.depth); y: root.py(root.r + root.cr, root.depth); radiusX: root.cr; radiusY: root.cr; direction: root.convex }
        PathLine { x: root.px(root.r + root.along - root.cr, root.depth); y: root.py(root.r + root.along - root.cr, root.depth) }
        PathArc { x: root.px(root.r + root.along, root.depth - root.cr); y: root.py(root.r + root.along, root.depth - root.cr); radiusX: root.cr; radiusY: root.cr; direction: root.convex }
        PathLine { x: root.px(root.r + root.along, root.r); y: root.py(root.r + root.along, root.r) }
        // right/bottom ear back to the frame edge
        PathArc { x: root.px(root.along + 2 * root.r, 0); y: root.py(root.along + 2 * root.r, 0); radiusX: root.r; radiusY: root.r; direction: root.concave }
        PathLine { x: root.px(0, 0); y: root.py(0, 0) }
    }
}
