import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// A Material 3 switch: a pill track with a knob that grows and shows a check when on.
Switch {
    id: root

    implicitWidth: 52
    implicitHeight: 32
    padding: 0

    indicator: StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Colours.palette.m3outline

        StyledRect {
            property real size: root.checked ? 24 : 16
            width: size
            height: size
            radius: size / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 4 : 8
            color: root.checked ? Colours.palette.m3onPrimary : Colours.palette.m3outline

            Behavior on x { Anim { type: Anim.FastSpatial } }
            Behavior on size { Anim { type: Anim.FastSpatial } }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.checked
                text: "check"
                font.pixelSize: 16
                color: Colours.palette.m3primary
            }
        }
    }
    contentItem: Item {}
}
