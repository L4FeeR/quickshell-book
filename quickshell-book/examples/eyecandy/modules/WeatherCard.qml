import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The weather on the desktop, from Open-Meteo (free, no key): the city is
// turned into coordinates once, then the forecast is fetched every 30 minutes.
PanelWindow {
    id: root

    property string city: "London"            // your city
    property var current: null             // { temperature, code, wind }
    property var days: []                  // [{ day, max, min, code }]
    property real lat: 0
    property real lon: 0

    anchors { top: true; right: true }
    margins { top: 70; right: 40 }
    implicitWidth: 300
    implicitHeight: 190
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "eyecandy_weather"

    // WMO weather codes → an emoji and a word
    function describe(code) {
        if (code === 0) return ["☀️", "Clear"];
        if (code <= 2) return ["⛅", "Partly cloudy"];
        if (code === 3) return ["☁️", "Cloudy"];
        if (code <= 48) return ["🌫️", "Fog"];
        if (code <= 67) return ["🌧️", "Rain"];
        if (code <= 77) return ["❄️", "Snow"];
        if (code <= 82) return ["🌦️", "Showers"];
        return ["⛈️", "Storm"];
    }

    // 1. the city's coordinates
    Process {
        id: geocode
        running: true
        command: ["curl", "-sf", "--max-time", "10", "https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(root.city)]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text).results[0];
                    root.lat = r.latitude;
                    root.lon = r.longitude;
                    forecast.running = true;
                } catch (e) { console.warn("[Weather] city not found:", root.city); }
            }
        }
    }
    // 2. the forecast
    Process {
        id: forecast
        command: ["curl", "-sf", "--max-time", "10",
            `https://api.open-meteo.com/v1/forecast?latitude=${root.lat}&longitude=${root.lon}`
            + "&current=temperature_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=4"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.current = { temperature: d.current.temperature_2m, code: d.current.weather_code, wind: d.current.wind_speed_10m };
                    root.days = d.daily.time.slice(1).map((t, i) => ({
                        day: new Date(t).toLocaleDateString(Qt.locale(), "ddd"),
                        max: d.daily.temperature_2m_max[i + 1], min: d.daily.temperature_2m_min[i + 1],
                        code: d.daily.weather_code[i + 1]
                    }));
                } catch (e) { console.warn("[Weather] bad answer"); }
            }
        }
    }
    Timer { interval: 30 * 60 * 1000; running: root.lat !== 0; repeat: true; onTriggered: forecast.running = true }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Qt.alpha("#1a1b26", 0.75)
        border.color: Qt.alpha("white", 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            visible: root.current !== null
            RowLayout {
                Text { text: root.current ? root.describe(root.current.code)[0] : ""; font.pixelSize: 46 }
                ColumnLayout {
                    spacing: 0
                    Text { text: root.current ? Math.round(root.current.temperature) + "°" : ""; color: "white"; font.pixelSize: 38; font.bold: true }
                    Text { text: root.current ? root.describe(root.current.code)[1] + " · " + root.city : ""; color: Qt.alpha("white", 0.7); font.pixelSize: 13 }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Repeater {
                    model: root.days
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        Text { Layout.alignment: Qt.AlignHCenter; text: parent.modelData.day; color: Qt.alpha("white", 0.6); font.pixelSize: 12 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: root.describe(parent.modelData.code)[0]; font.pixelSize: 20 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: Math.round(parent.modelData.max) + "° " + Math.round(parent.modelData.min) + "°"; color: "white"; font.pixelSize: 12 }
                    }
                }
            }
        }
        Text { anchors.centerIn: parent; visible: root.current === null; text: "Loading weather…"; color: Qt.alpha("white", 0.6) }
    }
}
