import QtQuick
import qs.config

// A thick slider with an icon on the filled part, as in the Quick Settings
// panel. Click or drag to set; scroll to nudge. `moved(v)` reports changes.
Item {
    id: root

    property real value: 0                    // 0..1
    property string icon: ""
    signal moved(real v)
    signal iconClicked

    implicitHeight: 34
    implicitWidth: 240

    Rectangle {                               // track
        anchors.fill: parent
        radius: height / 2
        color: Config.surface1Color

        Rectangle {                           // fill (never narrower than a circle)
            width: Math.max(height, parent.width * Math.min(1, root.value))
            height: parent.height
            radius: height / 2
            color: Config.accentColor
            Behavior on width {
                enabled: !drag.pressed
                NumberAnimation { duration: Config.animDurationShort }
            }
        }
        Glyph {
            x: (parent.height - width) / 2 + 2
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Config.textReverseColor
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.iconClicked() }
        }
        StyledText {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.value * 100) + "%"
            font.pixelSize: Config.fontSizeSmall
            color: Config.subtextColor
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.leftMargin: root.height             // leave the icon clickable
        cursorShape: Qt.PointingHandCursor
        function setFrom(x) { root.moved(Math.max(0, Math.min(1, (x + root.height) / root.width))); }
        onPressed: m => setFrom(m.x)
        onPositionChanged: m => { if (pressed) setFrom(m.x); }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
