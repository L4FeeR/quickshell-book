import Quickshell
import QtQuick
import QtQuick.Layouts

// A styled right-click menu. Give it a list of entries and open it at an item:
//   ContextMenu {
//       id: menu
//       entries: [ { icon: "content_copy", text: "Copy", action: () => … },
//                  { separator: true },
//                  { icon: "delete", text: "Delete", danger: true, action: () => … } ]
//   }
//   TapHandler { acceptedButtons: Qt.RightButton; onTapped: menu.popup(someItem) }
PopupWindow {
    id: root
    property var entries: []
    property Item at: null

    function popup(item: Item): void { at = item; visible = true }
    function close(): void { visible = false }

    anchor.item: at
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    implicitWidth: 200
    implicitHeight: col.implicitHeight + 12
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 12; color: "#1e1e2e"; border.color: "#45475a"
        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 2
            Repeater {
                model: root.entries
                Item {
                    id: entry
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: modelData.separator ? 9 : 32
                    Rectangle {                                  // separator line
                        visible: entry.modelData.separator === true
                        anchors.centerIn: parent
                        width: parent.width - 12; height: 1; color: "#313244"
                    }
                    Rectangle {                                  // normal entry
                        visible: !entry.modelData.separator
                        anchors.fill: parent
                        radius: 8
                        color: entryHover.hovered ? (entry.modelData.danger ? "#4d2a35" : "#313244") : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10
                            Text {
                                text: entry.modelData.icon ?? ""
                                font.family: "Material Symbols Rounded"; font.pixelSize: 17
                                color: entry.modelData.danger ? "#f38ba8" : "#a6adc8"
                            }
                            Text {
                                Layout.fillWidth: true
                                text: entry.modelData.text ?? ""
                                color: entry.modelData.danger ? "#f38ba8" : "#cdd6f4"; font.pixelSize: 13
                            }
                        }
                        HoverHandler { id: entryHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                root.close()
                                entry.modelData.action?.()
                            }
                        }
                    }
                }
            }
        }
    }
}
