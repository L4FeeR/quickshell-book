import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components

// System tray icons in a column. Left click activates, right click shows the app's menu.
StyledRect {
    id: root

    implicitWidth: Tokens.sizes.barInnerWidth
    implicitHeight: column.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: Colours.palette.m3surfaceContainer
    visible: SystemTray.items.values.length > 0

    Column {
        id: column
        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Repeater {
            model: SystemTray.items

            IconImage {
                id: icon
                required property SystemTrayItem modelData
                implicitSize: 18
                source: modelData.icon

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton && !icon.modelData.onlyMenu) {
                            icon.modelData.activate();
                        } else if (icon.modelData.hasMenu) {
                            const p = icon.mapToItem(null, icon.width + Tokens.padding.large, 0);
                            icon.modelData.display(icon.QsWindow.window, p.x, p.y);
                        }
                    }
                }
            }
        }
    }
}
