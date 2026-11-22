import QtQuick

Rectangle {
    id: root
    width: 34; height: 12; radius: 6
    property real shift: 0
    NumberAnimation on shift { from: 0; to: 1; duration: 3000; loops: Animation.Infinite; running: root.visible }
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Qt.hsla((root.shift + 0.00) % 1, 0.75, 0.75, 1) }
        GradientStop { position: 0.5; color: Qt.hsla((root.shift + 0.33) % 1, 0.75, 0.75, 1) }
        GradientStop { position: 1.0; color: Qt.hsla((root.shift + 0.66) % 1, 0.75, 0.75, 1) }
    }
}
