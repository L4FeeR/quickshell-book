import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool open: false
    IpcHandler { target: "appgrid"; function toggle(): void { root.open = !root.open } }

    LazyLoader {
        active: root.open
        PanelWindow {
            id: win
            implicitWidth: 760; implicitHeight: 560
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            readonly property var apps: DesktopEntries.applications.values
                .filter(a => a.name.toLowerCase().includes(search.text.toLowerCase())
                          || (a.genericName ?? "").toLowerCase().includes(search.text.toLowerCase()))
                .sort((a, b) => a.name.localeCompare(b.name))
            function launch(e) { Quickshell.execDetached(e.command); root.open = false }

            Rectangle {
                anchors.fill: parent
                radius: 28; color: "#ee1e1e2e"; border.color: "#313244"
                ColumnLayout {
                    anchors { fill: parent; margins: 24 }
                    spacing: 16
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 46; radius: 23; color: "#313244"
                        TextInput {
                            id: search
                            anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#cdd6f4"; font.pixelSize: 16; focus: true
                            Text { visible: !parent.text; text: "Search apps…"; color: "#6c7086"; font: parent.font; anchors.verticalCenter: parent.verticalCenter }
                            onTextChanged: grid.currentIndex = 0
                            Keys.onEscapePressed: root.open = false
                            Keys.onReturnPressed: if (grid.currentIndex >= 0) win.launch(grid.model.values[grid.currentIndex])
                            Keys.forwardTo: [grid]                          // arrows move the grid selection
                        }
                    }
                    GridView {
                        id: grid
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true
                        cellWidth: width / 6; cellHeight: 112
                        keyNavigationEnabled: true
                        model: ScriptModel { values: win.apps }
                        highlight: Rectangle { radius: 18; color: "#313244" }
                        highlightMoveDuration: 100
                        delegate: Item {
                            required property DesktopEntry modelData
                            required property int index
                            width: grid.cellWidth; height: grid.cellHeight
                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                IconImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    implicitSize: 52
                                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                                    asynchronous: true
                                    scale: ma.containsMouse ? 1.12 : 1
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                }
                                Text {
                                    width: grid.cellWidth - 12
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name; color: "#cdd6f4"; font.pixelSize: 12; elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: ma; anchors.fill: parent; hoverEnabled: true
                                onEntered: grid.currentIndex = index
                                onClicked: { Quickshell.execDetached(modelData.command); root.open = false }
                            }
                        }
                    }
                }
            }
        }
    }
}
