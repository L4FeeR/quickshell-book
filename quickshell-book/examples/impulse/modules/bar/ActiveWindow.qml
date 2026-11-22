import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Two lines: the app (small, dim) and the window title.
ColumnLayout {
    readonly property Toplevel win: ToplevelManager.activeToplevel
    spacing: -4

    StyledText {
        Layout.fillWidth: true
        text: parent.win?.appId ?? "Desktop"
        elide: Text.ElideRight
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }
    StyledText {
        Layout.fillWidth: true
        text: parent.win?.title ?? "Workspace"
        elide: Text.ElideRight
        color: Appearance.colors.colOnLayer0
    }
}
