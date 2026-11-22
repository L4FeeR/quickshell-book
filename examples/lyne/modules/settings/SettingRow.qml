import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// The frame shared by every setting: a title, an optional description,
// the control on the right, and a "reset" button that appears once the
// value differs from defaults.json. `path` is the state.json key.
Rectangle {
    id: root

    property string path
    property string title
    property string description: ""
    default property alias control: slot.data
    readonly property var value: StateService.get(path, null)

    Layout.fillWidth: true
    implicitHeight: Math.max(56, labels.implicitHeight + Config.spacing * 2)
    radius: Config.radius
    color: Config.cardColor

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.spacing * 2
        anchors.rightMargin: Config.spacing
        spacing: Config.spacing
        ColumnLayout {
            id: labels
            Layout.fillWidth: true
            spacing: 1
            StyledText { Layout.fillWidth: true; text: root.title; font.pixelSize: Config.fontSizeNormal }
            StyledText { Layout.fillWidth: true; visible: text !== ""; text: root.description; font.pixelSize: Config.fontSizeSmall; color: Config.mutedColor; wrapMode: Text.Wrap }
        }
        BarButton {                                        // reset to default
            visible: !StateService.isDefault(root.path)
            onClicked: StateService.reset(root.path)
            Glyph { text: Icons.restart; font.pixelSize: Config.fontSizeSmall + 2; color: Config.subtextColor }
        }
        Item {
            id: slot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
