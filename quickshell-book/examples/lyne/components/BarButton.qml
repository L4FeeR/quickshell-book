import QtQuick
import qs.config

// The base of every clickable thing in the bar: a pill that lights up when
// hovered or active, with left, right and middle click and scroll signals.
//   BarButton { onClicked: …; Glyph { text: Icons.bell } }
Rectangle {
    id: root

    default property alias content: row.data            // what you put inside goes in the row
    property alias spacing: row.spacing
    property bool active: false
    readonly property bool hovered: mouse.containsMouse

    signal clicked
    signal rightClicked
    signal middleClicked
    signal scrolled(int delta)                           // +1 up, -1 down

    implicitWidth: row.implicitWidth + Config.padding * 2
    implicitHeight: Config.barButtonHeight
    radius: height / 2
    color: active || hovered ? Config.surface1Color : Qt.alpha(Config.surface1Color, 0)
    Behavior on color {
        enabled: !Config.themeTransitioning                 // the theme fade animates it already
        ColorAnimation { duration: Config.animDuration }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Config.padding
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => {
            if (m.button === Qt.RightButton)
                root.rightClicked();
            else if (m.button === Qt.MiddleButton)
                root.middleClicked();
            else
                root.clicked();
        }
        onWheel: w => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
