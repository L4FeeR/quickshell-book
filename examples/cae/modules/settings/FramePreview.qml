import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings
import qs.modules.drawers

// A small live picture of the frame, drawn with the shell's own Border and PanelBg at half size.
// Move the thickness or rounding sliders and it updates immediately.
StyledRect {
    id: root

    readonly property real s: 0.5     // preview scale
    readonly property real t: Config.border.thickness * s
    readonly property real bar: (Tokens.sizes.barInnerWidth + Math.max(Tokens.padding.small, Config.border.thickness) * 2) * s

    Layout.fillWidth: true
    implicitHeight: 230
    radius: Tokens.rounding.large
    color: Colours.palette.m3surfaceContainer
    visible: SettingsState.query === ""

    Item {
        id: screen
        anchors.centerIn: parent
        width: 400
        height: 200
        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.darker(Colours.palette.m3primary, 1.6) }
                GradientStop { position: 1; color: Qt.darker(Colours.palette.m3tertiary, 1.8) }
            }
        }

        Item {
            anchors.fill: parent
            opacity: Colours.surface.a

            Border {
                thickness: root.t
                leftThickness: root.bar
                rounding: Config.border.rounding * root.s
                colour: Qt.alpha(Colours.surface, 1)
            }
            Item {
                id: panels
                x: root.bar; y: root.t
                width: screen.width - root.bar - root.t
                height: screen.height - root.t * 2
                Item { id: dash; x: (panels.width - width) / 2; width: 160; height: 46 }
                Item { id: osd; x: panels.width - width; y: (panels.height - height) / 2; width: 24; height: 70 }
            }
            PanelBg {
                panel: dash; edge: "top"; offsetX: root.bar; offsetY: root.t
                radius: Tokens.rounding.extraLarge * root.s; earRadius: Config.border.rounding * root.s
                colour: Qt.alpha(Colours.surface, 1)
            }
            PanelBg {
                panel: osd; edge: "right"; offsetX: root.bar; offsetY: root.t
                radius: Tokens.rounding.extraLarge * root.s; earRadius: Config.border.rounding * root.s
                colour: Qt.alpha(Colours.surface, 1)
            }
        }
    }
}
