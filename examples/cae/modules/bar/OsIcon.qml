import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import qs.components

// Your distro's logo from the icon theme. Click it to open the launcher.
Item {
    id: root

    required property ScreenState screenState
    property string distro: "linux"

    implicitWidth: 26
    implicitHeight: 26

    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath(`distributor-logo-${root.distro}`, Quickshell.iconPath("distributor-logo", "start-here"))
    }

    StateLayer {
        anchors.margins: -4
        radius: width / 2
        onClicked: root.screenState.launcher = !root.screenState.launcher
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: root.distro = (text().match(/^ID=(.*)$/m)?.[1] ?? "linux").replace(/"/g, "")
    }
}
