import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

PanelWindow {
    id: root
    anchors { bottom: true; right: true }
    margins { bottom: 80; right: 80 }
    implicitWidth: 380; implicitHeight: 160
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Bottom

    property real cpu: 0
    property real ram: 0
    property var last: null

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: mem; path: "/proc/meminfo" }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            stat.reload(); mem.reload()
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0)
            if (root.last) root.cpu = 1 - (idle - root.last.idle) / Math.max(1, total - root.last.total)
            root.last = { idle, total }
            const t = mem.text()
            const get = k => parseInt((t.match(new RegExp(k + ":\\s+(\\d+)")) ?? [0, 0])[1])
            root.ram = 1 - get("MemAvailable") / Math.max(1, get("MemTotal"))
        }
    }

    component Ring: Item {
        id: ring
        property real value
        property color tint
        property string label
        implicitWidth: 100; implicitHeight: 120
        property real shown: value
        Behavior on shown { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
        Shape {
            width: 90; height: 90; anchors.horizontalCenter: parent.horizontalCenter
            preferredRendererType: Shape.CurveRenderer
            ShapePath { fillColor: "transparent"; strokeColor: "#313244"; strokeWidth: 9
                PathAngleArc { centerX: 45; centerY: 45; radiusX: 38; radiusY: 38; sweepAngle: 360 } }
            ShapePath { fillColor: "transparent"; strokeColor: ring.tint; strokeWidth: 9; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: 45; centerY: 45; radiusX: 38; radiusY: 38; startAngle: -90; sweepAngle: 360 * ring.shown } }
            Text { anchors.centerIn: parent; text: Math.round(ring.value * 100) + "%"; color: "#cdd6f4"; font.pixelSize: 17; font.bold: true }
        }
        Text { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
               text: ring.label; color: "#a6adc8"; font.pixelSize: 11; font.letterSpacing: 1.5 }
    }

    Rectangle {
        anchors.fill: parent
        radius: 24; color: "#cc1e1e2e"
        RowLayout {
            anchors.centerIn: parent
            spacing: 18
            Ring { value: root.cpu; tint: "#cba6f7"; label: "CPU" }
            Ring { value: root.ram; tint: "#94e2d5"; label: "RAM" }
            Ring { visible: UPower.displayDevice.isLaptopBattery; value: UPower.displayDevice.percentage; tint: "#a6e3a1"; label: "BATTERY" }
        }
    }
}
