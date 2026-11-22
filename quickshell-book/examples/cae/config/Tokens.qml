pragma Singleton
import Quickshell
import QtQuick
import qs.config

// Design tokens: every size, radius, font and motion value in the shell comes from here.
// The names follow Material 3 (and Caelestia's own token names).
Singleton {
    id: root

    // Two user options scale the tokens live (see the settings app).
    readonly property real r: Config.appearance.roundingScale
    readonly property real speed: Math.max(0.1, Config.appearance.animationSpeed)

    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: Math.round(4 * root.r)
        readonly property int small: Math.round(8 * root.r)
        readonly property int medium: Math.round(12 * root.r)
        readonly property int large: Math.round(16 * root.r)
        readonly property int extraLarge: Math.round(28 * root.r)
        readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int extraLarge: 28
    }

    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int extraLarge: 28
    }

    readonly property QtObject font: QtObject {
        readonly property string sans: Config.appearance.font
        readonly property string mono: "JetBrains Mono"
        readonly property string material: "Material Symbols Rounded"
        readonly property QtObject size: QtObject {
            readonly property int small: 11
            readonly property int smaller: 12
            readonly property int normal: 13
            readonly property int larger: 15
            readonly property int large: 18
            readonly property int extraLarge: 28
        }
    }

    // Material 3 "expressive" motion: cubic-bezier curves for Easing.BezierSpline.
    // Spatial curves overshoot a little (springy); effect curves don't (for opacity and colour).
    readonly property QtObject anim: QtObject {
        readonly property QtObject curves: QtObject {
            readonly property list<real> fastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1]
            readonly property list<real> spatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
            readonly property list<real> slowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
            readonly property list<real> effects: [0.34, 0.80, 0.34, 1.00, 1, 1]
            readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
            readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        }
        readonly property QtObject durations: QtObject {
            readonly property int fastSpatial: Math.round(350 / root.speed)
            readonly property int spatial: Math.round(500 / root.speed)
            readonly property int slowSpatial: Math.round(650 / root.speed)
            readonly property int effects: Math.round(200 / root.speed)
            readonly property int emphasized: Math.round(500 / root.speed)
            readonly property int standard: Math.round(400 / root.speed)
        }
    }

    readonly property QtObject sizes: QtObject {
        readonly property int barInnerWidth: 40
        readonly property int dashboardWidth: 840
        readonly property int launcherWidth: 600
        readonly property int notificationWidth: 400
        readonly property int sessionButton: 64
        readonly property int osdSliderHeight: 160
        readonly property int popoutWidth: 300
    }
}
