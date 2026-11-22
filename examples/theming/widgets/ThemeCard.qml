import QtQuick
import qs.services

// A small picture of ONE theme, drawn in that theme's own colours (not the current theme's):
// a window with a title bar, text lines, an accent button and the six accent colours.
Rectangle {
    id: root

    required property var theme                 // a theme object from Theme.list
    property bool selected: false
    property bool hovered: false

    // read a role from this card's theme
    function c(roleName: string): color {
        return Theme.resolve(theme, roleName);
    }

    implicitWidth: 200
    implicitHeight: 150
    radius: 16
    color: c("background")
    border.width: selected ? 3 : hovered ? 2 : 1
    border.color: selected ? c("primary") : hovered ? c("textMuted") : c("border")
    scale: hovered ? 1.03 : 1

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    // mini "window"
    Rectangle {
        x: 12; y: 12
        width: parent.width - 24
        height: 72
        radius: 10
        color: root.c("surface")

        Rectangle {                              // title bar
            width: parent.width; height: 18
            radius: 10
            color: root.c("surfaceHigh")
            Row {
                x: 8; anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Repeater {
                    model: ["red", "yellow", "green"]
                    Rectangle { required property string modelData; width: 7; height: 7; radius: 3.5; color: root.c(modelData) }
                }
            }
        }
        Column {                                 // "text" lines in the three text colours
            x: 10; y: 26
            spacing: 6
            Rectangle { width: 110; height: 5; radius: 2.5; color: root.c("text") }
            Rectangle { width: 80; height: 5; radius: 2.5; color: root.c("textMuted") }
            Rectangle { width: 95; height: 5; radius: 2.5; color: root.c("textFaint") }
        }
        Rectangle {                              // an accent "button"
            anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
            width: 44; height: 18; radius: 9
            color: root.c("primary")
            Text { anchors.centerIn: parent; text: "Aa"; font.pixelSize: 10; font.bold: true; color: root.c("onPrimary") }
        }
    }

    // accent swatches
    Row {
        x: 12; y: 92
        spacing: 4
        Repeater {
            model: ["red", "orange", "yellow", "green", "cyan", "blue", "magenta"]
            Rectangle { required property string modelData; width: 16; height: 16; radius: 8; color: root.c(modelData) }
        }
    }

    Text {
        x: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: parent.width - 40
        text: root.theme.name
        elide: Text.ElideRight
        font.family: "Rubik"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: root.c("text")
    }
    Text {                                       // ☀ / ☾ badge
        anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
        text: root.theme.variant === "light" ? "☀" : "☾"
        font.pixelSize: 13
        color: root.c("textMuted")
    }
}
