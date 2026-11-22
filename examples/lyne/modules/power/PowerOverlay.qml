import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// The power menu (lyne's "strip" template): every monitor dims, and on the
// focused one a column of buttons slides out of the right edge.
//   letter keys (L S E R P)  run that action
//   1-5 / arrows             move the selection, Enter runs it
//   Esc or a click outside   closes (or cancels a countdown)
Scope {
    id: root

    readonly property string focusedName: Hyprland.focusedMonitor?.name ?? ""

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            readonly property bool isMain: modelData.name === root.focusedName || Quickshell.screens.length === 1
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lyne_power"
            WlrLayershell.keyboardFocus: isMain ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // the dim backdrop fades in; a click on it closes or cancels
            Rectangle {
                anchors.fill: parent
                color: Config.scrimColor
                opacity: 0
                Component.onCompleted: opacity = 0.45
                Behavior on opacity { NumberAnimation { duration: Config.animDuration } }
                MouseArea { anchors.fill: parent; onClicked: PowerService.countdown > 0 ? PowerService.cancel() : PowerService.close() }
            }

            Rectangle {
                id: strip
                visible: win.isMain
                anchors.verticalCenter: parent.verticalCenter
                width: 76
                height: col.implicitHeight + Config.spacing * 3
                radius: Config.radiusLarge
                color: Config.backgroundTransparentColor
                // slides in from the right edge: `entered` turns true one tick after
                // creation (by then the window has its size), and x follows it
                property bool entered: false
                Component.onCompleted: Qt.callLater(() => entered = true)
                x: entered ? parent.width - width - Config.spacing * 2 : parent.width
                Behavior on x { NumberAnimation { duration: Config.animDurationLong; easing.type: Easing.OutExpo } }
                MouseArea { anchors.fill: parent }                  // clicks on the strip don't close

                focus: win.isMain
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) {
                        PowerService.countdown > 0 ? PowerService.cancel() : PowerService.close();
                    } else if (PowerService.countdown > 0) {
                        PowerService.cancel();                       // any key cancels a countdown
                    } else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) {
                        PowerService.selected = (PowerService.selected + PowerService.actions.length - 1) % PowerService.actions.length;
                    } else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) {
                        PowerService.selected = (PowerService.selected + 1) % PowerService.actions.length;
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        PowerService.run(PowerService.selected);
                    } else if (e.text >= "1" && e.text <= "9") {
                        PowerService.selected = Math.min(PowerService.actions.length - 1, Number(e.text) - 1);
                    } else {
                        const i = PowerService.actions.findIndex(a => a.key === e.text.toUpperCase());
                        if (i >= 0) PowerService.run(i);
                    }
                }

                ColumnLayout {
                    id: col
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Config.spacing * 1.5
                    spacing: Config.spacing

                    Repeater {
                        model: PowerService.actions
                        Rectangle {
                            id: button
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === PowerService.selected
                            readonly property bool counting: PowerService.pending === index
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 56
                            implicitHeight: 56
                            radius: selected ? Config.radiusLarge : 28
                            color: counting ? Config.errorColor : selected ? Config.accentColor : bMouse.containsMouse ? Config.surface2Color : Config.surface1Color
                            Behavior on radius { NumberAnimation { duration: Config.animDuration } }
                            Glyph {
                                anchors.centerIn: parent
                                text: button.counting ? PowerService.countdown : button.modelData.icon
                                font.pixelSize: Config.fontSizeIcon
                                font.bold: button.counting
                                color: button.selected || button.counting ? Config.textReverseColor : Config.textColor
                            }
                            StyledText {                          // the key for this action
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 4
                                text: button.modelData.key
                                font.pixelSize: 9
                                font.bold: true
                                color: button.selected ? Config.textReverseColor : Config.mutedColor
                            }
                            MouseArea {
                                id: bMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: if (PowerService.countdown === 0) PowerService.selected = button.index
                                onClicked: PowerService.run(button.index)
                            }
                        }
                    }
                }
            }

            // the selected action's name (or the countdown), left of the strip
            StyledText {
                visible: win.isMain
                anchors.right: strip.left
                anchors.rightMargin: Config.spacing * 2
                anchors.verticalCenter: strip.verticalCenter
                text: PowerService.countdown > 0
                    ? PowerService.actions[PowerService.pending].label + " in " + PowerService.countdown + "…  (any key cancels)"
                    : PowerService.actions[PowerService.selected].label
                font.pixelSize: Config.fontSizeLarge
                font.bold: true
                color: "white"
            }
        }
    }
}
