import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The top bar window, one per monitor. With cornerStyle 0 ("hug") two concave corners hang
// under the bar so it melts into the screen; with auto-hide it slides away until you hover.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barRoot

            required property ShellScreen modelData
            readonly property bool autoHide: Config.options.bar.autoHide.enable
            readonly property bool mustShow: hover.containsMouse || GlobalStates.superDown
            readonly property bool hug: Config.options.bar.cornerStyle === 0
            readonly property bool floating: Config.options.bar.cornerStyle === 1
            readonly property real gap: floating ? Appearance.sizes.hyprlandGapsOut : 0

            screen: modelData
            visible: GlobalStates.barOpen && !GlobalStates.screenLocked
            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
                left: true
                right: true
            }
            implicitHeight: Appearance.sizes.barHeight + gap * 2 + Appearance.rounding.screenRounding
            exclusiveZone: autoHide && !mustShow ? 0 : Appearance.sizes.barHeight + gap
            color: "transparent"
            mask: Region { item: hoverArea }
            WlrLayershell.namespace: "quickshell:bar"

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                // the part that takes input: the bar itself, or a thin strip while hidden
                Item {
                    id: hoverArea
                    anchors.left: parent.left
                    anchors.right: parent.right
                    y: Config.options.bar.bottom ? parent.height - height : 0
                    height: barRoot.autoHide && !barRoot.mustShow ? 2 : Appearance.sizes.barHeight + barRoot.gap * 2
                }

                Item {
                    id: slide
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Appearance.sizes.barHeight + barRoot.gap * 2 + Appearance.rounding.screenRounding
                    // slide out of view when auto-hidden
                    y: (Config.options.bar.bottom ? parent.height - height : 0)
                       + (barRoot.autoHide && !barRoot.mustShow ? (Config.options.bar.bottom ? height : -height) : 0)

                    Behavior on y {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    BarContent {
                        id: content
                        screen: barRoot.modelData
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: barRoot.gap
                        y: Config.options.bar.bottom ? parent.height - height - barRoot.gap : barRoot.gap
                        height: Appearance.sizes.barHeight
                        radius: barRoot.floating ? Appearance.rounding.normal : 0
                    }

                    RoundCorner {
                        visible: barRoot.hug
                        size: Appearance.rounding.screenRounding
                        color: Appearance.colors.colLayer0
                        corner: Config.options.bar.bottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft
                        anchors.left: parent.left
                        y: Config.options.bar.bottom ? content.y - size : content.y + content.height
                    }
                    RoundCorner {
                        visible: barRoot.hug
                        size: Appearance.rounding.screenRounding
                        color: Appearance.colors.colLayer0
                        corner: Config.options.bar.bottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight
                        anchors.right: parent.right
                        y: Config.options.bar.bottom ? content.y - size : content.y + content.height
                    }
                }
            }
        }
    }
}
