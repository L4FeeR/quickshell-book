import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// A number on a slider, with its value shown next to it.
SettingRow {
    id: root

    property real from: 0
    property real to: 1
    property real stepSize: 0.05
    property int decimals: 2
    property string unit: ""

    RowLayout {
        spacing: Tokens.spacing.small

        M3Slider {
            id: slider
            from: root.from
            to: root.to
            stepSize: root.stepSize
            snapMode: Slider.SnapAlways
            value: root.value ?? root.from
            onMoved: root.edited(Number(value.toFixed(root.decimals)))
        }
        StyledText {
            Layout.preferredWidth: 56
            horizontalAlignment: Text.AlignRight
            text: Number(root.value ?? 0).toFixed(root.decimals) + root.unit
            font.family: Tokens.font.mono
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
