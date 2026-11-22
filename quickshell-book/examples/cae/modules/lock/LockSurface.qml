import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// What you see when locked: a blurred capture of the screen, a big clock, your picture and a
// password pill. Mistakes shake the pill.
Item {
    id: root

    required property var lock

    anchors.fill: parent

    // a frozen, blurred picture of what was on screen
    ScreencopyView {
        id: capture
        anchors.fill: parent
        captureSource: root.QsWindow.window?.screen ?? null
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: capture
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: -0.25
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing.large

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format("hh:mm")
            font.pixelSize: 110
            font.weight: 700
            color: Colours.palette.m3primary
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format("dddd, d MMMM")
            font.pixelSize: Tokens.font.size.large
            color: Colours.palette.m3onSurface
        }

        ClippingRectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.extraLarge
            implicitWidth: 96; implicitHeight: 96
            radius: Tokens.rounding.full
            color: Colours.palette.m3primaryContainer
            Image {
                anchors.fill: parent
                source: "file://" + Config.paths.face
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(192, 192)
            }
        }

        StyledRect {
            id: pill

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 300
            implicitHeight: 52
            radius: Tokens.rounding.full
            color: Colours.surface

            TextInput {
                id: input
                anchors.fill: parent
                opacity: 0                       // invisible: we draw dots ourselves
                focus: true
                echoMode: TextInput.Password
                enabled: !root.lock.busy
                text: root.lock.password
                onTextChanged: root.lock.password = text
                onAccepted: root.lock.submit()
                Component.onCompleted: forceActiveFocus()
            }

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small
                Repeater {
                    model: Math.min(root.lock.password.length, 16)
                    StyledRect {
                        width: 10; height: 10
                        radius: 5
                        color: Colours.palette.m3primary
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale { Anim { type: Anim.FastSpatial } }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.lock.password.length === 0
                text: root.lock.busy ? "Checking…" : root.lock.message || "Enter password"
                color: root.lock.message ? Colours.palette.m3error : Colours.palette.m3outline
            }

            transform: Translate { id: shakeX }
            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: shakeX; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 50 }
            }
        }
    }

    Connections {
        target: root.lock
        function onFailed(): void { shake.restart() }
    }
}
