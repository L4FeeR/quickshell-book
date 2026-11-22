import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Region, window or whole-screen screenshots with an optional delay.
// Saves to ~/Pictures/Screenshots, copies to the clipboard and shows a notification.
// Needs: grim, slurp, wl-clipboard, jq (for "window").
Scope {
    id: root
    property bool open: false
    property int delay: 0                              // seconds
    IpcHandler {
        target: "screenshot"
        function toggle(): void { root.open = !root.open }
        function region(): void { root.take("region") }      // for a keybind that skips the menu
    }

    // The shell script gets the mode and delay as arguments.
    // The menu is closed first, so it never appears in the picture.
    readonly property string script: '
        mode="$1"; delay="$2"
        dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"; mkdir -p "$dir"
        file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
        sleep 0.2; sleep "$delay"
        case "$mode" in
          region) geo=$(slurp) || exit 0; grim -g "$geo" "$file" ;;
          window) geo=$(hyprctl activewindow -j | jq -r "\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"")
                  grim -g "$geo" "$file" ;;
          *)      grim "$file" ;;
        esac
        wl-copy < "$file"
        notify-send -i "$file" "Screenshot saved" "$(basename "$file")"'

    function take(mode: string): void {
        open = false
        Quickshell.execDetached(["sh", "-c", script, "sh", mode, String(delay)])
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            anchors.bottom: true
            margins.bottom: 60
            implicitWidth: 420; implicitHeight: 150
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle {
                anchors.fill: parent
                radius: 24; color: "#1e1e2e"; border.color: "#313244"
                focus: true
                Keys.onEscapePressed: root.open = false
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_R) root.take("region")
                    else if (e.key === Qt.Key_W) root.take("window")
                    else if (e.key === Qt.Key_S) root.take("screen")
                }

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Repeater {
                            model: [
                                { mode: "region", icon: "screenshot_region", label: "Region", key: "R" },
                                { mode: "window", icon: "select_window", label: "Window", key: "W" },
                                { mode: "screen", icon: "fullscreen", label: "Screen", key: "S" }
                            ]
                            Rectangle {
                                id: btn
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 74; radius: 16
                                color: btnHover.hovered ? "#cba6f7" : "#313244"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: btn.modelData.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 28
                                        color: btnHover.hovered ? "#1e1e2e" : "#cdd6f4"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: btn.modelData.label + "  (" + btn.modelData.key + ")"
                                        color: btnHover.hovered ? "#1e1e2e" : "#a6adc8"; font.pixelSize: 11
                                    }
                                }
                                HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.take(btn.modelData.mode) }
                            }
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Text { text: "Delay"; color: "#a6adc8"; font.pixelSize: 12 }
                        Repeater {
                            model: [0, 3, 5, 10]
                            Rectangle {
                                required property int modelData
                                implicitWidth: 44; implicitHeight: 24; radius: 12
                                color: root.delay === modelData ? "#cba6f7" : "#313244"
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData ? parent.modelData + " s" : "off"
                                    color: root.delay === parent.modelData ? "#1e1e2e" : "#cdd6f4"; font.pixelSize: 11
                                }
                                TapHandler { onTapped: root.delay = parent.modelData }
                            }
                        }
                    }
                }
            }
        }
    }
}
