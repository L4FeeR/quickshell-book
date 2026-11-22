import QtQuick

// A Rectangle whose colour changes always fade. Transparent by default.
Rectangle {
    color: "transparent"

    Behavior on color {
        CAnim {}
    }
}
