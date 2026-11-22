import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Small round buttons: screenshot region, colour picker, mic mute.
RowLayout {
    spacing: 4

    component Util: RippleButton {
        id: util
        property string symbol
        implicitWidth: 26
        implicitHeight: 26
        buttonRadius: Appearance.rounding.full
        colBackground: Appearance.colors.colLayer2
        contentItem: MaterialSymbol {
            horizontalAlignment: Text.AlignHCenter
            text: util.symbol
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer2
        }
    }

    Util { symbol: "screenshot_region"; onClicked: Quickshell.execDetached(["sh", "-c", "grim -g \"$(slurp)\" - | wl-copy"]) }
    Util { symbol: "colorize"; onClicked: Quickshell.execDetached(["hyprpicker", "-a"]) }
    Util { symbol: Audio.micMuted ? "mic_off" : "mic"; onClicked: Audio.toggleMicMute() }
}
