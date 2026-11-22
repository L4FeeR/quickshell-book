import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// A whole number with − and + buttons.
SettingRow {
    id: root

    property int from: 0
    property int to: 100
    property int step: 1
    property string unit: ""

    RowLayout {
        spacing: Tokens.spacing.extraSmall

        IconButton {
            icon: "remove"
            size: 34
            onClicked: root.edited(Math.max(root.from, (root.value ?? 0) - root.step))
        }
        StyledText {
            Layout.preferredWidth: 64
            horizontalAlignment: Text.AlignHCenter
            text: (root.value ?? 0) + root.unit
            font.family: Tokens.font.mono
            font.pixelSize: Tokens.font.size.larger
        }
        IconButton {
            icon: "add"
            size: 34
            onClicked: root.edited(Math.min(root.to, (root.value ?? 0) + root.step))
        }
    }
}
