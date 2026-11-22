import QtQuick
import qs.services

// Scrolling synced lyrics, karaoke style: the line being sung is big, bright
// and centred, and fills with the accent colour as it's sung; the others are
// smaller and dim. The list glides to each new line.
Item {
    id: root

    property color color: "white"
    property color accent: "#7aa2f7"
    property int fontSize: 22
    property string fontFamily: "Inter"
    clip: true

    ListView {
        id: view
        anchors.fill: parent
        model: Lyrics.lines
        currentIndex: Math.max(0, Lyrics.current)
        interactive: false
        spacing: 14
        // keep the current line in the middle of the view
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: height / 2 - root.fontSize
        preferredHighlightEnd: height / 2 + root.fontSize
        highlightMoveDuration: 450

        delegate: Item {
            id: line
            required property var modelData
            required property int index
            readonly property bool active: index === Lyrics.current
            readonly property int distance: Math.abs(index - Lyrics.current)
            width: ListView.view.width
            height: label.implicitHeight

            // the line: white for the part not yet sung…
            Text {
                id: label
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: line.modelData.text || "♪"
                font.family: root.fontFamily
                font.pixelSize: line.active ? root.fontSize * 1.25 : root.fontSize
                font.bold: line.active
                color: root.color
                // lines further from the current one fade out
                opacity: line.active ? 1 : Math.max(0.15, 0.55 - line.distance * 0.12)
                Behavior on font.pixelSize { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
            // …and the same text in the accent, clipped to the part already sung.
            // The text is centred, so the clip starts where the text starts.
            Item {
                visible: line.active
                width: (label.width - label.contentWidth) / 2 + label.contentWidth * Lyrics.lineProgress
                height: label.height
                clip: true
                Text {
                    width: label.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: label.text
                    font: label.font
                    color: root.accent
                }
            }
        }
    }

    // when there are no synced lyrics
    Text {
        anchors.centerIn: parent
        visible: Lyrics.lines.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: root.color
        opacity: 0.6
        font.family: root.fontFamily
        font.pixelSize: root.fontSize * 0.8
        text: Lyrics.status === "loading" ? "Looking for lyrics…"
            : Lyrics.instrumental ? "♪ Instrumental ♪"
            : Lyrics.status === "none" ? "No lyrics found"
            : Lyrics.plain !== "" ? "Only unsynced lyrics for this song"
            : ""
    }
}
