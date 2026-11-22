import QtQuick

// A squash-and-stretch "jelly" effect for any item. Put it inside the item:
//   Rectangle { …; Stretch { id: jelly } }       then call jelly.press() / jelly.release()
// or let it handle the mouse itself with `handleMouse: true`.
// Pressing squashes the item (wider and flatter); releasing makes it spring
// back past its size and wobble to rest. poke() does a quick squash and
// release in one go, for keys and events.
Item {
    id: root

    property Item item: parent             // the item to deform
    property real amount: 0.12             // how far it squashes (0.12 = 12%)
    property bool handleMouse: false
    signal clicked

    anchors.fill: parent

    // Two scales: x and y. Squash makes x bigger and y smaller, so the area
    // looks constant, like something soft being pressed.
    Scale {
        id: deform
        origin.x: root.item.width / 2
        origin.y: root.item.height / 2
        xScale: 1
        yScale: 1
    }
    Component.onCompleted: root.item.transform = [deform]

    function press() {
        spring.stop();
        squash.restart();
    }
    function release() {
        squash.stop();
        spring.restart();
    }
    function poke(strength) {               // a quick squash-and-release
        const a = root.amount * (strength ?? 0.6);
        squash.stop();
        deform.xScale = 1 + a;
        deform.yScale = 1 - a;
        spring.restart();
    }

    // press: squash over 90 ms
    ParallelAnimation {
        id: squash
        NumberAnimation { target: deform; property: "xScale"; to: 1 + root.amount; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: deform; property: "yScale"; to: 1 - root.amount; duration: 90; easing.type: Easing.OutQuad }
    }
    // release: spring back. OutElastic overshoots and wobbles, like jelly.
    ParallelAnimation {
        id: spring
        NumberAnimation { target: deform; property: "xScale"; to: 1; duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 1.2; easing.period: 0.35 }
        NumberAnimation { target: deform; property: "yScale"; to: 1; duration: 700; easing.type: Easing.OutElastic; easing.amplitude: 1.2; easing.period: 0.35 }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.handleMouse
        cursorShape: Qt.PointingHandCursor
        onPressed: root.press()
        onReleased: root.release()
        onCanceled: root.release()
        onClicked: root.clicked()
    }
}
