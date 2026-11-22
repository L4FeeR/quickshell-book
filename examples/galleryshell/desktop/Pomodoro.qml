import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: root
    anchors { top: true; left: true }
    margins { top: 380; left: 90 }
    implicitWidth: 220; implicitHeight: 220
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom

    property int work: 25 * 60
    property int shortBreak: 5 * 60
    property int longBreak: 15 * 60
    property bool onBreak: false
    property int round: 1
    property int length: work
    property int left: work
    property bool running: false

    function next(): void {
        if (!onBreak) { onBreak = true; length = round % 4 === 0 ? longBreak : shortBreak }
        else { onBreak = false; round++; length = work }
        left = length
        Quickshell.execDetached(["notify-send", "-u", "critical", "Pomodoro", onBreak ? "Break time ☕" : "Back to focus 🎯"])
    }
    Timer { interval: 1000; repeat: true; running: root.running; onTriggered: { root.left--; if (root.left <= 0) root.next() } }
    IpcHandler { target: "pomodoro"; function toggle(): void { root.running = !root.running } }

    readonly property color tint: onBreak ? "#a6e3a1" : "#f38ba8"

    Rectangle {
        anchors.fill: parent
        radius: 28; color: "#e61e1e2e"
        Shape {
            anchors.centerIn: parent; anchors.verticalCenterOffset: -8
            width: 150; height: 150
            preferredRendererType: Shape.CurveRenderer
            ShapePath { fillColor: "transparent"; strokeColor: "#313244"; strokeWidth: 10
                PathAngleArc { centerX: 75; centerY: 75; radiusX: 64; radiusY: 64; sweepAngle: 360 } }
            ShapePath { fillColor: "transparent"; strokeColor: root.tint; strokeWidth: 10; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: 75; centerY: 75; radiusX: 64; radiusY: 64; startAngle: -90; sweepAngle: 360 * root.left / root.length } }
            Column {
                anchors.centerIn: parent
                Text { anchors.horizontalCenter: parent.horizontalCenter
                       text: Math.floor(root.left / 60) + ":" + String(root.left % 60).padStart(2, "0")
                       color: "#cdd6f4"; font.pixelSize: 30; font.weight: Font.Black; font.features: ({ "tnum": 1 }) }
                Text { anchors.horizontalCenter: parent.horizontalCenter
                       text: (root.onBreak ? "BREAK" : "FOCUS") + (root.running ? "" : " · paused") + "  #" + root.round
                       color: root.tint; font.pixelSize: 11; font.letterSpacing: 1.2 }
            }
        }
        TapHandler { onTapped: root.running = !root.running }
        TapHandler { acceptedButtons: Qt.RightButton; onTapped: { root.running = false; root.onBreak = false; root.round = 1; root.length = root.work; root.left = root.work } }
    }
}
