pragma Singleton
import Quickshell
import QtQuick

// Colour helpers used to build the layered palette.
Singleton {
    // p = 1 gives c1, p = 0 gives c2
    function mix(c1: color, c2: color, p: real): color {
        return Qt.rgba(c1.r * p + c2.r * (1 - p), c1.g * p + c2.g * (1 - p), c1.b * p + c2.b * (1 - p), c1.a * p + c2.a * (1 - p));
    }
    // amount = 0 keeps the colour, 1 makes it fully transparent
    function transparentize(c: color, amount: real): color {
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - amount));
    }
    function applyAlpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
