import QtQuick

// Which drawers are open on ONE screen. Every monitor gets its own instance.
QtObject {
    property bool bar: false         // shown when the bar isn't persistent
    property bool dashboard: false
    property bool launcher: false
    property bool session: false
    property bool sidebar: false
    property bool osd: false
    property bool utilities: false
}
