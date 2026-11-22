import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// A horizontal battery: the fill shows the level, a bolt appears while charging.
RowLayout {
    id: root

    readonly property UPowerDevice bat: UPower.displayDevice
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
    readonly property bool low: bat.percentage < 0.2 && !charging

    visible: bat.isLaptopBattery
    spacing: 4

    MaterialSymbol { visible: root.charging; text: "bolt"; fill: 1; iconSize: 14; color: Appearance.colors.colOnLayer1 }
    StyledText { text: Math.round(root.bat.percentage * 100); color: root.low ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1 }
    Rectangle {
        implicitWidth: 26; implicitHeight: 12
        radius: 4
        color: Appearance.colors.colLayer2
        Rectangle {
            width: parent.width * root.bat.percentage
            height: parent.height
            radius: parent.radius
            color: root.low ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer
        }
    }
}
