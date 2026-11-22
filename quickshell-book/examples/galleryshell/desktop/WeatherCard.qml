import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    property string city: ""
    property var wx: null

    anchors { bottom: true; left: true }
    margins { bottom: 80; left: 80 }
    implicitWidth: 300; implicitHeight: 170
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom

    function icon(code: int): string {
        if (code === 113) return "sunny"
        if (code === 116) return "partly_cloudy_day"
        if (code === 119 || code === 122) return "cloud"
        if ([143, 248, 260].includes(code)) return "foggy"
        if (code >= 386) return "thunderstorm"
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(code)) return "weather_snowy"
        return "rainy"
    }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/" + encodeURIComponent(root.city) + "?format=j1"]
        stdout: StdioCollector { onStreamFinished: { try { root.wx = JSON.parse(text) } catch (e) {} } }
    }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }

    readonly property var now: wx?.current_condition?.[0] ?? null
    readonly property string place: wx?.nearest_area?.[0]?.areaName?.[0]?.value ?? root.city

    Rectangle {
        anchors.fill: parent
        radius: 24; color: "#cc1e1e2e"; border.color: "#33ffffff"
        ColumnLayout {
            anchors { fill: parent; margins: 18 }
            spacing: 6
            RowLayout {
                spacing: 14
                Text { text: root.icon(parseInt(root.now?.weatherCode ?? 113)); font.family: "Material Symbols Rounded"
                       font.pixelSize: 56; font.variableAxes: ({ "FILL": 1 }); color: "#f9e2af" }
                ColumnLayout {
                    spacing: 0
                    Text { text: (root.now?.temp_C ?? "--") + "°"; color: "#cdd6f4"; font.pixelSize: 40; font.weight: Font.Black }
                    Text { text: (root.now?.weatherDesc?.[0]?.value ?? "") + " · " + root.place; color: "#a6adc8"; font.pixelSize: 12 }
                }
            }
            RowLayout {
                spacing: 18
                Repeater {
                    model: root.wx?.weather ?? []
                    Text {
                        required property var modelData
                        text: Qt.formatDate(new Date(modelData.date), "ddd") + "  " + modelData.maxtempC + "° / " + modelData.mintempC + "°"
                        color: "#a6adc8"; font.pixelSize: 11
                    }
                }
            }
        }
    }
}
