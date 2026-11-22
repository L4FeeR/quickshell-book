import QtQuick

Rectangle {
    id: root
    property string text: "Click me"
    signal clicked()

    implicitWidth: label.implicitWidth + 40; implicitHeight: 44
    radius: 16
    color: "#313244"
    clip: true                                      // keep the ripple inside (rectangular clip)

    Rectangle {
        id: ripple
        width: 0; height: width; radius: width / 2
        color: "#cdd6f4"; opacity: 0
        x: cx - width / 2; y: cy - height / 2
        property real cx: 0
        property real cy: 0
    }
    ParallelAnimation {
        id: spread
        NumberAnimation { target: ripple; property: "width"; from: 0; to: Math.hypot(root.width, root.height) * 2; duration: 450; easing.type: Easing.OutCubic }
        NumberAnimation { target: ripple; property: "opacity"; from: 0.3; to: 0; duration: 500 }
    }
    Text { id: label; anchors.centerIn: parent; text: root.text; color: "#cdd6f4"; font.bold: true }

    TapHandler {
        onTapped: (point) => {
            ripple.cx = point.position.x
            ripple.cy = point.position.y
            spread.restart()
            root.clicked()
        }
    }
}
