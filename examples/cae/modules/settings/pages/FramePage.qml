import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components
import qs.modules.settings

SettingsPage {
    title: "Frame"
    subtitle: "The border around your screen that every drawer comes out of."

    Section {
        title: "Preview"
        FramePreview {}
    }

    Section {
        title: "Size"

        SpinRow {
            icon: "border_outer"
            title: "Thickness"
            description: "Width of the frame. 0 removes it."
            keywords: "border width"
            from: 0; to: 40; step: 2; unit: " px"
            value: Config.border.thickness
            defaultValue: 10
            onEdited: v => Config.border.thickness = v
        }
        SpinRow {
            icon: "rounded_corner"
            title: "Inner rounding"
            description: "Radius of the frame's inner corners and of the joints with drawers"
            keywords: "radius corners border"
            from: 0; to: 60; step: 5; unit: " px"
            value: Config.border.rounding
            defaultValue: 25
            onEdited: v => Config.border.rounding = v
        }
    }
}
