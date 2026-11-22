import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 8

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
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) icon.modelData.activate();
                    else if (icon.modelData.hasMenu) {
                        const p = icon.mapToItem(null, 0, icon.height + 8);
                        icon.modelData.display(icon.QsWindow.window, p.x, p.y);
                    }
                }
            }
        }
    }
}
