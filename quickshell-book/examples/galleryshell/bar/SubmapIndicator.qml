import Quickshell
import Quickshell.Hyprland
import QtQuick

// Shows the active Hyprland submap ("resize", "launch"…). Hidden in the default map.
Rectangle {
    id: root
    property string submap: ""

    Connections {
        target: Hyprland
        // Hyprland sends "submap>>NAME" on entry and "submap>>" when returning to the default map
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "submap") root.submap = event.data
        }
    }

    visible: implicitWidth > 1
    implicitWidth: submap ? label.implicitWidth + 24 : 0
    implicitHeight: 26
    radius: height / 2
    color: "#f9e2af"
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.submap.toUpperCase()
        color: "#1e1e2e"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
    }

    // a gentle pulse so you notice you are not in the default map
    SequentialAnimation on opacity {
        running: root.submap !== ""
        loops: Animation.Infinite
        NumberAnimation { to: 0.65; duration: 700 }
        NumberAnimation { to: 1; duration: 700 }
        onRunningChanged: if (!running) root.opacity = 1
    }
}
