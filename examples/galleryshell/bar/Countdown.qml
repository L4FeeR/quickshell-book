import Quickshell
import QtQuick
import QtQuick.Layouts

// Scroll to pick minutes, click to start. A notification fires when time is up.
Rectangle {
    id: root
    property int minutes: 5
    property real endsAt: 0                 // 0 = not running
    property real now: Date.now()
    readonly property bool active: endsAt > 0
    readonly property real remaining: active ? Math.max(0, endsAt - now) : minutes * 60000
    readonly property real fraction: active ? remaining / (minutes * 60000) : 1

    Timer {
        interval: 500; running: root.active; repeat: true
        onTriggered: {
            root.now = Date.now()
            if (root.remaining <= 0) {
                root.endsAt = 0
                Quickshell.execDetached(["notify-send", "-u", "critical", "-i", "alarm", "Time's up", root.minutes + " minute timer finished"])
            }
        }
    }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26
    radius: height / 2
    color: "#313244"
    clip: true

    // the background drains from right to left as time passes
    Rectangle {
        width: parent.width * root.fraction; height: parent.height
        radius: parent.radius
        color: root.active ? "#45365e" : "transparent"
        Behavior on width { NumberAnimation { duration: 500 } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: root.active ? "hourglass_top" : "hourglass_empty"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: root.active ? "#cba6f7" : "#cdd6f4"
        }
        Text {
            readonly property int secs: Math.ceil(root.remaining / 1000)
            text: Math.floor(secs / 60) + ":" + String(secs % 60).padStart(2, "0")
            color: "#cdd6f4"; font.pixelSize: 12
            font.features: ({ "tnum": 1 })
        }
    }

    TapHandler {
        onTapped: {
            root.now = Date.now()
            root.endsAt = root.active ? 0 : root.now + root.minutes * 60000
        }
    }
    WheelHandler {
        enabled: !root.active
        onWheel: e => root.minutes = Math.max(1, Math.min(180, root.minutes + (e.angleDelta.y > 0 ? 1 : -1)))
    }
}
