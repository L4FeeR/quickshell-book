import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components

// A horizontal strip of wallpaper thumbnails for ">wallpaper". Click (or Enter) applies one.
ListView {
    id: root

    property string filter: ""
    signal picked()

    function pickCurrent(): void {
        if (currentIndex >= 0 && count > 0) {
            Wallpapers.set(model[currentIndex]);
            picked();
        }
    }

    height: 150
    orientation: ListView.Horizontal
    spacing: Tokens.spacing.small
    clip: true
    model: Wallpapers.list.filter(f => f.toLowerCase().includes(root.filter.toLowerCase()))
    highlightMoveDuration: Tokens.anim.durations.fastSpatial

    delegate: ClippingRectangle {
        required property string modelData
        required property int index
        width: 200
        height: root.height
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer
        border.width: modelData === Wallpapers.current ? 3 : 0
        border.color: Colours.palette.m3primary

        Image {
            anchors.fill: parent
            source: "file://" + parent.modelData
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(400, 300)
            asynchronous: true
        }
        StateLayer {
            onEntered: root.currentIndex = parent.index
            onClicked: { Wallpapers.set(parent.modelData); root.picked(); }
        }
    }
}
