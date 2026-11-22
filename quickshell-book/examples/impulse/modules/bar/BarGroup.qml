import QtQuick
import QtQuick.Layouts
import qs.modules.common

// A rounded "pill" holding a few modules side by side (end-4's signature grouped look).
Rectangle {
    default property alias items: row.data

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Appearance.sizes.barHeight - 8
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer1

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
