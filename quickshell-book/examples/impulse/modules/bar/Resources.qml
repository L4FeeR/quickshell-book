import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Memory and CPU as small rings with an icon inside.
RowLayout {
    spacing: 6

    Repeater {
        model: [["memory", ResourceUsage.memoryUsedPercentage], ["planner_review", ResourceUsage.cpuUsage]]

        CircularProgress {
            id: ring
            required property var modelData
            value: modelData[1]
            size: 24
            MaterialSymbol {
                anchors.centerIn: parent
                text: ring.modelData[0]
                iconSize: 13
                color: Appearance.colors.colOnSecondaryContainer
            }
        }
    }
}
