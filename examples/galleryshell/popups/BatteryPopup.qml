import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Battery chip with a details popup: time left, power draw, health, and power profile buttons.
Rectangle {
    id: root
    property bool open: false
    readonly property var bat: UPower.displayDevice
    readonly property real pct: bat?.percentage ?? 0           // 0..1
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
    readonly property bool full: bat?.state === UPowerDeviceState.FullyCharged

    function duration(s: real): string {
        if (s <= 0) return "—"
        const h = Math.floor(s / 3600), m = Math.round(s / 60) % 60
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    visible: bat?.isLaptopBattery ?? false
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: open || hover.hovered ? "#45475a" : "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Text {
            text: root.charging ? "battery_charging_full" : root.pct > 0.9 ? "battery_full" : root.pct > 0.5 ? "battery_5_bar"
                : root.pct > 0.2 ? "battery_3_bar" : "battery_alert"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.charging ? "#a6e3a1" : root.pct <= 0.2 ? "#f38ba8" : "#cdd6f4"
        }
        Text { text: Math.round(root.pct * 100) + "%"; color: "#cdd6f4"; font.pixelSize: 12 }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.open = !root.open }

    component Stat: RowLayout {
        property string icon
        property string label
        property string value
        Layout.fillWidth: true
        Text { text: parent.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: "#a6adc8" }
        Text { Layout.fillWidth: true; text: parent.label; color: "#a6adc8"; font.pixelSize: 12 }
        Text { text: parent.value; color: "#cdd6f4"; font.pixelSize: 12; font.bold: true }
    }

    PopupWindow {
        visible: root.open
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8
        implicitWidth: 290
        implicitHeight: col.implicitHeight + 32
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            radius: 18; color: "#1e1e2e"; border.color: "#313244"
            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 10
                RowLayout {
                    Text { text: Math.round(root.pct * 100) + "%"; color: "#cdd6f4"; font.pixelSize: 30; font.bold: true }
                    Text {
                        Layout.fillWidth: true
                        text: root.full ? "Fully charged" : root.charging ? "Charging" : "On battery"
                        color: "#a6adc8"; font.pixelSize: 13
                    }
                }
                Rectangle {                                       // level bar
                    Layout.fillWidth: true; implicitHeight: 8; radius: 4; color: "#313244"
                    Rectangle {
                        width: parent.width * root.pct; height: parent.height; radius: 4
                        color: root.charging ? "#a6e3a1" : root.pct <= 0.2 ? "#f38ba8" : "#cba6f7"
                    }
                }
                Stat {
                    icon: "schedule"
                    label: root.charging ? "Until full" : "Time left"
                    value: root.duration(root.charging ? root.bat.timeToFull : root.bat.timeToEmpty)
                }
                Stat { icon: "bolt"; label: "Power draw"; value: Math.abs(root.bat?.changeRate ?? 0).toFixed(1) + " W" }
                Stat {
                    icon: "health_metrics"; label: "Health"
                    value: root.bat?.healthSupported ? Math.round(root.bat.healthPercentage) + "%" : "unknown"
                }
                RowLayout {                                       // power profiles
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [
                            { p: PowerProfile.PowerSaver, icon: "eco", t: "Saver" },
                            { p: PowerProfile.Balanced, icon: "balance", t: "Balanced" },
                            { p: PowerProfile.Performance, icon: "speed", t: "Performance" }
                        ]
                        Rectangle {
                            id: prof
                            required property var modelData
                            readonly property bool active: PowerProfiles.profile === modelData.p
                            visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                            Layout.fillWidth: true
                            implicitHeight: 52; radius: 12
                            color: active ? "#cba6f7" : profHover.hovered ? "#45475a" : "#313244"
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text { Layout.alignment: Qt.AlignHCenter; text: prof.modelData.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: prof.active ? "#1e1e2e" : "#cdd6f4" }
                                Text { Layout.alignment: Qt.AlignHCenter; text: prof.modelData.t; font.pixelSize: 10; color: prof.active ? "#1e1e2e" : "#a6adc8" }
                            }
                            HoverHandler { id: profHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: PowerProfiles.profile = prof.modelData.p }
                        }
                    }
                }
            }
        }
    }
}
