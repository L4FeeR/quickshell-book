import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// The media tab: big cover art, track info, a seek slider, controls and the player list.
RowLayout {
    id: root

    readonly property MprisPlayer p: Players.active

    implicitWidth: 640
    spacing: Tokens.spacing.large

    ClippingRectangle {
        implicitWidth: 200; implicitHeight: 200
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        Image {
            anchors.fill: parent
            source: root.p?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(400, 400)
        }
        MaterialIcon {
            anchors.centerIn: parent
            visible: !root.p?.trackArtUrl
            text: "music_note"
            font.pixelSize: 64
            color: Colours.palette.m3outline
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText { Layout.fillWidth: true; text: root.p?.trackTitle || "Nothing playing"; elide: Text.ElideRight; font.pixelSize: Tokens.font.size.large; font.weight: 600 }
        StyledText { Layout.fillWidth: true; text: root.p?.trackArtist ?? ""; elide: Text.ElideRight; color: Colours.palette.m3secondary }
        StyledText { Layout.fillWidth: true; text: root.p?.trackAlbum ?? ""; elide: Text.ElideRight; color: Colours.palette.m3outline }

        Slider {
            Layout.fillWidth: true
            enabled: root.p?.canSeek ?? false
            from: 0
            to: Math.max(1, root.p?.length ?? 1)
            value: root.p?.position ?? 0
            onMoved: root.p.position = value
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.medium
            IconButton { icon: "skip_previous"; onClicked: Players.active?.previous() }
            IconButton { icon: Players.active?.isPlaying ? "pause" : "play_arrow"; size: 56; toggle: true; checked: true; onClicked: Players.active?.togglePlaying() }
            IconButton { icon: "skip_next"; onClicked: Players.active?.next() }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
            Repeater {
                model: Players.list
                StyledRect {
                    required property MprisPlayer modelData
                    implicitWidth: name.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: 30
                    radius: Tokens.rounding.full
                    color: modelData === Players.active ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer
                    StyledText { id: name; anchors.centerIn: parent; text: parent.modelData.identity }
                    StateLayer { onClicked: Players.manual = parent.modelData }
                }
            }
        }
    }
}
