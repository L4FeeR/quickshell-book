import QtQuick

// The theme's colours and the settings from theme.conf, in one object the
// other components receive. SDDM hands config values over as text, so the
// numbers and booleans are converted here.
QtObject {
    property var conf                                   // SDDM's `config`

    readonly property color accent: conf.accent || "#7aa2f7"
    readonly property color base: "#1a1b26"
    readonly property color surface: "#24283b"
    readonly property color raised: "#292e42"
    readonly property color border: "#414868"
    readonly property color text: "#c0caf5"
    readonly property color subtext: "#a9b1d6"
    readonly property color muted: "#545c7e"
    readonly property color error: "#f7768e"
    readonly property color warning: "#e0af68"

    readonly property string font: conf.font || "Inter"
    readonly property real blur: Number(conf.blur ?? 0.6)
    readonly property real dim: Number(conf.dim ?? 0.15)
    readonly property string clockFormat: conf.clockFormat || "hh:mm"
    readonly property string dateFormat: conf.dateFormat || "dddd, d MMMM"
    readonly property bool showUsers: String(conf.showUsers ?? "true") === "true"
}
