import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Alt+Tab window switcher. Hyprland binds (classic config):
//   bind  = ALT, Tab, exec, qs ipc call alttab next
//   bind  = ALT SHIFT, Tab, exec, qs ipc call alttab prev
//   bindr = ALT, ALT_L, exec, qs ipc call alttab commit     # releasing Alt switches
Scope {
    id: root
    property bool open: false
    property int index: 0
    property var order: []                         // window list frozen while the switcher is open

    // most recently focused first: remember focus order as it happens
    property var history: []
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged(): void {
            const t = ToplevelManager.activeToplevel
            if (t) root.history = [t].concat(root.history.filter(x => x !== t && !x.closed))
        }
    }
    function sorted(): var {
        const all = ToplevelManager.toplevels.values
        const known = history.filter(t => all.includes(t))
        return known.concat(all.filter(t => !known.includes(t)))
    }

    function step(d: int): void {
        if (!open) { order = sorted(); if (order.length === 0) return; index = 0; open = true }
        index = (index + d + order.length) % order.length
    }
    function commit(): void {
        if (!open) return
        open = false
        order[index]?.activate()
    }
    IpcHandler {
        target: "alttab"
        function next(): void { root.step(1) }
        function prev(): void { root.step(-1) }
        function commit(): void { root.commit() }
        function cancel(): void { root.open = false }
    }

    LazyLoader {
        active: root.open
        PanelWindow {
            implicitWidth: Math.min(screen.width - 80, row.implicitWidth + 32)
            implicitHeight: 170
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                anchors.fill: parent
                radius: 24; color: "#e61e1e2e"; border.color: "#313244"
                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 10
                    Repeater {
                        model: root.order
                        Rectangle {
                            id: card
                            required property var modelData
                            required property int index
                            readonly property bool current: index === root.index
                            implicitWidth: 120; implicitHeight: 130; radius: 16
                            color: current ? "#45365e" : "transparent"
                            border.color: current ? "#cba6f7" : "transparent"; border.width: 2
                            ColumnLayout {
                                anchors { fill: parent; margins: 10 }
                                IconImage {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitSize: 56
                                    source: Quickshell.iconPath(DesktopEntries.heuristicLookup(card.modelData.appId)?.icon ?? card.modelData.appId, "application-x-executable")
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.title
                                    color: "#cdd6f4"; font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                }
                            }
                            TapHandler { onTapped: { root.index = card.index; root.commit() } }
                        }
                    }
                }
            }
        }
    }
}
