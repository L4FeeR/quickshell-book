import QtQuick

// The pattern behind every Caelestia drawer. The wrapper's size along the slide direction
// grows from 0 to the content's size as `offsetScale` goes 1 -> 0, and it clips, so the
// content appears to slide out from behind the frame edge.
Item {
    id: root

    property bool open: false
    property string edge: "top"         // the frame edge it comes out of
    property real offsetScale: open ? 0 : 1
    default property alias content: holder.data

    readonly property Item contentItem: holder.children.length > 0 ? holder.children[0] : null
    readonly property bool horizontal: edge === "top" || edge === "bottom"
    readonly property real contentWidth: contentItem?.implicitWidth ?? 0
    readonly property real contentHeight: contentItem?.implicitHeight ?? 0

    implicitWidth: horizontal ? contentWidth : contentWidth * (1 - offsetScale)
    implicitHeight: horizontal ? contentHeight * (1 - offsetScale) : contentHeight
    visible: offsetScale < 1
    clip: true

    Behavior on offsetScale {
        Anim { type: root.open ? Anim.Spatial : Anim.Emphasized }
    }

    Item {
        id: holder

        width: root.contentWidth
        height: root.contentHeight
        // keep the content glued to the side away from the edge, so it slides in
        x: root.edge === "left" ? root.width - width : 0
        y: root.edge === "top" ? root.height - height : 0
        opacity: 1 - root.offsetScale * 0.6
    }
}
