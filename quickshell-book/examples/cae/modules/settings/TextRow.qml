import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// A short text setting. The value is applied when you press Enter or leave the field.
SettingRow {
    id: root

    property string placeholder: ""

    TextField {
        implicitWidth: 220
        text: root.value ?? ""
        placeholderText: root.placeholder
        placeholderTextColor: Colours.palette.m3outline
        color: Colours.palette.m3onSurface
        font.family: Tokens.font.mono
        selectByMouse: true
        background: StyledRect {
            radius: Tokens.rounding.small
            color: Colours.palette.m3surfaceContainerHighest
            border.width: parent.activeFocus ? 2 : 0
            border.color: Colours.palette.m3primary
        }
        onEditingFinished: if (text !== root.value) root.edited(text)
    }
}
