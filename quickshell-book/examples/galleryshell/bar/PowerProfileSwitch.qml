import Quickshell.Services.UPower
import QtQuick

Rectangle {
    id: root
    readonly property var profiles: PowerProfiles.hasPerformanceProfile
        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        : [PowerProfile.PowerSaver, PowerProfile.Balanced]
    readonly property var icons: ["eco", "balance", "bolt"]
    readonly property int current: profiles.indexOf(PowerProfiles.profile)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    Rectangle {                                    // sliding highlight
        x: 3 + root.current * 36
        anchors.verticalCenter: parent.verticalCenter
        width: 34; height: 20; radius: 10
        color: "#cba6f7"
        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }
    Row {
        id: row
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Repeater {
            model: root.profiles
            Item {
                required property int modelData
                required property int index
                width: 34; height: 20
                Text {
                    anchors.centerIn: parent
                    text: root.icons[index]
                    font.family: "Material Symbols Rounded"; font.pixelSize: 15
                    color: index === root.current ? "#1e1e2e" : "#cdd6f4"
                }
                TapHandler { onTapped: PowerProfiles.profile = parent.modelData }
            }
        }
    }
}
