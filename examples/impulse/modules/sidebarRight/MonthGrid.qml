import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property int offset: 0
    readonly property date first: new Date(DateTime.now.getFullYear(), DateTime.now.getMonth() + offset, 1)
    readonly property int lead: (first.getDay() + 6) % 7

    RowLayout {
        Layout.fillWidth: true
        StyledText { Layout.fillWidth: true; text: Qt.formatDate(root.first, "MMMM yyyy"); font.pixelSize: Appearance.font.pixelSize.large; color: Appearance.colors.colOnLayer1 }
        MaterialSymbol { text: "chevron_left"; TapHandler { onTapped: root.offset-- } }
        MaterialSymbol { text: "chevron_right"; TapHandler { onTapped: root.offset++ } }
    }
    Grid {
        columns: 7
        spacing: 4
        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            StyledText { required property string modelData; width: 40; horizontalAlignment: Text.AlignHCenter; text: modelData; font.weight: 600 }
        }
        Repeater {
            model: 42
            Rectangle {
                required property int index
                readonly property date day: new Date(root.first.getFullYear(), root.first.getMonth(), index - root.lead + 1)
                readonly property bool today: day.toDateString() === DateTime.now.toDateString()
                width: 40; height: 30
                radius: Appearance.rounding.full
                color: today ? Appearance.colors.colPrimary : "transparent"
                StyledText {
                    anchors.centerIn: parent
                    text: parent.day.getDate()
                    color: parent.today ? Appearance.colors.colOnPrimary : parent.day.getMonth() === root.first.getMonth() ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }
            }
        }
    }
}
