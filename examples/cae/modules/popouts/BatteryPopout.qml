import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Battery level, time left and the power profile switcher.
ColumnLayout {
    readonly property UPowerDevice bat: UPower.displayDevice
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
    readonly property int secs: charging ? bat.timeToFull : bat.timeToEmpty

    implicitWidth: Tokens.sizes.popoutWidth
    spacing: Tokens.spacing.small

    StyledText {
        text: Math.round(parent.bat.percentage * 100) + "%" + (parent.charging ? " · charging" : "")
        font.pixelSize: Tokens.font.size.large
        font.weight: 500
    }
    StyledText {
        visible: parent.secs > 0
        text: Math.floor(parent.secs / 3600) + "h " + Math.round(parent.secs % 3600 / 60) + "m " + (parent.charging ? "until full" : "left")
        color: Colours.palette.m3onSurfaceVariant
    }

    RowLayout {
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

        Repeater {
            model: [[PowerProfile.PowerSaver, "eco"], [PowerProfile.Balanced, "balance"], [PowerProfile.Performance, "bolt"]]

            IconButton {
                required property var modelData
                icon: modelData[1]
                toggle: true
                checked: PowerProfiles.profile === modelData[0]
                visible: modelData[0] !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                onClicked: PowerProfiles.profile = modelData[0]
            }
        }
    }
}
