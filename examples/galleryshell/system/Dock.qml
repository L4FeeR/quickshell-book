import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// A bottom dock: pinned apps plus running ones, a dot under running apps, magnify on hover,
// and it hides when a window would cover it (shows again when the pointer touches the bottom edge).
Scope {
    id: root
    property list<string> pinned: ["firefox", "kitty", "org.gnome.Nautilus", "code"]

    readonly property var running: ToplevelManager.toplevels.values
    // pinned first, then running apps that aren't pinned, one icon per app id
    readonly property var apps: {
        const ids = Array.from(pinned)
        for (const t of running) if (t.appId && !ids.includes(t.appId)) ids.push(t.appId)
        return ids
    }
    function windowsOf(appId: string): var { return running.filter(t => t.appId === appId) }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors.bottom: true
            implicitWidth: dock.implicitWidth + 40
            implicitHeight: 90
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "quickshell:dock"

            // a window on this screen is maximized/fullscreen → hide unless hovered
            readonly property bool covered: root.running.some(t => (t.maximized || t.fullscreen) && t.screens.includes(win.screen))
            readonly property bool shown: !covered || area.containsMouse
            // input area: the dock and the gap below it while shown, only a 4 px strip while hidden
            mask: Region { item: win.shown ? zone : edge }
            Item { id: zone; anchors.bottom: parent.bottom; x: dock.x; width: dock.width; height: dock.height + 8 }
            Item { id: edge; anchors.bottom: parent.bottom; width: parent.width; height: 4 }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                Rectangle {
                    id: dock
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: win.shown ? parent.height - height - 8 : parent.height + 4
                    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    implicitWidth: row.implicitWidth + 20
                    implicitHeight: 62
                    radius: 20; color: "#e61e1e2e"; border.color: "#313244"

                    RowLayout {
                        id: row
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                        spacing: 6
                        Repeater {
                            model: root.apps
                            Item {
                                id: app
                                required property string modelData
                                readonly property var entry: DesktopEntries.heuristicLookup(modelData)
                                readonly property var windows: root.windowsOf(modelData)
                                readonly property bool focused: windows.some(t => t.activated)
                                implicitWidth: 46 * icon.scale; implicitHeight: 46
                                Layout.alignment: Qt.AlignBottom

                                IconImage {
                                    id: icon
                                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
                                    implicitSize: 40
                                    source: Quickshell.iconPath(app.entry?.icon ?? app.modelData, "application-x-executable")
                                    scale: appHover.hovered ? 1.3 : 1
                                    transformOrigin: Item.Bottom
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                }
                                Row {                                     // one dot per open window (max 3)
                                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -4 }
                                    spacing: 3
                                    Repeater {
                                        model: Math.min(3, app.windows.length)
                                        Rectangle { width: app.focused ? 10 : 4; height: 4; radius: 2; color: app.focused ? "#cba6f7" : "#a6adc8" }
                                    }
                                }
                                HoverHandler { id: appHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: {
                                        const w = app.windows
                                        if (w.length === 0) app.entry?.execute()              // launch
                                        else if (!app.focused) w[0].activate()                // focus
                                        else w[(w.findIndex(t => t.activated) + 1) % w.length].activate()   // cycle
                                    }
                                }
                                TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: app.entry?.execute() }   // new window
                            }
                        }
                    }
                }
            }
        }
    }
}
