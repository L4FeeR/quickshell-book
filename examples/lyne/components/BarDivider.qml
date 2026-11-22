import QtQuick
import qs.config

// A short vertical line between bar items
Rectangle {
    implicitWidth: 1
    implicitHeight: Config.barButtonHeight * 0.55
    color: Config.surface2Color
}
