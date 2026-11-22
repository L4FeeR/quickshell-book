import QtQuick
import QtQuick.Controls
import qs.modules.common

// end-4's universal button: a rounded background that changes on hover/press and a ripple
// that grows from the click point. `toggled` switches to the primary colour.
Button {
    id: root

    property bool toggled: false
    property real buttonRadius: Appearance.rounding.small
    property color colBackground: "transparent"
    property color colBackgroundHover: Appearance.colors.colLayer1Hover
    property color colBackgroundToggled: Appearance.colors.colPrimary
    property color colBackgroundToggledHover: Appearance.colors.colPrimaryHover
    property color colRipple: Appearance.colors.colLayer1Active

    hoverEnabled: true
    padding: 0

    background: Rectangle {
        id: bg
        radius: root.buttonRadius
        clip: true
        color: root.toggled ? (root.hovered ? root.colBackgroundToggledHover : root.colBackgroundToggled)
                            : (root.hovered ? root.colBackgroundHover : root.colBackground)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Rectangle {
            id: ripple
            property real cx: 0
            property real cy: 0
            x: cx - width / 2
            y: cy - height / 2
            width: 0
            height: width
            radius: width / 2
            opacity: 0
            color: root.colRipple
        }
    }

    onPressed: {
        ripple.cx = pressX;
        ripple.cy = pressY;
        rippleAnim.restart();
    }

    ParallelAnimation {
        id: rippleAnim
        NumberAnimation { target: ripple; property: "width"; from: 0; to: Math.hypot(root.width, root.height) * 2; duration: 500; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: ripple; property: "opacity"; to: 0.6; duration: 60 }
            NumberAnimation { target: ripple; property: "opacity"; to: 0; duration: 500 }
        }
    }
}
