import QtQuick

Rectangle {
    id: root
    property string icon: "wifi"
    property string label: "Home-5G"
    readonly property bool open: hover.hovered

    implicitWidth: open ? row.implicitWidth + 18 : 28
    implicitHeight: 28
    radius: height / 2
    color: open ? "#45475a" : "transparent"
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 160 } }

    Row {
        id: row
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text { text: root.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: "#cdd6f4"
               font.variableAxes: ({ "FILL": root.open ? 1 : 0 }) }
        Text {
            text: root.label; color: "#cdd6f4"; font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
    HoverHandler { id: hover }
}
