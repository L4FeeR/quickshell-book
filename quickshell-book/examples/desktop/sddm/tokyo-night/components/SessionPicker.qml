import QtQuick

// The session (Hyprland, Plasma…): a button showing the current one that
// opens a list upward. `currentIndex` is what sddm.login() wants.
Item {
    id: root
    required property var theme
    required property var sessions                     // SDDM's sessionModel
    property int currentIndex: sessions.lastIndex >= 0 ? sessions.lastIndex : 0
    property string currentName: ""
    property bool open: false

    implicitWidth: button.width
    implicitHeight: button.height

    Rectangle {
        id: button
        width: label.implicitWidth + 36
        height: 36
        radius: 18
        color: buttonMouse.containsMouse || root.open ? root.theme.raised : Qt.alpha(root.theme.base, 0.8)
        Text {
            id: label
            anchors.centerIn: parent
            text: (root.currentName || "Session") + "  ▴"
            color: root.theme.text
            font.family: root.theme.font
            font.pixelSize: 13
        }
        MouseArea { id: buttonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.open = !root.open }
    }

    // the list, above the button
    Rectangle {
        visible: root.open
        anchors.bottom: button.top
        anchors.bottomMargin: 8
        width: Math.max(220, button.width)
        height: list.contentHeight + 12
        radius: 14
        color: root.theme.surface
        border.color: root.theme.border

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            model: root.sessions
            interactive: false
            delegate: Rectangle {
                id: entry
                required property int index
                required property string name
                width: ListView.view.width
                height: 34
                radius: 10
                color: entryMouse.containsMouse ? root.theme.raised : "transparent"
                // publish the current session's name
                Binding { target: root; property: "currentName"; value: entry.name; when: entry.index === root.currentIndex }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    text: entry.name
                    color: entry.index === root.currentIndex ? root.theme.accent : root.theme.text
                    font.family: root.theme.font
                    font.pixelSize: 13
                }
                MouseArea {
                    id: entryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.currentIndex = entry.index; root.open = false; }
                }
            }
        }
    }
}
