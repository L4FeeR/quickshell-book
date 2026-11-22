import QtQuick
import QtQuick.Shapes
import qs.services

// A smooth wave through the spectrum values, drawn as one filled shape.
// Each value is a point; curves between the points make it flow instead
// of looking like steps.
Item {
    id: root

    property color color: "#7aa2f7"
    property real opacityFill: 0.35

    Component.onCompleted: Cava.acquire()
    Component.onDestruction: Cava.release()

    // the points, recomputed every frame: x spread across the width, y from the value
    readonly property var points: {
        const v = Cava.values, n = v.length, pts = [];
        for (let i = 0; i < n; i++)
            pts.push(Qt.point(i / (n - 1) * width, height - (v[i] ?? 0) * height * 0.9));
        return pts;
    }

    // SVG path text: start at the bottom left, curve through every point, close at the bottom right.
    // Each curve's control points sit halfway between two points, which gives a smooth line.
    readonly property string path: {
        const p = points;
        if (p.length < 2)
            return "";
        let d = `M 0 ${height} L ${p[0].x} ${p[0].y}`;
        for (let i = 1; i < p.length; i++) {
            const mx = (p[i - 1].x + p[i].x) / 2;
            d += ` C ${mx} ${p[i - 1].y} ${mx} ${p[i].y} ${p[i].x} ${p[i].y}`;
        }
        return d + ` L ${width} ${height} Z`;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.color
            strokeWidth: 2
            fillColor: Qt.alpha(root.color, root.opacityFill)
            PathSvg { path: root.path }
        }
    }
}
