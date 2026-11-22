import Quickshell
import QtQuick

// Reusable tooltip. Put one next to any widget:
//   Tooltip { target: myIcon; text: "Volume 40%"; show: myHover.hovered }
PopupWindow {
    id: root
    required property Item target
    property string text: ""
    property bool show: false
    property int delay: 500                       // ms of hovering before it appears

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip   // stay on screen
    implicitWidth: label.implicitWidth + 20
    implicitHeight: label.implicitHeight + 12
    color: "transparent"

    // visible after `delay`, hidden immediately; stays mapped during the fade-out
    property bool wanted: false
    visible: wanted || box.opacity > 0
    Timer { id: wait; interval: root.delay; onTriggered: root.wanted = true }
    onShowChanged: { if (show && text) wait.restart(); else { wait.stop(); wanted = false } }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: 8
        color: "#11111b"; border.color: "#45475a"
        opacity: root.wanted ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: "#cdd6f4"; font.pixelSize: 12
        }
    }
}
