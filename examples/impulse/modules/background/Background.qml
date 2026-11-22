import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Wallpaper plus a clock widget on the desktop.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bg
        required property ShellScreen modelData

        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Appearance.m3colors.m3background
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:background"

        Image {
            anchors.fill: parent
            source: Config.options.background.wallpaperPath ? "file://" + Config.options.background.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(bg.width * bg.modelData.devicePixelRatio, bg.height * bg.modelData.devicePixelRatio)
        }

        ColumnLayout {
            visible: Config.options.background.showClock
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 60
            spacing: -10
            StyledText { Layout.alignment: Qt.AlignRight; text: DateTime.time; font.pixelSize: 90; font.family: Appearance.font.family.title; color: Appearance.m3colors.m3primary }
            StyledText { Layout.alignment: Qt.AlignRight; text: DateTime.date; font.pixelSize: Appearance.font.pixelSize.huge; color: Appearance.m3colors.m3onBackground }
        }
    }
}
