import QtQuick
import qs.config
import qs.services

// An on/off setting:  SwitchRow { path: "bar.autoHide"; title: "Auto-hide" }
SettingRow {
    id: root
    readonly property bool on: value === true

    Rectangle {
        width: 46
        height: 26
        radius: 13
        color: root.on ? Config.accentColor : Config.surface2Color
        Behavior on color { ColorAnimation { duration: Config.animDuration } }
        Rectangle {
            width: 20
            height: 20
            radius: 10
            y: 3
            x: root.on ? parent.width - width - 3 : 3
            color: root.on ? Config.textReverseColor : Config.textColor
            Behavior on x { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: StateService.set(root.path, !root.on) }
    }
}
