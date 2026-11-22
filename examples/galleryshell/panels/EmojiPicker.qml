import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property bool open: false
    IpcHandler { target: "emoji"; function toggle(): void { root.open = !root.open } }

    // a small built-in list: [emoji, keywords]. Load a full list from a JSON file for production.
    readonly property var emojis: [
        ["😀","grin happy smile"],["😂","joy laugh tears"],["😍","love heart eyes"],["🥺","pleading puppy"],["😎","cool sunglasses"],
        ["🤔","thinking hmm"],["😭","cry sob"],["😡","angry mad"],["👍","thumbs up yes ok"],["👎","thumbs down no"],
        ["🙏","pray please thanks"],["👏","clap"],["🔥","fire lit hot"],["✨","sparkles shine"],["🎉","party tada"],
        ["❤️","heart love red"],["💜","heart purple"],["💙","heart blue"],["💚","heart green"],["🖤","heart black"],
        ["✅","check done yes"],["❌","cross no wrong"],["⚠️","warning"],["💡","idea bulb"],["🚀","rocket launch ship"],
        ["🐧","penguin linux"],["☕","coffee"],["🍕","pizza food"],["🎵","music note"],["💻","laptop computer"]
    ]
    function pick(e) { Quickshell.execDetached(["wl-copy", e]); root.open = false }

    LazyLoader {
        active: root.open
        PanelWindow {
            id: win
            implicitWidth: 380; implicitHeight: 360
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            readonly property var shown: root.emojis.filter(e => !q.text || e[1].includes(q.text.toLowerCase()))

            Rectangle {
                anchors.fill: parent; radius: 22; color: "#1e1e2e"; border.color: "#313244"
                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 12
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 38; radius: 19; color: "#313244"
                        TextInput {
                            id: q; anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            verticalAlignment: TextInput.AlignVCenter; color: "#cdd6f4"; font.pixelSize: 14; focus: true
                            Keys.onEscapePressed: root.open = false
                            Keys.onReturnPressed: if (win.shown.length) root.pick(win.shown[g.currentIndex][0])
                            Keys.forwardTo: [g]
                            onTextChanged: g.currentIndex = 0
                        }
                    }
                    GridView {
                        id: g
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; cellWidth: width / 7; cellHeight: cellWidth
                        keyNavigationEnabled: true
                        model: win.shown
                        highlight: Rectangle { radius: 10; color: "#45475a" }
                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: g.cellWidth; height: g.cellHeight
                            Text { anchors.centerIn: parent; text: modelData[0]; font.pixelSize: 26; font.family: "Noto Color Emoji" }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: g.currentIndex = index; onClicked: root.pick(modelData[0]) }
                        }
                    }
                }
            }
        }
    }
}
