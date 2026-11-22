import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Black rounded corners on every screen (click-through, above everything).
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property ShellScreen modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:screenCorners"

        RoundCorner { anchors.top: parent.top; anchors.left: parent.left; corner: RoundCorner.CornerEnum.TopLeft; size: Appearance.rounding.screenRounding; visible: Config.options.bar.cornerStyle !== 0 || Config.options.bar.bottom }
        RoundCorner { anchors.top: parent.top; anchors.right: parent.right; corner: RoundCorner.CornerEnum.TopRight; size: Appearance.rounding.screenRounding; visible: Config.options.bar.cornerStyle !== 0 || Config.options.bar.bottom }
        RoundCorner { anchors.bottom: parent.bottom; anchors.left: parent.left; corner: RoundCorner.CornerEnum.BottomLeft; size: Appearance.rounding.screenRounding }
        RoundCorner { anchors.bottom: parent.bottom; anchors.right: parent.right; corner: RoundCorner.CornerEnum.BottomRight; size: Appearance.rounding.screenRounding }
    }
}
