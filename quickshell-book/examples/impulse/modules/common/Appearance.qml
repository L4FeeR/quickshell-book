pragma Singleton
import Quickshell
import QtQuick
import qs.modules.common
import qs.modules.common.functions

// end-4's design system: the raw Material 3 colours (m3colors), "layers" built on top of them
// (colLayer0 = bar/panel background, colLayer1 = cards on it, colLayer2 = controls on cards...),
// rounding, fonts, animation presets and sizes.
Singleton {
    id: root

    property real transparency: Config.options.appearance.transparency ? 0.15 : 0
    readonly property M3Colors m3colors: M3Colors {}

    readonly property QtObject colors: QtObject {
        readonly property color colSubtext: root.m3colors.m3outline
        // layer 0: the bar and panel backgrounds
        readonly property color colLayer0: ColorUtils.transparentize(root.m3colors.m3background, root.transparency)
        readonly property color colOnLayer0: root.m3colors.m3onBackground
        readonly property color colLayer0Border: ColorUtils.mix(root.m3colors.m3outlineVariant, root.m3colors.m3background, 0.4)
        // layer 1: groups and cards sitting on layer 0
        readonly property color colLayer1: root.m3colors.m3surfaceContainerLow
        readonly property color colOnLayer1: root.m3colors.m3onSurfaceVariant
        readonly property color colLayer1Hover: ColorUtils.mix(colLayer1, colOnLayer1, 0.92)
        readonly property color colLayer1Active: ColorUtils.mix(colLayer1, colOnLayer1, 0.85)
        // layer 2: buttons and fields inside cards
        readonly property color colLayer2: root.m3colors.m3surfaceContainer
        readonly property color colOnLayer2: root.m3colors.m3onSurface
        readonly property color colLayer2Hover: ColorUtils.mix(colLayer2, colOnLayer2, 0.90)
        readonly property color colLayer2Active: ColorUtils.mix(colLayer2, colOnLayer2, 0.80)
        // accents
        readonly property color colPrimary: root.m3colors.m3primary
        readonly property color colOnPrimary: root.m3colors.m3onPrimary
        readonly property color colPrimaryHover: ColorUtils.mix(colPrimary, colOnPrimary, 0.87)
        readonly property color colSecondaryContainer: root.m3colors.m3secondaryContainer
        readonly property color colOnSecondaryContainer: root.m3colors.m3onSecondaryContainer
        readonly property color colSecondaryContainerHover: ColorUtils.mix(colSecondaryContainer, colOnSecondaryContainer, 0.90)
        readonly property color colTooltip: root.m3colors.m3inverseSurface
        readonly property color colOnTooltip: root.m3colors.m3inverseOnSurface
        readonly property color colShadow: ColorUtils.transparentize(root.m3colors.m3shadow, 0.7)
    }

    readonly property QtObject rounding: QtObject {
        readonly property int unsharpen: 2
        readonly property int verysmall: 8
        readonly property int small: 12
        readonly property int normal: 17
        readonly property int large: 23
        readonly property int verylarge: 30
        readonly property int full: 9999
        readonly property int screenRounding: large
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string main: "Rubik"
            readonly property string title: "Gabarito"
            readonly property string iconMaterial: "Material Symbols Rounded"
            readonly property string monospace: "JetBrains Mono NF"
        }
        readonly property QtObject pixelSize: QtObject {
            readonly property int smallest: 10
            readonly property int smaller: 12
            readonly property int small: 15
            readonly property int normal: 16
            readonly property int large: 17
            readonly property int larger: 19
            readonly property int huge: 22
            readonly property int title: huge
        }
    }

    // Animation presets. Each one also carries a ready-made NumberAnimation Component, so a
    // Behavior can say: animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    readonly property QtObject animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    }
    readonly property QtObject animation: QtObject {
        readonly property AnimPreset elementMove: AnimPreset { duration: 500; bezierCurve: root.animationCurves.expressiveDefaultSpatial }
        readonly property AnimPreset elementMoveFast: AnimPreset { duration: 200; bezierCurve: root.animationCurves.expressiveEffects }
        readonly property AnimPreset elementMoveSmall: AnimPreset { duration: 350; bezierCurve: root.animationCurves.expressiveFastSpatial }
        readonly property AnimPreset elementMoveEnter: AnimPreset { duration: 400; bezierCurve: root.animationCurves.emphasizedDecel }
        readonly property AnimPreset elementMoveExit: AnimPreset { duration: 200; bezierCurve: root.animationCurves.emphasizedAccel }
    }

    readonly property QtObject sizes: QtObject {
        readonly property real barHeight: 40
        readonly property real hyprlandGapsOut: 5
        readonly property real elevationMargin: 10
        readonly property real sidebarWidth: 460
        readonly property real notificationPopupWidth: 410
        readonly property real osdWidth: 200
        readonly property real workspaceButton: 26
    }

    component AnimPreset: QtObject {
        id: preset
        property int duration: 300
        property list<real> bezierCurve: [0.2, 0, 0, 1, 1, 1]
        readonly property Component numberAnimation: Component {
            NumberAnimation {
                duration: preset.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: preset.bezierCurve
            }
        }
        readonly property Component colorAnimation: Component {
            ColorAnimation {
                duration: preset.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: preset.bezierCurve
            }
        }
    }

    component M3Colors: QtObject {
        property bool darkmode: true
        property color m3background: "#141218"
        property color m3onBackground: "#e6e0e9"
        property color m3surface: "#141218"
        property color m3surfaceContainerLow: "#1d1b20"
        property color m3surfaceContainer: "#211f26"
        property color m3surfaceContainerHigh: "#2b2930"
        property color m3surfaceContainerHighest: "#36343b"
        property color m3onSurface: "#e6e0e9"
        property color m3onSurfaceVariant: "#cac4d0"
        property color m3outline: "#938f99"
        property color m3outlineVariant: "#49454f"
        property color m3primary: "#d0bcff"
        property color m3onPrimary: "#381e72"
        property color m3primaryContainer: "#4f378b"
        property color m3onPrimaryContainer: "#eaddff"
        property color m3secondary: "#ccc2dc"
        property color m3secondaryContainer: "#4a4458"
        property color m3onSecondaryContainer: "#e8def8"
        property color m3tertiary: "#efb8c8"
        property color m3error: "#f2b8b5"
        property color m3onError: "#601410"
        property color m3errorContainer: "#8c1d18"
        property color m3onErrorContainer: "#f9dedc"
        property color m3inverseSurface: "#e6e0e9"
        property color m3inverseOnSurface: "#322f35"
        property color m3shadow: "#000000"
    }
}
