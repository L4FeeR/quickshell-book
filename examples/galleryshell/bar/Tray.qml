import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// System tray that shows the first few icons and folds the rest into a drawer behind a chevron.
Rectangle {
    id: root
    property int maxVisible: 4
    readonly property var items: SystemTray.items.values
    readonly property var shown: items.slice(0, maxVisible)
    readonly property var hidden: items.slice(maxVisible)
    property bool drawerOpen: false

    visible: items.length > 0
    implicitWidth: row.implicitWidth + 12
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    // one tray icon; used both in the bar and in the drawer
    component TrayIcon: Item {
        id: icon
        required property SystemTrayItem modelData
        implicitWidth: 20; implicitHeight: 20
        IconImage {
            anchors.fill: parent
            source: icon.modelData.icon
            asynchronous: true
            scale: iconHover.hovered ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
        HoverHandler { id: iconHover; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: m => {
                if (m.button === Qt.LeftButton && !icon.modelData.onlyMenu) icon.modelData.activate()
                else if (m.button === Qt.MiddleButton) icon.modelData.secondaryActivate()
                else if (icon.modelData.hasMenu) menu.open()
            }
            onWheel: w => icon.modelData.scroll(w.angleDelta.y / 120, false)
        }
        QsMenuAnchor {                                  // the app's own menu, drawn natively
            id: menu
            menu: icon.modelData.menu
            anchor.item: icon
            anchor.edges: Edges.Bottom
            anchor.gravity: Edges.Bottom
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Repeater { model: root.shown; TrayIcon {} }
        Text {
            id: chevron
            visible: root.hidden.length > 0
            text: root.drawerOpen ? "expand_less" : "expand_more"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: "#a6adc8"
            TapHandler { onTapped: root.drawerOpen = !root.drawerOpen }
        }
    }

    PopupWindow {
        visible: root.drawerOpen && root.hidden.length > 0
        anchor.item: chevron
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 10
        implicitWidth: grid.implicitWidth + 20
        implicitHeight: grid.implicitHeight + 20
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            radius: 12; color: "#1e1e2e"; border.color: "#45475a"
            GridLayout {
                id: grid
                anchors.centerIn: parent
                columns: 4; rowSpacing: 10; columnSpacing: 10
                Repeater { model: root.hidden; TrayIcon {} }
            }
        }
    }
}
