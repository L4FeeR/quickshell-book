import QtQuick
import qs.config
import qs.services

// The logo at the left of the bar. Click: launcher. Right click: the
// launcher's actions (">"). Middle click: clipboard history (";").
// Hovering makes the dot hop: crouch, leap stretched, land flat, settle.
BarButton {
    id: root

    active: LauncherService.visible
    onClicked: LauncherService.toggle()
    onRightClicked: LauncherService.toggleMode(">")
    onMiddleClicked: LauncherService.toggleMode(";")
    onHoveredChanged: if (hovered && !hop.running) hop.start()

    LyneMark {
        id: mark
        height: Config.fontSizeIcon * 0.8
        width: height * 1.2
        // the dot takes the accent colour; the line is derived from it
        dotColor: Config.accentColor
    }

    SequentialAnimation {
        id: hop
        // anticipation: squash down
        ParallelAnimation {
            NumberAnimation { target: mark; property: "stretch"; to: -0.3; duration: 90; easing.type: Easing.OutQuad }
        }
        // leap: rise, stretched tall
        ParallelAnimation {
            NumberAnimation { target: mark; property: "lift"; to: 26; duration: 220; easing.type: Easing.OutQuad }
            NumberAnimation { target: mark; property: "stretch"; to: 0.25; duration: 120 }
        }
        // fall back down
        ParallelAnimation {
            NumberAnimation { target: mark; property: "lift"; to: 0; duration: 200; easing.type: Easing.InQuad }
            NumberAnimation { target: mark; property: "stretch"; to: 0.15; duration: 200 }
        }
        // impact: flat, then back to round
        NumberAnimation { target: mark; property: "stretch"; to: -0.35; duration: 70 }
        NumberAnimation { target: mark; property: "stretch"; to: 0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 3 }
    }
}
