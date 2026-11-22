import QtQuick

Item {
    id: root
    property int count: 0            // bind to Notifs.count from your service
    property bool dnd: false         // bind to GlobalStates.dnd
    signal clicked()

    implicitWidth: 32; implicitHeight: 26

    onCountChanged: if (count > 0) ring.restart()

    Text {
        id: bell
        anchors.centerIn: parent
        text: root.dnd ? "notifications_off" : root.count > 0 ? "notifications_unread" : "notifications"
        font.family: "Material Symbols Rounded"
        font.pixelSize: 20
        color: "#cdd6f4"
        transformOrigin: Item.Top
        SequentialAnimation {
            id: ring
            RotationAnimation { target: bell; to: 18; duration: 70 }
            RotationAnimation { target: bell; to: -16; duration: 110 }
            RotationAnimation { target: bell; to: 10; duration: 90 }
            RotationAnimation { target: bell; to: -6; duration: 80 }
            RotationAnimation { target: bell; to: 0; duration: 70 }
        }
    }
    Rectangle {                                     // badge
        visible: root.count > 0 && !root.dnd
        anchors { right: parent.right; top: parent.top; rightMargin: -2; topMargin: -2 }
        width: Math.max(14, badgeText.implicitWidth + 6); height: 14; radius: 7
        color: "#f38ba8"
        scale: visible ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        Text { id: badgeText; anchors.centerIn: parent; text: root.count > 9 ? "9+" : root.count; color: "#1e1e2e"; font.pixelSize: 9; font.bold: true }
    }
    TapHandler { onTapped: root.clicked() }
}
