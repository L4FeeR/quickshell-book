import QtQuick
import qs.config
import qs.services
import qs.components

// Hours above minutes, so the clock fits a narrow vertical bar.
Column {
    spacing: 0

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "schedule"
        color: Colours.palette.m3tertiary
        bottomPadding: Tokens.spacing.extraSmall
    }

    Repeater {
        model: [Time.format("hh"), Time.format("mm")]

        StyledText {
            required property string modelData
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData
            font.family: Tokens.font.mono
            font.pixelSize: Tokens.font.size.larger
            color: Colours.palette.m3tertiary
        }
    }
}
