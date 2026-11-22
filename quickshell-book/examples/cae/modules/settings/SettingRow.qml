import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// The base of every setting: icon, title, description, a control on the right, and a reset
// button that appears when the value differs from its default. Rows never write to Config
// themselves: they emit edited(newValue) and the page decides what to do with it.
StyledRect {
    id: root

    property string icon: ""
    property string title: ""
    property string description: ""
    property string keywords: ""            // extra words the search should find
    property var value
    property var defaultValue
    default property alias control: controlSlot.data

    readonly property bool isSettingRow: true
    readonly property bool matches: SettingsState.matches(title, description, keywords)
    readonly property bool isDefault: defaultValue === undefined || JSON.stringify(value) === JSON.stringify(defaultValue)

    signal edited(var value)

    Layout.fillWidth: true
    visible: matches
    implicitHeight: Math.max(64, layout.implicitHeight + Tokens.padding.medium * 2)
    radius: Tokens.rounding.medium
    color: hover.hovered ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer

    HoverHandler { id: hover }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            color: Colours.palette.m3primary
            font.pixelSize: 22
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Tokens.font.size.larger
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.description
                wrapMode: Text.Wrap
                color: Colours.palette.m3onSurfaceVariant
                font.pixelSize: Tokens.font.size.smaller
            }
        }

        Item {
            id: controlSlot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }

        IconButton {
            icon: "restart_alt"
            size: 32
            opacity: root.isDefault ? 0 : 1
            enabled: !root.isDefault
            inactiveColour: "transparent"
            onClicked: root.edited(root.defaultValue)

            Behavior on opacity { Anim { type: Anim.Effects } }
        }
    }
}
