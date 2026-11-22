import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// cliphist entries; click one to copy it again.
ListView {
    id: root
    property bool active: false
    property var entries: []

    clip: true
    spacing: 4
    model: entries
    onActiveChanged: if (active) list.running = true

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.entries = text.split("\n").filter(l => l).slice(0, 100) }
    }

    delegate: RippleButton {
        id: entry
        required property string modelData
        width: ListView.view.width
        height: 44
        colBackground: Appearance.colors.colLayer1
        onClicked: Quickshell.execDetached(["sh", "-c", `printf '%s' "$1" | cliphist decode | wl-copy`, "sh", modelData])
        contentItem: StyledText {
            leftPadding: 10
            text: entry.modelData.replace(/^\d+\t/, "")
            elide: Text.ElideRight
            color: Appearance.colors.colOnLayer1
        }
    }
}
