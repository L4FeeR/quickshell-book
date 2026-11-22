import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// The main tab: user card, big clock, calendar, now playing and resource bars in a grid.
GridLayout {
    columns: 3
    rowSpacing: Tokens.spacing.small
    columnSpacing: Tokens.spacing.small

    // user: avatar, name@host, uptime
    Card {
        Layout.columnSpan: 2
        Layout.preferredWidth: 360
        Layout.preferredHeight: 110

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.large

            ClippingRectangle {
                implicitWidth: 78; implicitHeight: 78
                radius: Tokens.rounding.full
                color: Colours.palette.m3primaryContainer
                Image {
                    anchors.fill: parent
                    source: "file://" + Config.paths.face
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(156, 156)
                }
            }
            ColumnLayout {
                spacing: 2
                StyledText { text: Quickshell.env("USER"); font.pixelSize: Tokens.font.size.large; font.weight: 600 }
                StyledText { text: "up " + SysInfo.uptime; color: Colours.palette.m3onSurfaceVariant }
            }
            Item { Layout.fillWidth: true }
        }
    }

    // big vertical clock
    Card {
        Layout.rowSpan: 2
        Layout.preferredWidth: 110
        Layout.fillHeight: true

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            StyledText { Layout.alignment: Qt.AlignHCenter; text: Time.format("hh"); font.pixelSize: 44; font.weight: 700; color: Colours.palette.m3primary }
            StyledText { Layout.alignment: Qt.AlignHCenter; text: "•••"; color: Colours.palette.m3outline }
            StyledText { Layout.alignment: Qt.AlignHCenter; text: Time.format("mm"); font.pixelSize: 44; font.weight: 700; color: Colours.palette.m3primary }
            StyledText { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Tokens.spacing.small; text: Time.format("ddd, d"); color: Colours.palette.m3onSurfaceVariant }
        }
    }

    // calendar
    Card {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 200
        Calendar { anchors.centerIn: parent }
    }

    // resources: CPU / RAM / disk vertical bars
    Card {
        Layout.preferredWidth: 134
        Layout.preferredHeight: 200

        Row {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium
            Repeater {
                model: [["memory", SysInfo.cpu], ["memory_alt", SysInfo.mem], ["hard_drive", SysInfo.disk]]
                Column {
                    required property var modelData
                    spacing: Tokens.spacing.small
                    StyledRect {
                        width: 10; height: 140
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3surfaceContainerHighest
                        StyledRect {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * Math.min(1, modelData[1])
                            radius: parent.radius
                            color: modelData[1] > 0.85 ? Colours.palette.m3error : Colours.palette.m3primary
                            Behavior on height { Anim {} }
                        }
                    }
                    MaterialIcon { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; font.pixelSize: Tokens.font.size.normal }
                }
            }
        }
    }

    // now playing
    Card {
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        visible: Players.active !== null

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            ClippingRectangle {
                implicitWidth: 66; implicitHeight: 66
                radius: Tokens.rounding.full
                color: Colours.palette.m3secondaryContainer
                Image {
                    anchors.fill: parent
                    source: Players.active?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(132, 132)
                }
                RotationAnimation on rotation {
                    running: Players.active?.isPlaying ?? false
                    from: 0; to: 360; duration: 12000; loops: Animation.Infinite
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText { Layout.fillWidth: true; text: Players.active?.trackTitle ?? ""; elide: Text.ElideRight; font.weight: 600 }
                StyledText { Layout.fillWidth: true; text: Players.active?.trackArtist ?? ""; elide: Text.ElideRight; color: Colours.palette.m3onSurfaceVariant }
            }
            IconButton { icon: "skip_previous"; onClicked: Players.active.previous() }
            IconButton { icon: Players.active?.isPlaying ? "pause" : "play_arrow"; toggle: true; checked: true; onClicked: Players.active.togglePlaying() }
            IconButton { icon: "skip_next"; onClicked: Players.active.next() }
        }
    }
}
