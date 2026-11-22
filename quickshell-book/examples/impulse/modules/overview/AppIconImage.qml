import Quickshell
import Quickshell.Widgets

IconImage {
    property string name
    implicitSize: 30
    source: Quickshell.iconPath(name, "application-x-executable")
}
