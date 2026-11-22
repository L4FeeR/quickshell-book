import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real radius: 24
    property real borderWidth: 3
    property color fill: "#1e1e2e"
    property real angle: 0
    default property alias content: inner.data

    NumberAnimation on angle { from: 0; to: 360; duration: 4000; loops: Animation.Infinite; running: root.visible }

    Shape {                                               // gradient-filled rounded rect = the border
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: ConicalGradient {
                centerX: root.width / 2; centerY: root.height / 2
                angle: root.angle
                GradientStop { position: 0.00; color: "#cba6f7" }
                GradientStop { position: 0.33; color: "#89b4fa" }
                GradientStop { position: 0.66; color: "#94e2d5" }
                GradientStop { position: 1.00; color: "#cba6f7" }
            }
            PathRectangle { x: 0; y: 0; width: root.width; height: root.height; radius: root.radius }   // Qt 6.8+
        }
    }
    Rectangle {                                           // inner surface
        id: inner
        anchors.fill: parent
        anchors.margins: root.borderWidth
        radius: root.radius - root.borderWidth
        color: root.fill
    }
}
