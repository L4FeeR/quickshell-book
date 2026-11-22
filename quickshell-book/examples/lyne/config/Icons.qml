pragma Singleton
import QtQuick
import Quickshell

// Icon glyphs from the Nerd Font (its Material Design range, "nf-md-…").
// lyne-dots writes the codes inline ("\u{f057e}"); naming them here keeps
// the widgets readable. Find more at nerdfonts.com/cheat-sheet.
Singleton {
    readonly property string apps: "\u{f003b}"
    readonly property string magnify: "\u{f0349}"
    readonly property string lightning: "\u{f140b}"
    readonly property string calculator: "\u{f00ec}"
    readonly property string clipboard: "\u{f014d}"
    readonly property string copy: "\u{f018f}"
    readonly property string close: "\u{f0156}"
    readonly property string check: "\u{f012c}"
    readonly property string chevronLeft: "\u{f0141}"
    readonly property string chevronRight: "\u{f0142}"
    readonly property string chevronDown: "\u{f0140}"
    readonly property string chevronUp: "\u{f0143}"
    readonly property string back: "\u{f004d}"
    readonly property string cog: "\u{f0493}"
    readonly property string trash: "\u{f09e7}"
    readonly property string star: "\u{f04ce}"
    readonly property string starOutline: "\u{f04d2}"

    readonly property var wifi: ["\u{f092e}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]   // 0 = none … 4 = full
    readonly property string wifiOff: "\u{f05aa}"
    readonly property string ethernet: "\u{f0200}"
    readonly property string bluetooth: "\u{f00af}"
    readonly property string bluetoothOff: "\u{f00b2}"
    readonly property string volumeHigh: "\u{f057e}"
    readonly property string volumeMute: "\u{f075f}"
    readonly property string mic: "\u{f036c}"
    readonly property string micOff: "\u{f036d}"
    readonly property string brightness: "\u{f00df}"
    readonly property string battery: "\u{f0079}"
    readonly property string batteryHalf: "\u{f007e}"
    readonly property string batteryLow: "\u{f007b}"
    readonly property string batteryAlert: "\u{f0083}"
    readonly property string batteryCharging: "\u{f0084}"

    readonly property string bell: "\u{f009a}"
    readonly property string bellBadge: "\u{f116b}"
    readonly property string bellOff: "\u{f009b}"
    readonly property string clearAll: "\u{f039f}"
    readonly property string coffee: "\u{f0176}"
    readonly property string coffeeOutline: "\u{f06ca}"
    readonly property string night: "\u{f0594}"
    readonly property string palette: "\u{f03d8}"
    readonly property string themeMode: "\u{f050e}"

    readonly property string lock: "\u{f033e}"
    readonly property string power: "\u{f0425}"
    readonly property string restart: "\u{f0709}"
    readonly property string sleep: "\u{f04b2}"
    readonly property string logout: "\u{f0343}"

    readonly property string play: "\u{f040a}"
    readonly property string pause: "\u{f03e4}"
    readonly property string next: "\u{f04ad}"
    readonly property string previous: "\u{f04ae}"
    readonly property string music: "\u{f075a}"

    readonly property string cpu: "\u{f0ee0}"
    readonly property string memory: "\u{f035b}"
    readonly property string disk: "\u{f02ca}"
    readonly property string temperature: "\u{f050f}"
    readonly property string clock: "\u{f0150}"
    readonly property string calendar: "\u{f00ed}"

    readonly property string screenshot: "\u{f0e51}"
    readonly property string region: "\u{f0a6d}"
    readonly property string window: "\u{f05af}"
    readonly property string screen: "\u{f0293}"
    readonly property string image: "\u{f02e9}"
    readonly property string wallpaper: "\u{f0e09}"
    readonly property string tray: "\u{f1294}"
    readonly property string keyboard: "\u{f030c}"

    readonly property string saver: "\u{f032a}"
    readonly property string balanced: "\u{f05d1}"
    readonly property string performance: "\u{f04c5}"
}
