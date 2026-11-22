import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string city: ""                 // "" = detect from IP, or e.g. "Kochi"
    property string temp: "--"
    property string desc: ""
    property string icon: "cloud"

    function iconFor(code: int): string {
        if (code === 113) return "sunny"
        if (code === 116) return "partly_cloudy_day"
        if (code === 119 || code === 122) return "cloud"
        if ([143, 248, 260].includes(code)) return "foggy"
        if (code >= 386) return "thunderstorm"
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(code)) return "ac_unit"
        return "rainy"
    }

    implicitWidth: row.implicitWidth + 22
    implicitHeight: 26
    radius: height / 2
    color: "#313244"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Text { text: root.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: "#f9e2af" }
        Text { text: root.temp + "°C " + root.desc; color: "#cdd6f4"; font.pixelSize: 12 }
    }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/" + encodeURIComponent(root.city) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text).current_condition[0]
                    root.temp = c.temp_C
                    root.desc = c.weatherDesc[0].value
                    root.icon = root.iconFor(parseInt(c.weatherCode))
                } catch (e) { root.desc = "offline" }
            }
        }
    }
    Timer { interval: 20 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }
    TapHandler { onTapped: Qt.openUrlExternally("https://wttr.in/" + root.city) }
}
