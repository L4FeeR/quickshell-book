import QtQuick
import qs.config
import qs.services
import qs.components

// The power button at the bottom: opens the session drawer.
StyledRect {
    id: root

    required property ScreenState screenState

    implicitWidth: Tokens.sizes.barInnerWidth - Tokens.padding.small
    implicitHeight: implicitWidth
    radius: Tokens.rounding.full

    MaterialIcon {
        anchors.centerIn: parent
        text: "power_settings_new"
        color: Colours.palette.m3error
        font.bold: true
    }

    StateLayer {
        color: Colours.palette.m3error
        onClicked: root.screenState.session = !root.screenState.session
    }
}
