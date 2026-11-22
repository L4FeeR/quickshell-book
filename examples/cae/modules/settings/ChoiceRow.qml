import QtQuick
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// One option out of a few, as a segmented button. options: [{ value, label, icon }]
SettingRow {
    id: root

    property var options: []

    Row {
        spacing: 2

        Repeater {
            model: root.options

            StyledRect {
                id: segment

                required property var modelData
                required property int index
                readonly property bool selected: root.value === modelData.value
                readonly property bool first: index === 0
                readonly property bool last: index === root.options.length - 1

                implicitWidth: segRow.implicitWidth + Tokens.padding.large * 2
                implicitHeight: 38
                radius: Tokens.rounding.full
                topLeftRadius: first ? radius : Tokens.rounding.extraSmall
                bottomLeftRadius: first ? radius : Tokens.rounding.extraSmall
                topRightRadius: last ? radius : Tokens.rounding.extraSmall
                bottomRightRadius: last ? radius : Tokens.rounding.extraSmall
                color: selected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest

                Row {
                    id: segRow
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        visible: segment.selected || (segment.modelData.icon ?? "") !== ""
                        text: segment.selected ? "check" : (segment.modelData.icon ?? "")
                        font.pixelSize: 18
                        color: segment.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.modelData.label
                        color: segment.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    }
                }
                StateLayer {
                    onClicked: root.edited(segment.modelData.value)
                }
            }
        }
    }
}
