import QtQuick

// Ripples for typing: attach it to a TextInput (or TextField) and every key
// sends a ripple out from the caret. Deleting sends a smaller ring; Enter a
// big one; call shake("red") for a failure shockwave.
//   Item {
//       TextInput { id: field; … }
//       TypingRipple { target: field; anchors.fill: parent }
//   }
// The ripple layer fills the TypingRipple; place it where the effect may spread.
Item {
    id: root

    required property var target           // a TextInput, TextField, or anything with text and cursorRectangle
    property color tint: "#7aa2f7"
    property color deleteTint: "#bb9af7"
    property real keySize: 90
    property bool randomTints: false       // a different colour from `tints` per key
    property var tints: ["#7aa2f7", "#bb9af7", "#7dcfff", "#9ece6a", "#e0af68", "#f7768e"]

    property int lastLength: target.text.length

    RippleLayer { id: ripples; anchors.fill: parent }

    // the caret's centre, in this item's coordinates
    function caret() {
        const r = target.cursorRectangle;
        return target.mapToItem(root, r.x + r.width / 2, r.y + r.height / 2);
    }

    // Inside textChanged, Qt hasn't laid out the new text yet, so the caret
    // position is still stale (an empty rectangle). Qt.callLater runs the
    // ripple a moment later, once the caret has moved.
    function _typed(deleted) {
        const p = root.caret();
        if (deleted) {
            ripples.burst(p.x, p.y, { tint: root.deleteTint, endSize: root.keySize * 0.6, ring: true, duration: 400 });
        } else {
            const t = root.randomTints ? root.tints[Math.floor(Math.random() * root.tints.length)] : root.tint;
            ripples.burst(p.x, p.y, { tint: t, endSize: root.keySize, duration: 500 });
        }
    }

    Connections {
        target: root.target
        function onTextChanged() {
            const now = root.target.text.length;
            if (now !== root.lastLength)
                Qt.callLater(root._typed, now < root.lastLength);
            root.lastLength = now;
        }
        function onAccepted() {                   // Enter
            const p = root.caret();
            ripples.burst(p.x, p.y, { tint: root.tint, endSize: Math.max(root.width, root.height) * 2.5, ring: true, duration: 800, startOpacity: 0.6 });
        }
    }

    // a red shockwave over the whole area, for "wrong password" and the like
    function shake(colour) {
        ripples.flood({ tint: colour ?? "#f7768e", ring: true, duration: 700, startOpacity: 0.8 });
        ripples.flood({ tint: colour ?? "#f7768e", duration: 500, startOpacity: 0.25 });
    }
}
