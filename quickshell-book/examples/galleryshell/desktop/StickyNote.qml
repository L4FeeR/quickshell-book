import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: 120; right: 380 }
    implicitWidth: 240; implicitHeight: 240
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand        // focus when clicked, so you can type

    FileView {
        id: file
        path: Quickshell.statePath("sticky-note.txt")
        printErrors: false
        onLoaded: if (edit.text !== text()) edit.text = text()
    }
    Timer { id: save; interval: 600; onTriggered: file.setText(edit.text) }    // save shortly after typing stops

    Rectangle {
        anchors.fill: parent; anchors.margins: 10
        rotation: -2
        radius: 6; color: "#f9e2af"
        Rectangle { width: parent.width; height: 22; radius: 6; color: "#f5d48a" }
        TextEdit {
            id: edit
            anchors { fill: parent; margins: 14; topMargin: 30 }
            wrapMode: TextEdit.Wrap
            color: "#45475a"; font.pixelSize: 14
            selectByMouse: true
            onTextChanged: save.restart()
            Text { visible: !parent.text && !parent.activeFocus; text: "Click to write…"; color: "#8a7f60"; font: parent.font }
        }
    }
}
