import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services
import qs.components

// The performance tab: four rings (CPU, memory, temperature, disk).
Row {
    spacing: Tokens.spacing.large

    Ring { value: SysInfo.cpu; icon: "memory"; label: "CPU"; text: Math.round(SysInfo.cpu * 100) + "%" }
    Ring { value: SysInfo.mem; icon: "memory_alt"; label: "Memory"; text: SysInfo.memUsedGb.toFixed(1) + " / " + Math.round(SysInfo.memTotalGb) + "G" }
    Ring { value: Math.min(1, SysInfo.temp / 100); icon: "thermostat"; label: "Temp"; text: Math.round(SysInfo.temp) + "°C" }
    Ring { value: SysInfo.disk; icon: "hard_drive"; label: "Disk"; text: Math.round(SysInfo.disk * 100) + "%" }

    component Ring: Column {
        id: ring
        property real value
        property string icon
        property string label
        property string text
        property real shown: value
        spacing: Tokens.spacing.small

        Behavior on shown { Anim { type: Anim.SlowSpatial } }

        Item {
            width: 120; height: 120
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Colours.palette.m3surfaceContainerHighest; strokeWidth: 10; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 60; centerY: 60; radiusX: 52; radiusY: 52; startAngle: 135; sweepAngle: 270 }
                }
                ShapePath {
                    strokeColor: ring.value > 0.85 ? Colours.palette.m3error : Colours.palette.m3primary
                    strokeWidth: 10; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 60; centerY: 60; radiusX: 52; radiusY: 52; startAngle: 135; sweepAngle: 270 * Math.min(1, ring.shown) }
                }
            }
            MaterialIcon { anchors.centerIn: parent; text: ring.icon; font.pixelSize: 30; color: Colours.palette.m3primary }
        }
        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: ring.text; font.weight: 600 }
        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: ring.label; color: Colours.palette.m3outline }
    }
}
