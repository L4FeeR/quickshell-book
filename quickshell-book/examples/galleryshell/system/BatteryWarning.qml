import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Warns once at 15% and again at 5% while discharging; at 3% it suspends the machine.
Scope {
    id: root
    property real warnAt: 0.15
    property real criticalAt: 0.05
    property real suspendAt: 0.03
    readonly property var bat: UPower.displayDevice
    readonly property real pct: bat?.percentage ?? 1
    readonly property bool discharging: UPower.onBattery

    property string level: ""                         // "", "low", "critical": what has been shown already
    property bool bannerOpen: false

    onPctChanged: check()
    onDischargingChanged: { if (!discharging) { level = ""; bannerOpen = false } else check() }

    function check(): void {
        if (!discharging || !(bat?.isLaptopBattery ?? false)) return
        if (pct <= suspendAt) Quickshell.execDetached(["systemctl", "suspend"])
        else if (pct <= criticalAt && level !== "critical") { level = "critical"; bannerOpen = true }
        else if (pct <= warnAt && level === "") {
            level = "low"
            Quickshell.execDetached(["notify-send", "-u", "normal", "-i", "battery-low", "Battery low", Math.round(pct * 100) + "% left"])
        }
    }

    // the critical warning is a banner across the top of every screen
    Variants {
        model: root.bannerOpen ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 64
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                anchors { fill: parent; margins: 8 }
                radius: 16; color: "#f38ba8"
                SequentialAnimation on opacity {             // pulse
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.75; duration: 600 }
                    NumberAnimation { to: 1; duration: 600 }
                }
                RowLayout {
                    anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                    spacing: 12
                    Text { text: "battery_alert"; font.family: "Material Symbols Rounded"; font.pixelSize: 28; color: "#1e1e2e" }
                    Text {
                        Layout.fillWidth: true
                        text: "Battery critical: " + Math.round(root.pct * 100) + "%. Plug in now, the computer will suspend at " + Math.round(root.suspendAt * 100) + "%."
                        color: "#1e1e2e"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight
                    }
                    Text {
                        text: "close"; font.family: "Material Symbols Rounded"; font.pixelSize: 22; color: "#1e1e2e"
                        TapHandler { onTapped: root.bannerOpen = false }
                    }
                }
            }
        }
    }
}
