import Quickshell
import QtQuick
import QtQuick.Layouts

// A date chip for the bar. Click it for a month calendar; scroll the calendar to change month.
Rectangle {
    id: root
    property bool open: false
    property int monthOffset: 0                    // 0 = this month, -1 = last month…
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // the first day of the month being shown
    readonly property date shownMonth: new Date(clock.date.getFullYear(), clock.date.getMonth() + monthOffset, 1)
    // 42 cells (6 weeks), starting on the Monday on or before the 1st
    readonly property var cells: {
        const first = shownMonth
        const lead = (first.getDay() + 6) % 7      // Monday = 0
        const out = []
        for (let i = 0; i < 42; i++)
            out.push(new Date(first.getFullYear(), first.getMonth(), 1 - lead + i))
        return out
    }
    function sameDay(a: date, b: date): bool {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: open ? "#45475a" : hover.hovered ? "#45475a" : "#313244"
    Text { id: label; anchors.centerIn: parent; text: Qt.formatDateTime(clock.date, "ddd d MMM"); color: "#cdd6f4"; font.pixelSize: 12 }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: { root.monthOffset = 0; root.open = !root.open } }

    PopupWindow {
        visible: root.open
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8
        implicitWidth: 280; implicitHeight: 300
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 16; color: "#1e1e2e"; border.color: "#313244"

            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 8
                RowLayout {
                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(root.shownMonth, "MMMM yyyy")
                        color: "#cdd6f4"; font.pixelSize: 15; font.bold: true
                    }
                    Repeater {
                        model: [["chevron_left", -1], ["today", 0], ["chevron_right", 1]]
                        Text {
                            required property var modelData
                            text: modelData[0]; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: "#a6adc8"
                            TapHandler { onTapped: root.monthOffset = parent.modelData[1] === 0 ? 0 : root.monthOffset + parent.modelData[1] }
                        }
                    }
                }
                GridLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    columns: 7; rowSpacing: 2; columnSpacing: 2
                    Repeater {                                           // weekday header
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        Text {
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData; font.pixelSize: 11; font.bold: true
                            color: index >= 5 ? "#f38ba8" : "#6c7086"
                        }
                    }
                    Repeater {
                        model: root.cells
                        Rectangle {
                            id: cell
                            required property var modelData
                            readonly property bool today: root.sameDay(modelData, clock.date)
                            readonly property bool inMonth: modelData.getMonth() === root.shownMonth.getMonth()
                            Layout.fillWidth: true; Layout.fillHeight: true
                            radius: 8
                            color: today ? "#cba6f7" : cellHover.hovered ? "#313244" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: cell.modelData.getDate()
                                font.pixelSize: 12; font.bold: cell.today
                                color: cell.today ? "#1e1e2e" : cell.inMonth ? "#cdd6f4" : "#585b70"
                            }
                            HoverHandler { id: cellHover }
                        }
                    }
                }
            }
            WheelHandler { onWheel: e => root.monthOffset += e.angleDelta.y > 0 ? -1 : 1 }
        }
    }
}
