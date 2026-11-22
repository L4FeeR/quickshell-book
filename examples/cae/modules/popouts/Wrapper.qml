import QtQuick
import qs.config
import qs.components

// The popout next to the bar. The bar sets `currentName` ("audio", "network", "bluetooth",
// "battery") and `currentCenter` (the hovered icon's y); the drawer slides out from the bar
// and morphs its size when you move between icons.
DrawerWrapper {
    id: root

    property string currentName: ""
    property real currentCenter: 0
    property bool hasCurrent: false

    edge: "left"
    open: hasCurrent

    Item {
        implicitWidth: page.implicitWidth + Tokens.padding.large * 2
        implicitHeight: page.implicitHeight + Tokens.padding.large * 2

        Behavior on implicitWidth { Anim { type: Anim.FastSpatial } }
        Behavior on implicitHeight { Anim { type: Anim.FastSpatial } }

        Loader {
            id: page
            anchors.centerIn: parent
            sourceComponent: ({ audio: audio, network: network, bluetooth: bluetooth, battery: battery })[root.currentName] ?? null
        }
    }

    Component { id: audio; AudioPopout {} }
    Component { id: network; NetworkPopout {} }
    Component { id: bluetooth; BluetoothPopout {} }
    Component { id: battery; BatteryPopout {} }
}
