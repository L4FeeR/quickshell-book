import QtQuick

// A Rectangle whose colour changes fade, so switching themes animates instead of snapping.
Rectangle {
    color: "transparent"
    Behavior on color {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    Behavior on border.color {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
}
