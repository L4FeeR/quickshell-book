import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

Scope {
    property int radius: 18
    property color cornerColor: "black"

    component Corner: Shape {
        id: c
        property int r
        property color tint
        width: r; height: r
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: c.tint; strokeWidth: -1
            startX: 0; startY: 0
            PathLine { x: c.r; y: 0 }
            PathArc { x: 0; y: c.r; radiusX: c.r; radiusY: c.r; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: 0 }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}                                    // never blocks input
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:corners"

            Corner { anchors.top: parent.top; anchors.left: parent.left; r: radius; tint: cornerColor; rotation: 0 }
            Corner { anchors.top: parent.top; anchors.right: parent.right; r: radius; tint: cornerColor; rotation: 90 }
            Corner { anchors.bottom: parent.bottom; anchors.right: parent.right; r: radius; tint: cornerColor; rotation: 180 }
            Corner { anchors.bottom: parent.bottom; anchors.left: parent.left; r: radius; tint: cornerColor; rotation: 270 }
        }
    }
}
