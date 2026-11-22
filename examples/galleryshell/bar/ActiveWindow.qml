import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    readonly property Toplevel win: ToplevelManager.activeToplevel
    property int maxWidth: 320
    visible: win !== null

    implicitWidth: Math.min(row.implicitWidth + 20, maxWidth)
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 10; anchors.rightMargin: 10
        spacing: 8
        IconImage {
            implicitSize: 16
            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(root.win?.appId ?? "")?.icon ?? "", "application-x-executable")
        }
        Text {
            Layout.fillWidth: true
            text: root.win?.title ?? ""
            color: "#cdd6f4"
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }
}
