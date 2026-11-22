import QtQuick

// A row of users with their avatars; the selected one is bigger and has an
// accent ring. Arrow keys or clicks change it. `selectedName` is the login
// name of the selected user.
ListView {
    id: root
    required property var theme
    property string selectedName: ""

    orientation: ListView.Horizontal
    implicitHeight: 150
    implicitWidth: Math.min(count, 5) * 120
    spacing: 12
    clip: true
    interactive: false
    highlightMoveDuration: 200
    currentIndex: model.lastIndex >= 0 ? model.lastIndex : 0
    // keep the selected user in the middle
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: width / 2 - 54
    preferredHighlightEnd: width / 2 + 54

    delegate: Item {
        id: user
        required property int index
        required property string name          // login name
        required property string realName      // full name, may be empty
        required property string icon          // avatar file, may be empty
        readonly property bool current: ListView.isCurrentItem

        width: 108
        height: root.height

        // publish the selected user's name to the list
        Binding { target: root; property: "selectedName"; value: user.name; when: user.current }

        Rectangle {                                    // accent ring + avatar
            id: ring
            anchors.horizontalCenter: parent.horizontalCenter
            y: user.current ? 4 : 16
            width: user.current ? 96 : 72
            height: width
            radius: width / 2
            color: user.current ? root.theme.accent : root.theme.border
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 200 } }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 8
                height: width
                radius: width / 2
                color: root.theme.surface
                clip: true
                Text {                                 // initial, under the picture
                    anchors.centerIn: parent
                    text: (user.realName || user.name).charAt(0).toUpperCase()
                    color: root.theme.text
                    font.family: root.theme.font
                    font.pixelSize: parent.width * 0.42
                    font.weight: Font.Bold
                }
                Image {
                    anchors.fill: parent
                    source: user.icon ? "file://" + user.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: ring.bottom
            anchors.topMargin: 10
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: user.realName || user.name
            color: user.current ? root.theme.text : root.theme.muted
            font.family: root.theme.font
            font.pixelSize: 15
            font.weight: user.current ? Font.DemiBold : Font.Normal
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentIndex = user.index }
    }
}
