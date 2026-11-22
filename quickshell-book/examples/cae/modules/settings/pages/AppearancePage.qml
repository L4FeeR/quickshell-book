import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

// Colours, wallpaper, fonts, shape and motion. Every change is written to Config at once,
// so the shell restyles itself while you move the controls.
SettingsPage {
    title: "Appearance"
    subtitle: "Colours come from your wallpaper. Every change applies instantly."

    Section {
        title: "Colour scheme"

        ChoiceRow {
            icon: "contrast"
            title: "Mode"
            description: "Regenerates the palette from the current wallpaper"
            keywords: "dark light theme"
            value: Config.appearance.mode
            defaultValue: "dark"
            options: [{ value: "dark", label: "Dark", icon: "dark_mode" }, { value: "light", label: "Light", icon: "light_mode" }]
            onEdited: v => { Config.appearance.mode = v; Wallpapers.regenerate(); }
        }
    }

    Section {
        title: "Wallpaper"

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: Tokens.spacing.small
            columnSpacing: Tokens.spacing.small
            visible: SettingsState.query === "" || SettingsState.matches("wallpaper background image")

            Repeater {
                model: Wallpapers.list.slice(0, 24)

                ClippingRectangle {
                    id: thumb
                    required property string modelData
                    readonly property bool current: modelData === Wallpapers.current

                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16
                    radius: current ? Tokens.rounding.large : Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainer
                    border.width: current ? 3 : 0
                    border.color: Colours.palette.m3primary

                    Behavior on radius { Anim { type: Anim.FastSpatial } }

                    Image {
                        anchors.fill: parent
                        source: "file://" + thumb.modelData
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(320, 180)
                        asynchronous: true
                    }
                    StateLayer {
                        color: "white"
                        onClicked: Wallpapers.set(thumb.modelData)
                    }
                }
            }
        }

        TextRow {
            icon: "folder"
            title: "Wallpaper folder"
            description: "Images in this folder (and one level below) appear above and in the launcher"
            value: Config.paths.wallpaperDir
            onEdited: v => { Config.paths.wallpaperDir = v; Wallpapers.rescan(); }
        }
    }

    Section {
        title: "Surfaces"

        SwitchRow {
            icon: "blur_on"
            title: "Transparency"
            description: "See-through frame and drawers (Hyprland blurs behind them)"
            keywords: "blur opacity glass"
            value: Config.appearance.transparency
            defaultValue: false
            onEdited: v => Config.appearance.transparency = v
        }
        SliderRow {
            icon: "opacity"
            title: "Opacity"
            description: "How solid the surfaces are when transparency is on"
            keywords: "transparency alpha"
            from: 0.3; to: 1; stepSize: 0.05
            value: Config.appearance.transparencyBase
            defaultValue: 0.85
            onEdited: v => Config.appearance.transparencyBase = v
        }
    }

    Section {
        title: "Shape and type"

        FontRow {
            icon: "font_download"
            title: "Font"
            description: "Used for all text in the shell"
            keywords: "typeface family"
            value: Config.appearance.font
            defaultValue: "Rubik"
            onEdited: v => Config.appearance.font = v
        }
        SliderRow {
            icon: "rounded_corner"
            title: "Roundness"
            description: "Scales every corner radius (cards, buttons, drawers)"
            keywords: "rounding radius corners"
            from: 0; to: 2; stepSize: 0.1; decimals: 1; unit: "×"
            value: Config.appearance.roundingScale
            defaultValue: 1
            onEdited: v => Config.appearance.roundingScale = v
        }
        SliderRow {
            icon: "animation"
            title: "Animation speed"
            description: "2× makes every animation twice as fast"
            keywords: "motion duration fast slow"
            from: 0.5; to: 3; stepSize: 0.25; decimals: 2; unit: "×"
            value: Config.appearance.animationSpeed
            defaultValue: 1
            onEdited: v => Config.appearance.animationSpeed = v
        }
    }
}
