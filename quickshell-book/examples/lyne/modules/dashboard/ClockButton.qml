import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

// The clock in the middle of the bar. Click: the dashboard on its first tab.
BarButton {
    id: root

    required property string screenName

    active: DashboardService.visible && DashboardService.screenName === screenName
    onClicked: DashboardService.toggle("", screenName)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    StyledText {
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        color: Config.subtextColor
        font.pixelSize: Config.fontSizeSmall
    }
    StyledText {
        text: Qt.formatDateTime(clock.date, "hh:mm")
        font.pixelSize: Config.fontSizeNormal
        font.bold: true
    }
}
