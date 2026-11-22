import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Volume slider plus a list of output devices to choose from.
ColumnLayout {
    implicitWidth: Tokens.sizes.popoutWidth
    spacing: Tokens.spacing.small

    StyledText {
        text: "Output"
        font.pixelSize: Tokens.font.size.larger
        font.weight: 500
    }

    Repeater {
        model: Audio.sinks

        RowLayout {
            required property PwNode modelData
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: Audio.sink === parent.modelData ? "radio_button_checked" : "radio_button_unchecked"
                color: Audio.sink === parent.modelData ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
            StyledText {
                Layout.fillWidth: true
                text: parent.modelData.description || parent.modelData.name
                elide: Text.ElideRight
            }
            TapHandler { onTapped: Audio.setSink(parent.modelData) }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small

        MaterialIcon {
            text: Audio.icon
            TapHandler { onTapped: Audio.toggleMute() }
        }
        Slider {
            Layout.fillWidth: true
            from: 0; to: 1
            value: Audio.volume
            onMoved: Audio.setVolume(value)
        }
        StyledText { text: Math.round(Audio.volume * 100) + "%" }
    }
}
