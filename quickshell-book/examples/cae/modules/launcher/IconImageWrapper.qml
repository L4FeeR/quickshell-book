import Quickshell
import Quickshell.Widgets
import QtQuick

IconImage {
    required property DesktopEntry entry
    implicitSize: 34
    asynchronous: true
    source: Quickshell.iconPath(entry?.icon ?? "", "application-x-executable")
}
