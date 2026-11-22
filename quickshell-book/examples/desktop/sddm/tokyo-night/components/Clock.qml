import QtQuick

// Time and date, updated every second.
Column {
    id: root
    required property var theme
    property date now: new Date()
    spacing: 2

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(root.now, root.theme.clockFormat)
        color: root.theme.text
        font.family: root.theme.font
        font.pixelSize: 112
        font.weight: Font.Bold
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(root.now, root.theme.dateFormat)
        color: root.theme.subtext
        font.family: root.theme.font
        font.pixelSize: 20
    }
}
