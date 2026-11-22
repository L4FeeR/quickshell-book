import QtQuick
import qs.config
import qs.services
import qs.components

// A compact month grid with today highlighted. Scroll to change month.
Column {
    id: root

    property int monthOffset: 0
    readonly property date first: new Date(Time.date.getFullYear(), Time.date.getMonth() + monthOffset, 1)
    readonly property int lead: (first.getDay() + 6) % 7          // Monday-first

    spacing: Tokens.spacing.small

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(root.first, "MMMM yyyy")
        font.weight: 600
    }

    Grid {
        columns: 7
        spacing: 2

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            StyledText {
                required property string modelData
                width: 26
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colours.palette.m3outline
                font.pixelSize: Tokens.font.size.small
            }
        }

        Repeater {
            model: 42

            StyledRect {
                required property int index
                readonly property date day: new Date(root.first.getFullYear(), root.first.getMonth(), index - root.lead + 1)
                readonly property bool inMonth: day.getMonth() === root.first.getMonth()
                readonly property bool today: day.toDateString() === Time.date.toDateString()

                width: 26; height: 20
                radius: Tokens.rounding.full
                color: today ? Colours.palette.m3primary : "transparent"

                StyledText {
                    anchors.centerIn: parent
                    text: parent.day.getDate()
                    font.pixelSize: Tokens.font.size.small
                    color: parent.today ? Colours.palette.m3onPrimary : parent.inMonth ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => root.monthOffset += event.angleDelta.y > 0 ? -1 : 1
    }
}
