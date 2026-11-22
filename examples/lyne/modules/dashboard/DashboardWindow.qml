import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config
import qs.services
import qs.components

// The dashboard under the bar clock, with three tabs:
//   Overview  big clock, a month calendar and the player
//   Media     the player, large, with a progress bar
//   System    CPU, memory and disk usage
// Ctrl+Tab switches tabs; the panel's height follows the tab.
AttachedPopup {
    id: root

    required property string screenName

    shown: DashboardService.visible && DashboardService.screenName === screenName
    onDismissed: DashboardService.close()
    panelWidth: 520
    panelHeight: tabsColumn.implicitHeight + Config.spacing * 4
    Behavior on panelHeight { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    SystemClock { id: clock; precision: SystemClock.Seconds }

    function stepTab(d) {
        const t = DashboardService.tabs;
        DashboardService.tab = t[(t.indexOf(DashboardService.tab) + d + t.length) % t.length];
    }

    ColumnLayout {
        id: tabsColumn
        anchors.fill: parent
        anchors.margins: Config.spacing * 2
        spacing: Config.spacing
        focus: true
        Keys.onTabPressed: e => { if (e.modifiers & Qt.ControlModifier) root.stepTab(1); }
        Keys.onBacktabPressed: root.stepTab(-1)

        // ── tab bar: the active tab's pill slides under its label ──
        Item {
            Layout.fillWidth: true
            implicitHeight: 32
            Rectangle {
                width: parent.width / 3
                height: parent.height
                x: DashboardService.tabs.indexOf(DashboardService.tab) * width
                radius: height / 2
                color: Config.surface1Color
                Behavior on x { NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutCubic } }
            }
            Row {
                anchors.fill: parent
                Repeater {
                    model: [["overview", "Overview", Icons.calendar], ["media", "Media", Icons.music], ["system", "System", Icons.cpu]]
                    Item {
                        id: tabItem
                        required property var modelData
                        width: parent.width / 3
                        height: parent.height
                        Row {
                            anchors.centerIn: parent
                            spacing: Config.padding
                            Glyph { text: tabItem.modelData[2]; color: DashboardService.tab === tabItem.modelData[0] ? Config.accentColor : Config.subtextColor }
                            StyledText { text: tabItem.modelData[1]; font.pixelSize: Config.fontSizeSmall; color: DashboardService.tab === tabItem.modelData[0] ? Config.textColor : Config.subtextColor }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: DashboardService.tab = tabItem.modelData[0] }
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            sourceComponent: ({ overview: overviewTab, media: mediaTab, system: systemTab })[DashboardService.tab]
        }
    }

    // ── Player controls, used by two tabs ──
    component PlayerControls: Row {
        spacing: Config.spacing
        BarButton { onClicked: root.player?.previous(); Glyph { text: Icons.previous } }
        BarButton { onClicked: root.player?.togglePlaying(); Glyph { text: root.player?.isPlaying ? Icons.pause : Icons.play; color: Config.accentColor } }
        BarButton { onClicked: root.player?.next(); Glyph { text: Icons.next } }
    }

    component PlayerCard: Card {
        implicitHeight: 96
        RowLayout {
            anchors.fill: parent
            anchors.margins: Config.spacing
            spacing: Config.spacing
            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                radius: Config.radius
                color: Config.surface1Color
                clip: true
                Image { anchors.fill: parent; source: root.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                Glyph { anchors.centerIn: parent; visible: !(root.player?.trackArtUrl); text: Icons.music; color: Config.mutedColor }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText { Layout.fillWidth: true; text: root.player?.trackTitle || "Nothing playing"; font.bold: true }
                StyledText { Layout.fillWidth: true; text: root.player?.trackArtist ?? ""; font.pixelSize: Config.fontSizeSmall; color: Config.subtextColor }
                PlayerControls { visible: root.player !== null }
            }
        }
    }

    // ── Overview ──
    Component {
        id: overviewTab
        RowLayout {
            spacing: Config.spacing
            ColumnLayout {
                Layout.preferredWidth: 220; Layout.maximumWidth: 220; Layout.fillWidth: false   // fixed column: the calendar takes the rest
                Layout.alignment: Qt.AlignTop
                spacing: Config.spacing
                Card {
                    Layout.fillWidth: true
                    implicitHeight: 110
                    Column {
                        anchors.centerIn: parent
                        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clock.date, "hh:mm"); font.pixelSize: 44; font.bold: true }
                        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clock.date, "dddd, d MMMM"); color: Config.subtextColor; font.pixelSize: Config.fontSizeSmall }
                    }
                }
                PlayerCard { Layout.fillWidth: true }
            }
            Card {                                           // month calendar
                id: cal
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                implicitHeight: 214
                readonly property date first: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
                readonly property int lead: (first.getDay() + 6) % 7          // Monday first
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Config.spacing
                    StyledText { text: Qt.formatDateTime(clock.date, "MMMM yyyy"); font.bold: true }
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: 0
                        columnSpacing: 0
                        Repeater {
                            model: ["M", "T", "W", "T", "F", "S", "S"]
                            StyledText { required property string modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Config.mutedColor; font.pixelSize: Config.fontSizeSmall }
                        }
                        Repeater {
                            model: 42
                            Rectangle {
                                required property int index
                                readonly property date day: new Date(cal.first.getFullYear(), cal.first.getMonth(), 1 - cal.lead + index)
                                readonly property bool today: day.toDateString() === clock.date.toDateString()
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: height / 2
                                color: today ? Config.accentColor : "transparent"
                                StyledText {
                                    anchors.centerIn: parent
                                    text: parent.day.getDate()
                                    font.pixelSize: Config.fontSizeSmall
                                    color: parent.today ? Config.textReverseColor : parent.day.getMonth() === clock.date.getMonth() ? Config.textColor : Config.mutedColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Media ──
    Component {
        id: mediaTab
        ColumnLayout {
            spacing: Config.spacing
            PlayerCard { Layout.fillWidth: true; implicitHeight: 120 }
            // position: MPRIS doesn't push updates, so we ask once a second
            Timer { running: root.player?.isPlaying ?? false; interval: 1000; repeat: true; onTriggered: root.player.positionChanged() }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Config.surface1Color
                visible: (root.player?.length ?? 0) > 0
                Rectangle {
                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                    height: parent.height
                    radius: 3
                    color: Config.accentColor
                }
            }
        }
    }

    // ── System ──
    // CPU from /proc/stat (time spent busy between two reads), memory from
    // /proc/meminfo, disk from df. Files in /proc are read without a process.
    Component {
        id: systemTab
        ColumnLayout {
            id: sys
            spacing: Config.spacing
            property real cpu: 0
            property real mem: 0
            property real disk: 0
            property var last: null

            FileView { id: stat; path: "/proc/stat" }
            FileView { id: meminfo; path: "/proc/meminfo" }
            Process {
                id: df
                command: ["df", "--output=pcent", "/"]
                stdout: StdioCollector { onStreamFinished: sys.disk = parseInt(text.split("\n")[1]) / 100 }
            }
            Timer {
                interval: 1500
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    stat.reload();
                    meminfo.reload();
                    df.running = true;
                    const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
                    const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
                    if (sys.last)
                        sys.cpu = 1 - (idle - sys.last.idle) / Math.max(1, total - sys.last.total);
                    sys.last = { idle: idle, total: total };
                    const m = k => Number((meminfo.text().match(new RegExp(k + ":\\s+(\\d+)")) ?? [0, 0])[1]);
                    sys.mem = 1 - m("MemAvailable") / Math.max(1, m("MemTotal"));
                }
            }

            Repeater {
                model: [[Icons.cpu, "CPU"], [Icons.memory, "Memory"], [Icons.disk, "Disk"]]
                Card {
                    id: statCard
                    required property var modelData
                    required property int index
                    readonly property real value: [sys.cpu, sys.mem, sys.disk][index]
                    Layout.fillWidth: true
                    implicitHeight: 52
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Config.spacing
                        spacing: Config.spacing
                        Glyph { text: statCard.modelData[0]; color: Config.accentColor }
                        StyledText { Layout.preferredWidth: 70; text: statCard.modelData[1]; font.pixelSize: Config.fontSizeSmall }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 8
                            radius: 4
                            color: Config.surface1Color
                            Rectangle {
                                width: parent.width * statCard.value
                                height: parent.height
                                radius: 4
                                color: statCard.value > 0.85 ? Config.errorColor : Config.accentColor
                                Behavior on width { NumberAnimation { duration: Config.animDurationLong } }
                            }
                        }
                        StyledText { Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight; text: Math.round(statCard.value * 100) + "%"; font.pixelSize: Config.fontSizeSmall }
                    }
                }
            }
        }
    }
}
