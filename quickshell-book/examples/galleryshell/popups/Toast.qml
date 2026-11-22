import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property string title: ""
    property string body: ""
    property string icon: "check_circle"
    property color tint: "#a6e3a1"
    property bool shown: false

    function show(t: string, b: string, i: string, c: color): void {
        title = t; body = b; icon = i || "info"; tint = c
        shown = true
        hideTimer.restart()
    }
    Timer { id: hideTimer; interval: 2500; onTriggered: root.shown = false }

    IpcHandler {
        target: "toast"
        function show(title: string, body: string): void { root.show(title, body, "info", "#89b4fa") }
        function ok(title: string, body: string): void { root.show(title, body, "check_circle", "#a6e3a1") }
        function error(title: string, body: string): void { root.show(title, body, "error", "#f38ba8") }
    }

    PanelWindow {
        anchors.top: true
        implicitWidth: 340
        implicitHeight: 100
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        visible: root.shown || slide.running
        mask: Region { item: card }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:toast"

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320; height: 60; radius: 18
            y: root.shown ? 12 : -height - 10
            Behavior on y { NumberAnimation { id: slide; duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            color: "#1e1e2e"; border.color: "#45475a"

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 12
                Text { text: root.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 28; color: root.tint
                       font.variableAxes: ({ "FILL": 1 }) }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Text { text: root.title; color: "#cdd6f4"; font.bold: true; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { text: root.body; visible: text; color: "#a6adc8"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                }
            }
            TapHandler { onTapped: root.shown = false }
        }
    }
}
