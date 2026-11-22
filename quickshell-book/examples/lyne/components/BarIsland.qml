import QtQuick
import QtQuick.Layouts
import qs.config

// A group of bar items in a row. With the "islands" bar style each group is
// its own floating pill; with the other styles the bar draws one background
// and the group is just a row.
Rectangle {
    id: root

    default property alias content: row.data          // children go into the row
    readonly property bool framed: Config.barIslands
    readonly property int sidePadding: framed ? Config.padding : 0

    implicitWidth: row.implicitWidth + sidePadding * 2
    implicitHeight: Config.barIslandHeight
    radius: height / 2
    color: framed ? Config.backgroundTransparentColor : "transparent"

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: root.sidePadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.padding
    }
}
