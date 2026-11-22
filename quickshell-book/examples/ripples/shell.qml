//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "components"

// Every way to use the effects, in one place:
//   a window with click ripples, jelly buttons, a stretchy tab pill, a
//   password field with typing ripples and a failure shockwave, a search
//   field with colourful keys and snow puffs,
//   ripples from shell events (volume changes), and snow on the desktop.
// Run:  qs -p examples/ripples        (the password is "secret")
ShellRoot {
    id: shell

    // ── snow over the whole desktop, never taking clicks ──
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom          // on the wallpaper, behind windows
            WlrLayershell.namespace: "ripples_snow"
            mask: Region {}
            Snow { anchors.fill: parent; intensity: 0.8; wind: 12 }
        }
    }

    // ── ripples from a shell event: the volume changing ──
    PanelWindow {
        anchors.bottom: true
        margins.bottom: 60
        implicitWidth: 360
        implicitHeight: 360
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        mask: Region {}
        RippleLayer { id: eventRipples; anchors.fill: parent; tint: "#7aa2f7"; endSize: 340; duration: 900 }
        PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
        Connections {
            target: Pipewire.defaultAudioSink?.audio ?? null
            function onVolumeChanged() { eventRipples.burst(180, 180, { ring: true, startOpacity: 0.7 }); }
        }
        // or from anywhere: qs -p examples/ripples ipc call ripple at 180 180
        IpcHandler { target: "ripple"; function at(x: real, y: real): void { eventRipples.burst(x, y, { ring: true, startOpacity: 0.7 }); } }
    }

    // ── the showcase window ──
    FloatingWindow {
        id: win
        title: "Ripples and friends"
        implicitWidth: 760
        implicitHeight: 560
        color: "#1a1b26"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 22

            Text { text: "Click, press and type"; color: "#c0caf5"; font.pixelSize: 22; font.bold: true }

            // 1. click ripples on buttons of any shape
            RowLayout {
                spacing: 14
                Repeater {
                    model: [["Ripple", 14, "#7aa2f7"], ["Pill", 22, "#bb9af7"], ["Square", 4, "#9ece6a"]]
                    Rectangle {
                        id: button
                        required property var modelData
                        implicitWidth: 140
                        implicitHeight: 48
                        radius: modelData[1]
                        color: "#24283b"
                        Text { anchors.centerIn: parent; text: button.modelData[0]; color: "#c0caf5"; font.pixelSize: 15 }
                        ClickRipple { radius: button.radius; tint: button.modelData[2] }
                    }
                }
                // 2. jelly: squash on press, springy release
                Rectangle {
                    implicitWidth: 140
                    implicitHeight: 48
                    radius: 24
                    color: "#7aa2f7"
                    Text { anchors.centerIn: parent; text: "Jelly"; color: "#1a1b26"; font.pixelSize: 15; font.bold: true }
                    Stretch { handleMouse: true }
                }
            }

            // 3. a stretchy pill following the selected tab
            Item {
                Layout.fillWidth: true
                implicitHeight: 40
                property int current: 0
                id: tabs
                StretchPill { id: pill; target: tabRow.children[tabs.current] ?? null; height: 40; color: "#292e42" }
                Row {
                    id: tabRow
                    Repeater {
                        model: ["Overview", "Media", "System", "Weather"]
                        Item {
                            required property string modelData
                            required property int index
                            width: 130
                            height: 40
                            Text { anchors.centerIn: parent; text: parent.modelData; color: tabs.current === parent.index ? "#7aa2f7" : "#a9b1d6"; font.pixelSize: 14 }
                            MouseArea { anchors.fill: parent; onClicked: tabs.current = parent.index }
                        }
                    }
                }
            }

            // 4. a password field: ripples per key, a shockwave when wrong
            Item {
                id: passwordArea
                Layout.fillWidth: true
                implicitHeight: 90
                Rectangle {
                    id: passwordBox
                    anchors.centerIn: parent
                    width: 360
                    height: 50
                    radius: 25
                    color: "#16161e"
                    border.width: 2
                    border.color: password.activeFocus ? "#7aa2f7" : "#414868"
                    TextInput {
                        id: password
                        objectName: "password"
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 22
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: "#c0caf5"
                        font.pixelSize: 16
                        onAccepted: {
                            if (text === "secret") { snowBurst(); text = ""; }
                            else { typing.shake(); jelly.poke(1.4); text = ""; }
                        }
                    }
                    Stretch { id: jelly }
                }
                TypingRipple { id: typing; target: password; anchors.fill: parent }
            }

            // 5. a search field: a colour per key, and a little snow puff from the caret
            Item {
                Layout.fillWidth: true
                implicitHeight: 70
                Rectangle {
                    anchors.centerIn: parent
                    width: 360
                    height: 44
                    radius: 22
                    color: "#16161e"
                    TextInput {
                        id: search
                        objectName: "search"
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#c0caf5"
                        font.pixelSize: 15
                        // later: the caret has moved only once the new text is laid out
                        onTextEdited: Qt.callLater(() => {
                            const r = cursorRectangle;
                            const p = mapToItem(winSnow, r.x, r.y + r.height / 2);
                            winSnow.burst(p.x, p.y, 8);
                        })
                    }
                }
                TypingRipple { target: search; anchors.fill: parent; randomTints: true; keySize: 70 }
            }
        }

        // snow inside the window, for bursts (on top, but it never takes clicks)
        Snow { id: winSnow; anchors.fill: parent; intensity: 0; z: 10 }
    }

    function snowBurst() {
        for (let i = 0; i < 6; i++)
            winSnow.burst(win.width * (0.15 + i * 0.14), win.height * 0.55, 20);
    }
}
