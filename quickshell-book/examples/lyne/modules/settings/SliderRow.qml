import QtQuick
import qs.config
import qs.services
import qs.components

// A number in a range:
//   SliderRow { path: "geometry.radius"; from: 0; to: 24; step: 1; unit: " px" }
SettingRow {
    id: root
    property real from: 0
    property real to: 100
    property real step: 1
    property string unit: ""
    property real factor: 1                        // shown value = stored value × factor (e.g. 100 for %)

    Row {
        spacing: Config.spacing
        StyledText {
            width: 56
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.value * root.factor * 100) / 100 + root.unit
            font.pixelSize: Config.fontSizeSmall
            color: Config.subtextColor
        }
        Item {
            width: 180
            height: 26
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Config.surface2Color
                Rectangle {
                    width: parent.width * (root.value - root.from) / (root.to - root.from)
                    height: parent.height
                    radius: 3
                    color: Config.accentColor
                }
            }
            Rectangle {                              // the handle
                x: (parent.width - width) * (root.value - root.from) / (root.to - root.from)
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: Config.textColor
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function setFrom(x) {
                    const raw = root.from + Math.max(0, Math.min(1, x / width)) * (root.to - root.from);
                    StateService.set(root.path, Number((Math.round(raw / root.step) * root.step).toFixed(4)));   // toFixed: no 0.30000000000000004
                }
                onPressed: m => setFrom(m.x)
                onPositionChanged: m => { if (pressed) setFrom(m.x); }
            }
        }
    }
}
