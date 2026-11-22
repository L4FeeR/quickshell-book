import QtQuick

// Suspend, restart and shut down, each only if this machine allows it.
Row {
    id: root
    required property var theme
    required property var power                          // SDDM's `sddm` object
    spacing: 10

    Repeater {
        model: [
            { label: "Suspend", allowed: root.power.canSuspend, run: () => root.power.suspend() },
            { label: "Restart", allowed: root.power.canReboot, run: () => root.power.reboot() },
            { label: "Shut down", allowed: root.power.canPowerOff, run: () => root.power.powerOff() }
        ]
        Rectangle {
            id: button
            required property var modelData
            visible: modelData.allowed !== false
            width: text.implicitWidth + 32
            height: 36
            radius: 18
            color: mouse.containsMouse ? root.theme.raised : Qt.alpha(root.theme.base, 0.8)
            Text {
                id: text
                anchors.centerIn: parent
                text: button.modelData.label
                color: button.modelData.label === "Shut down" && mouse.containsMouse ? root.theme.error : root.theme.text
                font.family: root.theme.font
                font.pixelSize: 13
            }
            MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.modelData.run() }
        }
    }
}
