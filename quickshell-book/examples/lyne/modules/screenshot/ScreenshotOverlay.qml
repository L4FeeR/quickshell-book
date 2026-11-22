import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// Screenshots, lyne style: the screens dim and a control bar appears.
//   Region  drag a rectangle (R)      Window  click a window (W)
//   Screen  click a monitor (S)       Enter   capture, Esc cancel
// The picture is saved to ~/Pictures/Screenshots and copied to the clipboard.
Scope {
    id: root

    property bool active: false
    property string mode: "region"                       // "region" | "window" | "screen"
    // the selection, in global (all-monitor) coordinates
    property rect selection: Qt.rect(0, 0, 0, 0)
    readonly property bool hasSelection: selection.width > 2 && selection.height > 2

    function start() { mode = "region"; selection = Qt.rect(0, 0, 0, 0); active = true; }
    function cancel() { active = false; }

    function capture() {
        if (!hasSelection)
            return;
        active = false;
        const g = `${Math.round(selection.x)},${Math.round(selection.y)} ${Math.round(selection.width)}x${Math.round(selection.height)}`;
        // wait for the overlay to disappear, then grab that area of the screen
        Quickshell.execDetached(["sh", "-c",
            'sleep 0.25; dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"; mkdir -p "$dir"; f="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"; '
            + 'grim -g "$1" "$f" && wl-copy < "$f" && notify-send -i "$f" "Screenshot saved" "$(basename "$f")"', "sh", g]);
    }

    // the windows on each screen, for window mode: Hyprland knows their position and size
    function windowAt(gx, gy) {
        const ws = Hyprland.focusedMonitor?.activeWorkspace?.id;
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject;
            if (!o?.at || o.workspace?.id !== ws)
                continue;
            if (gx >= o.at[0] && gx <= o.at[0] + o.size[0] && gy >= o.at[1] && gy <= o.at[1] + o.size[1])
                return Qt.rect(o.at[0], o.at[1], o.size[0], o.size[1]);
        }
        return Qt.rect(0, 0, 0, 0);
    }

    Variants {
        model: root.active ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property bool isMain: modelData.name === (Hyprland.focusedMonitor?.name ?? "") || Quickshell.screens.length === 1
            // the selection in this window's coordinates
            readonly property rect local: Qt.rect(root.selection.x - modelData.x, root.selection.y - modelData.y, root.selection.width, root.selection.height)

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lyne_screenshot"
            WlrLayershell.keyboardFocus: isMain ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // Lists Hyprland's windows fresh when the overlay opens
            Component.onCompleted: Hyprland.refreshToplevels()

            // ── dim everything except the selection: four rectangles around it ──
            readonly property color shade: Qt.alpha(Config.scrimColor, 0.6)
            readonly property real sx: Math.max(0, Math.min(width, local.x))
            readonly property real sy: Math.max(0, Math.min(height, local.y))
            readonly property real ex: Math.max(0, Math.min(width, local.x + local.width))
            readonly property real ey: Math.max(0, Math.min(height, local.y + local.height))
            Rectangle { color: win.shade; x: 0; y: 0; width: parent.width; height: root.hasSelection ? win.sy : parent.height }
            Rectangle { visible: root.hasSelection; color: win.shade; x: 0; y: win.ey; width: parent.width; height: parent.height - win.ey }
            Rectangle { visible: root.hasSelection; color: win.shade; x: 0; y: win.sy; width: win.sx; height: win.ey - win.sy }
            Rectangle { visible: root.hasSelection; color: win.shade; x: win.ex; y: win.sy; width: parent.width - win.ex; height: win.ey - win.sy }

            Rectangle {                                         // outline and size
                visible: root.hasSelection
                x: win.local.x
                y: win.local.y
                width: win.local.width
                height: win.local.height
                color: "transparent"
                border.color: Config.accentColor
                border.width: 2
                Behavior on x { enabled: root.mode !== "region"; NumberAnimation { duration: Config.animDurationShort } }
                Behavior on y { enabled: root.mode !== "region"; NumberAnimation { duration: Config.animDurationShort } }
                Behavior on width { enabled: root.mode !== "region"; NumberAnimation { duration: Config.animDurationShort } }
                Behavior on height { enabled: root.mode !== "region"; NumberAnimation { duration: Config.animDurationShort } }
                Rectangle {
                    anchors.top: parent.bottom
                    anchors.topMargin: 6
                    anchors.right: parent.right
                    width: sizeText.implicitWidth + 12
                    height: 22
                    radius: Config.radiusSmall
                    color: Config.backgroundColor
                    StyledText { id: sizeText; anchors.centerIn: parent; text: Math.round(win.local.width) + " × " + Math.round(win.local.height); font.pixelSize: Config.fontSizeSmall }
                }
            }

            // ── mouse: drag (region), hover + click (window, screen) ──
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                property point start
                onPressed: m => {
                    if (root.mode === "region") {
                        start = Qt.point(m.x + win.modelData.x, m.y + win.modelData.y);
                        root.selection = Qt.rect(start.x, start.y, 0, 0);
                    }
                }
                onPositionChanged: m => {
                    const gx = m.x + win.modelData.x, gy = m.y + win.modelData.y;
                    if (root.mode === "region" && pressed)
                        root.selection = Qt.rect(Math.min(start.x, gx), Math.min(start.y, gy), Math.abs(gx - start.x), Math.abs(gy - start.y));
                    else if (root.mode === "window")
                        root.selection = root.windowAt(gx, gy);
                    else if (root.mode === "screen")
                        root.selection = Qt.rect(win.modelData.x, win.modelData.y, win.width, win.height);
                }
                onClicked: if (root.mode !== "region") root.capture()
            }

            // ── the control bar ──
            Rectangle {
                visible: win.isMain
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 40
                implicitWidth: controls.implicitWidth + Config.spacing * 2
                implicitHeight: 52
                radius: height / 2
                color: Config.backgroundTransparentColor

                focus: win.isMain
                Keys.onEscapePressed: root.cancel()
                Keys.onReturnPressed: root.capture()
                Keys.onEnterPressed: root.capture()
                Keys.onPressed: e => {
                    const m = ({ "r": "region", "w": "window", "s": "screen" })[e.text.toLowerCase()];
                    if (m) { root.mode = m; root.selection = Qt.rect(0, 0, 0, 0); }
                }

                RowLayout {
                    id: controls
                    anchors.centerIn: parent
                    spacing: Config.padding
                    Repeater {
                        model: [["region", Icons.region, "Region"], ["window", Icons.window, "Window"], ["screen", Icons.screen, "Screen"]]
                        BarButton {
                            id: modeButton
                            required property var modelData
                            implicitHeight: 40
                            active: root.mode === modelData[0]
                            onClicked: { root.mode = modelData[0]; root.selection = Qt.rect(0, 0, 0, 0); }
                            Glyph { text: modeButton.modelData[1]; color: root.mode === modeButton.modelData[0] ? Config.accentColor : Config.textColor }
                            StyledText { text: modeButton.modelData[2]; font.pixelSize: Config.fontSizeSmall }
                        }
                    }
                    BarDivider {}
                    BarButton {
                        implicitHeight: 40
                        enabled: root.hasSelection
                        opacity: enabled ? 1 : 0.4
                        onClicked: root.capture()
                        Glyph { text: Icons.screenshot; color: Config.accentColor }
                        StyledText { text: "Capture"; font.pixelSize: Config.fontSizeSmall }
                    }
                }
            }
        }
    }
}
