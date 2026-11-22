import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root
    anchors { bottom: true }
    margins.bottom: 140
    implicitWidth: 720; implicitHeight: 120
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom

    readonly property var quotes: [
        ["Simplicity is the soul of efficiency.", "Austin Freeman"],
        ["Talk is cheap. Show me the code.", "Linus Torvalds"],
        ["Make it work, make it right, make it fast.", "Kent Beck"],
        ["The details are not the details. They make the design.", "Charles Eames"],
        ["Less, but better.", "Dieter Rams"],
        ["First, solve the problem. Then, write the code.", "John Johnson"]
    ]
    SystemClock { id: clock; precision: SystemClock.Hours }
    property int offset: 0
    // a new quote every day: days since epoch modulo the list length
    readonly property var q: quotes[(Math.floor(clock.date.getTime() / 86400000) + offset) % quotes.length]

    Item {
        anchors.fill: parent
        Column {
            id: col
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "“" + root.q[0] + "”"
                color: "#cdd6f4"; font.pixelSize: 22; font.italic: true
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 600 } }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "— " + root.q[1]; color: "#a6adc8"; font.pixelSize: 13 }
        }
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.7; shadowOpacity: 0.6 }
        TapHandler { onTapped: root.offset++ }
    }
}
