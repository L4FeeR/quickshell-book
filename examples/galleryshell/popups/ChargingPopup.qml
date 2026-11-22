import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick

Scope {
    id: root
    property bool shown: false
    property bool lastOnBattery: UPower.onBattery

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            if (root.lastOnBattery && !UPower.onBattery) { root.shown = true; hide.restart() }   // just plugged in
            root.lastOnBattery = UPower.onBattery
        }
    }
    Timer { id: hide; interval: 2200; onTriggered: root.shown = false }

    PanelWindow {
        implicitWidth: 220; implicitHeight: 150
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        visible: root.shown || anim.running
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.centerIn: parent
            width: 180; height: 120; radius: 28; color: "#1e1e2e"
            scale: root.shown ? 1 : 0.8
            opacity: root.shown ? 1 : 0
            Behavior on scale { NumberAnimation { id: anim; duration: 300; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {                                         // battery outline
                id: shell
                x: 50; y: 26; width: 74; height: 38; radius: 9
                color: "transparent"; border.color: "#a6e3a1"; border.width: 3
                Rectangle { x: parent.width; anchors.verticalCenter: parent.verticalCenter; width: 6; height: 14; radius: 2; color: "#a6e3a1" }
                Rectangle {                                     // animated fill
                    x: 5; y: 5; height: parent.height - 10; radius: 4; color: "#a6e3a1"
                    width: 10
                    SequentialAnimation on width {
                        running: root.shown; loops: Animation.Infinite
                        NumberAnimation { from: 6; to: (shell.width - 10) * UPower.displayDevice.percentage; duration: 1100; easing.type: Easing.OutCubic }
                        PauseAnimation { duration: 300 }
                    }
                }
                Text { anchors.centerIn: parent; text: "bolt"; font.family: "Material Symbols Rounded"; font.pixelSize: 22
                       font.variableAxes: ({ "FILL": 1 }); color: "#1e1e2e" }
            }
            Text {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 16 }
                text: "Charging · " + Math.round(UPower.displayDevice.percentage * 100) + "%"
                color: "#cdd6f4"; font.pixelSize: 13; font.bold: true
            }
        }
    }
}
