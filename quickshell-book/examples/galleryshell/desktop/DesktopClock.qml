import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

PanelWindow {
    anchors { top: true; left: true }
    margins { top: 140; left: 90 }
    implicitWidth: 520; implicitHeight: 200
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}                                  // click-through
    WlrLayershell.layer: WlrLayer.Bottom             // above wallpaper, below windows
    WlrLayershell.namespace: "quickshell:desktop-clock"

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Item {
        id: content
        anchors.fill: parent
        Row {
            id: timeRow
            spacing: 8
            Text {
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: "#cba6f7"
                font { family: "Inter"; pixelSize: 110; weight: Font.Black; letterSpacing: -4 }
                font.features: ({ "tnum": 1 })
            }
            Text {
                anchors.baseline: parent.children[0].baseline
                text: String(clock.seconds).padStart(2, "0")
                color: "#cba6f7"; opacity: 0.55
                font { pixelSize: 28; bold: true }
                // fade on each tick
                onTextChanged: tick.restart()
                NumberAnimation on opacity { id: tick; from: 0.9; to: 0.4; duration: 900; running: false }
            }
        }
        Text {
            anchors { top: timeRow.bottom; left: parent.left; leftMargin: 6; topMargin: -12 }
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: "#cdd6f4"; font.pixelSize: 24
        }
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowOpacity: 0.55; shadowVerticalOffset: 3 }
    }
}
