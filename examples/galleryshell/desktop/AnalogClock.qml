import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    anchors { top: true; right: true }
    margins { top: 120; right: 120 }
    implicitWidth: 220; implicitHeight: 220
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Bottom

    SystemClock { id: clock; precision: SystemClock.Seconds }

    component Hand: Rectangle {                          // rotated by a `transform` at each use
        property real len
        x: face.width / 2 - width / 2
        y: face.height / 2 - len
        height: len + 10                                  // a bit of tail past the center
        radius: width / 2
    }

    Rectangle {
        id: face
        anchors.fill: parent
        anchors.margins: 10
        radius: width / 2
        color: "#1e1e2e"; border.color: "#45475a"; border.width: 2

        Repeater {                                        // hour ticks
            model: 12
            Rectangle {
                required property int index
                x: face.width / 2 - width / 2; y: 8
                width: index % 3 === 0 ? 4 : 2; height: index % 3 === 0 ? 12 : 6; radius: 2
                color: "#585b70"
                transform: Rotation { origin.x: width / 2; origin.y: face.height / 2 - 8; angle: index * 30 }
            }
        }
        Hand { width: 7; len: face.width * 0.26; color: "#cdd6f4"
               transform: Rotation { origin.x: 3.5; origin.y: face.width * 0.26; angle: (clock.hours % 12 + clock.minutes / 60) * 30 } }
        Hand { width: 5; len: face.width * 0.38; color: "#cdd6f4"
               transform: Rotation { origin.x: 2.5; origin.y: face.width * 0.38; angle: (clock.minutes + clock.seconds / 60) * 6 } }
        Hand {
            id: sec
            width: 2; len: face.width * 0.42; color: "#f38ba8"
            property real a: clock.seconds * 6
            Behavior on a { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }   // "tick" with a little bounce
            transform: Rotation { origin.x: 1; origin.y: face.width * 0.42; angle: sec.a }
        }
        Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: "#f38ba8" }
    }
}
