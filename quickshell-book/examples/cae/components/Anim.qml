import QtQuick
import qs.config

// The one NumberAnimation used everywhere. Pick a motion "type"; duration and curve follow the tokens.
NumberAnimation {
    enum Type {
        Spatial,        // things that move or resize (default)
        FastSpatial,    // small, quick moves
        SlowSpatial,    // big panels
        Effects,        // opacity, no overshoot
        Emphasized      // closing / leaving
    }

    property int type: Anim.Spatial

    duration: [Tokens.anim.durations.spatial, Tokens.anim.durations.fastSpatial, Tokens.anim.durations.slowSpatial,
               Tokens.anim.durations.effects, Tokens.anim.durations.emphasized][type]
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [Tokens.anim.curves.spatial, Tokens.anim.curves.fastSpatial, Tokens.anim.curves.slowSpatial,
                         Tokens.anim.curves.effects, Tokens.anim.curves.emphasized][type]
}
