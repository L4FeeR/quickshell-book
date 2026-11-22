import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// The page list on the left. While searching, each page shows how many settings match.
ColumnLayout {
    id: root

    required property var counts       // matches per page while searching
    spacing: 2

    Repeater {
        model: SettingsState.pages

        StyledRect {
            id: item
            required property var modelData
            required property int index
            readonly property bool active: SettingsState.page === index
            readonly property int count: root.counts[index] ?? 0
            readonly property bool dimmed: SettingsState.query !== "" && count === 0

            Layout.fillWidth: true
            implicitHeight: 52
            radius: Tokens.rounding.full
            color: active ? Colours.palette.m3secondaryContainer : "transparent"
            opacity: dimmed ? 0.4 : 1

            Behavior on opacity { Anim { type: Anim.Effects } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.large
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: item.modelData.icon
                    fill: item.active ? 1 : 0
                    color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    text: item.modelData.label
                    font.weight: item.active ? 600 : 400
                    color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                }
                StyledRect {
                    visible: SettingsState.query !== "" && item.count > 0
                    implicitWidth: Math.max(22, badge.implicitWidth + 10)
                    implicitHeight: 22
                    radius: 11
                    color: Colours.palette.m3primary
                    StyledText { id: badge; anchors.centerIn: parent; text: item.count; color: Colours.palette.m3onPrimary; font.pixelSize: Tokens.font.size.small }
                }
            }
            StateLayer {
                radius: Tokens.rounding.full
                onClicked: SettingsState.page = item.index
            }
        }
    }
}
