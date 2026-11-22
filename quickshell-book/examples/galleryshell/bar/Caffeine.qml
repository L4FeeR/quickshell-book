import Quickshell
import Quickshell.Wayland
import QtQuick

Rectangle {
    id: root
    property bool on: false

    implicitWidth: 32; implicitHeight: 26
    radius: on ? 8 : height / 2
    color: on ? "#cba6f7" : "#313244"
    Behavior on radius { NumberAnimation { duration: 250 } }
    Behavior on color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: "coffee"
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.variableAxes: ({ "FILL": root.on ? 1 : 0 })
        color: root.on ? "#1e1e2e" : "#cdd6f4"
    }
    IdleInhibitor {
        window: root.QsWindow.window          // the bar window this widget is in
        enabled: root.on
    }
    TapHandler { onTapped: root.on = !root.on }
}
