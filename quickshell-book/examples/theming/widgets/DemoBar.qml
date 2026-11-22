import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services

// A small bar that uses every colour role, to see a theme at work. It also holds the
// theme controls: previous/next, the light/dark twin, and the picker.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property ShellScreen modelData

        screen: modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: 44
        color: "transparent"
        WlrLayershell.namespace: "theming-bar"

        TRect {
            anchors.fill: parent
            anchors.margins: 6
            anchors.bottomMargin: 0
            radius: 14
            color: Theme.colors.background
            border.width: 1
            border.color: Theme.colors.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // theme name, on a primary-coloured pill
                TRect {
                    implicitWidth: nameRow.implicitWidth + 24
                    implicitHeight: 28
                    radius: 14
                    color: Theme.colors.primary
                    Row {
                        id: nameRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon { text: Theme.dark ? "dark_mode" : "light_mode"; fill: 1; color: Theme.colors.onPrimary }
                        TText { text: Theme.theme.name; color: Theme.colors.onPrimary; font.weight: Font.DemiBold }
                    }
                }
                TText { text: Theme.theme.family; color: Theme.colors.textMuted }

                Item { Layout.fillWidth: true }

                // the accents, on a surface "group"
                TRect {
                    implicitWidth: swatches.implicitWidth + 20
                    implicitHeight: 28
                    radius: 14
                    color: Theme.colors.surfaceHigh
                    Row {
                        id: swatches
                        anchors.centerIn: parent
                        spacing: 6
                        Repeater {
                            model: ["red", "orange", "yellow", "green", "cyan", "blue", "magenta"]
                            TRect { required property string modelData; width: 14; height: 14; radius: 7; color: Theme.colors[modelData] }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                TText {
                    text: Qt.formatTime(clock.date, "hh:mm")
                    color: Theme.colors.text
                    SystemClock { id: clock; precision: SystemClock.Minutes }
                }
                IconButton { icon: "chevron_left"; onClicked: Theme.step(-1) }
                IconButton { icon: "chevron_right"; onClicked: Theme.step(1) }
                IconButton { icon: "contrast"; onClicked: Theme.toggleVariant() }
                IconButton { icon: "palette"; active: Ui.pickerOpen; onClicked: Ui.pickerOpen = !Ui.pickerOpen }
            }
        }
    }
}
