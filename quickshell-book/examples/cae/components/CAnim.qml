import QtQuick
import qs.config

// Colour animation with the "effects" curve: used by every Behavior on color.
ColorAnimation {
    duration: Tokens.anim.durations.effects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Tokens.anim.curves.effects
}
