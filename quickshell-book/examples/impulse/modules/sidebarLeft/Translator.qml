import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Type text, get a translation from translate-shell (`trans`). Debounced like a search box.
ColumnLayout {
    id: root
    property string target: "en"
    spacing: 8

    RowLayout {
        StyledText { text: "Translate to"; color: Appearance.colors.colSubtext }
        TextField { id: lang; text: root.target; implicitWidth: 60; onEditingFinished: root.target = text }
    }
    TextArea {
        id: input
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        placeholderText: "Enter text…"
        wrapMode: TextEdit.Wrap
        color: Appearance.colors.colOnLayer1
        background: Rectangle { radius: Appearance.rounding.small; color: Appearance.colors.colLayer1 }
        onTextChanged: debounce.restart()
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1
        StyledText {
            anchors.fill: parent
            anchors.margins: 10
            verticalAlignment: Text.AlignTop
            wrapMode: Text.Wrap
            text: output.text || "Translation appears here"
            color: output.text ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
        }
    }

    Timer { id: debounce; interval: 600; onTriggered: if (input.text.trim()) trans.running = true }
    Process {
        id: trans
        command: ["trans", "-brief", ":" + root.target, input.text]
        stdout: StdioCollector { id: output }
    }
}
