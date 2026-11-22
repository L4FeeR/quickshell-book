import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// Pick a font from the fonts installed on the system. Each entry is drawn in its own font.
SettingRow {
    id: root

    ComboBox {
        id: combo

        implicitWidth: 240
        model: Qt.fontFamilies()
        currentIndex: Math.max(0, model.indexOf(root.value))
        onActivated: index => root.edited(model[index])

        background: StyledRect {
            radius: Tokens.rounding.small
            color: Colours.palette.m3surfaceContainerHighest
        }
        contentItem: StyledText {
            leftPadding: Tokens.padding.medium
            text: combo.displayText
            font.family: combo.displayText
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        delegate: ItemDelegate {
            required property string modelData
            width: combo.width
            contentItem: StyledText { text: parent.modelData; font.family: parent.modelData }
            highlighted: combo.highlightedIndex === index
            required property int index
        }
    }
}
