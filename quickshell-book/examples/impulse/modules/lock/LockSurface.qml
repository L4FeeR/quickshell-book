import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// The blurred wallpaper with a big clock; the password field sits at the bottom and shows
// one shape per typed character, cycling through a few Material shapes like end-4's.
Item {
    id: root

    required property var context

    anchors.fill: parent

    Image {
        id: wall
        anchors.fill: parent
        source: Config.options.background.wallpaperPath ? "file://" + Config.options.background.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: 1
        blurMax: 48
        brightness: -0.2
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18
        spacing: 0
        StyledText { Layout.alignment: Qt.AlignHCenter; text: DateTime.time; font.pixelSize: 110; font.family: Appearance.font.family.title; color: "white" }
        StyledText { Layout.alignment: Qt.AlignHCenter; text: DateTime.date; font.pixelSize: Appearance.font.pixelSize.huge; color: "white" }
    }

    Rectangle {
        id: field
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: 320
        height: 56
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer0
        border.width: root.context.failed ? 2 : 0
        border.color: Appearance.m3colors.m3error

        TextInput {
            anchors.fill: parent
            opacity: 0
            focus: true
            echoMode: TextInput.Password
            text: root.context.password
            onTextChanged: { root.context.password = text; root.context.failed = false; }
            onAccepted: root.context.tryUnlock()
            Component.onCompleted: forceActiveFocus()
        }

        Row {
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: root.context.password.length
                Rectangle {
                    required property int index
                    width: 14; height: 14
                    color: Appearance.colors.colPrimary
                    // circle, square-ish, diamond, pill: a small nod to end-4's shape characters
                    radius: [7, 4, 2, 7][index % 4]
                    rotation: index % 4 === 2 ? 45 : 0
                    scale: 0
                    Component.onCompleted: scale = 1
                    Behavior on scale { animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this) }
                }
            }
        }
        StyledText {
            anchors.centerIn: parent
            visible: root.context.password.length === 0
            text: root.context.unlocking ? "Unlocking…" : root.context.failed ? "Incorrect password" : "Enter password"
            color: root.context.failed ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
        }
    }
}
