import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    spacing: 4
    StyledText { text: DateTime.time; font.pixelSize: Appearance.font.pixelSize.large; color: Appearance.colors.colOnLayer1 }
    StyledText { text: "•"; color: Appearance.colors.colSubtext }
    StyledText { text: DateTime.date; color: Appearance.colors.colOnLayer1 }
}
