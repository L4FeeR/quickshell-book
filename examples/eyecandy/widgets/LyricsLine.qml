import QtQuick
import qs.services

// The current lyric on one line, for a bar or a small overlay. Each new line
// slides up and fades in, replacing the old one.
Item {
    id: root

    property color color: "white"
    property int fontSize: 13
    property string fontFamily: "Inter"
    implicitWidth: Math.min(420, label.implicitWidth)
    implicitHeight: label.implicitHeight
    visible: Lyrics.currentText !== ""
    clip: true

    Text {
        id: label
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        text: Lyrics.currentText
    }

    // a new line: start a little lower and transparent, then move into place
    Connections {
        target: Lyrics
        function onCurrentTextChanged() { enter.restart(); }
    }
    ParallelAnimation {
        id: enter
        NumberAnimation { target: label; property: "y"; from: root.height * 0.6; to: 0; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: label; property: "opacity"; from: 0; to: 1; duration: 300 }
    }
}
