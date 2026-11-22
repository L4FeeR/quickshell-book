import QtQuick
import qs.config
import qs.services
import qs.components

// One of a few values, as a segmented control:
//   ChoiceRow { path: "bar.style"; options: [["docked", "Docked"], ["floating", "Floating"]] }
SettingRow {
    id: root
    property var options: []                       // [[value, label], …]

    Rectangle {
        width: row.implicitWidth + 6
        height: 32
        radius: 16
        color: Config.surface1Color
        Row {
            id: row
            anchors.centerIn: parent
            Repeater {
                model: root.options
                Rectangle {
                    required property var modelData
                    readonly property bool chosen: root.value === modelData[0]
                    width: label.implicitWidth + 22
                    height: 26
                    radius: 13
                    color: chosen ? Config.accentColor : "transparent"
                    StyledText {
                        id: label
                        anchors.centerIn: parent
                        text: parent.modelData[1]
                        font.pixelSize: Config.fontSizeSmall
                        color: parent.chosen ? Config.textReverseColor : Config.textColor
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: StateService.set(root.path, parent.modelData[0]) }
                }
            }
        }
    }
}
