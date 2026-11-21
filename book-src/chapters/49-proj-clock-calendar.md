# Project: Clock and Calendar Popup

A clock in the center of the bar; click it and a Material-style calendar drops down with month navigation, today highlighted, week numbers and an optional events list.

## Time service

One shared clock for the whole shell:

```qml file="services/Time.qml"
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property bool showSeconds: Config.bar.showSeconds ?? false
    property bool use24h: Config.bar.use24h ?? true

    SystemClock {
        id: clock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
    readonly property date now: clock.date
    readonly property string time: Qt.formatDateTime(clock.date,
        (use24h ? "hh:mm" : "h:mm") + (showSeconds ? ":ss" : "") + (use24h ? "" : " AP"))
    readonly property string date: Qt.formatDateTime(clock.date, "ddd d MMM")
    readonly property string greeting: clock.hours < 12 ? "Good morning"
                                     : clock.hours < 18 ? "Good afternoon" : "Good evening"
}
```

## The clock button

```qml file="modules/bar/Clock.qml"
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    required property var bar
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 28
    radius: height / 2
    color: popup.visible ? Colors.primaryContainer : hover.hovered ? Colors.surfaceContainerHighest : "transparent"
    Behavior on color { CAnim {} }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        StyledText { text: Time.date; color: Colors.onSurfaceVariant }
        StyledText {
            text: Time.time
            font.bold: true
            font.features: ({ "tnum": 1 })      // digits don't jiggle
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: popup.visible = !popup.visible }

    PopupWindow {
        id: popup
        anchor.item: root
        anchor.edges: Config.bar.bottom ? Edges.Top : Edges.Bottom
        anchor.gravity: Config.bar.bottom ? Edges.Top : Edges.Bottom
        anchor.margins.top: Config.bar.bottom ? 0 : 12
        anchor.margins.bottom: Config.bar.bottom ? 12 : 0
        implicitWidth: 320
        implicitHeight: content.implicitHeight + 32
        color: "transparent"
        visible: false
        grabFocus: true                                 // click outside closes it

        StyledRect {
            id: card
            anchors.fill: parent
            level: 2
            transformOrigin: Item.Top
            scale: popup.visible ? 1 : 0.92
            opacity: popup.visible ? 1 : 0
            Behavior on scale { Anim {} }
            Behavior on opacity { Anim { duration: Appearance.anim.fast } }

            ColumnLayout {
                id: content
                anchors { fill: parent; margins: 16 }
                spacing: 12
                StyledText {
                    text: Qt.formatDateTime(Time.now, "dddd")
                    color: Colors.primary
                    font.pixelSize: Appearance.font.size.large
                    font.bold: true
                }
                StyledText {
                    text: Qt.formatDateTime(Time.now, "d MMMM yyyy")
                    font.pixelSize: Appearance.font.size.title
                }
                CalendarGrid { Layout.fillWidth: true; today: Time.now }
            }
        }
    }
}
```

## The calendar grid

```qml file="modules/bar/CalendarGrid.qml"
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    property date today
    property int offset: 0                         // months away from today
    property bool mondayFirst: true

    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int firstWeekday: mondayFirst ? (shown.getDay() + 6) % 7 : shown.getDay()
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property int daysInPrev: new Date(shown.getFullYear(), shown.getMonth(), 0).getDate()
    spacing: 6

    function isoWeek(d) {                           // ISO-8601 week number
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        const day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7)
    }

    // header: < Month Year >
    RowLayout {
        Layout.fillWidth: true
        IconButton { icon: "chevron_left"; size: 28; onClicked: root.offset-- }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(root.shown, "MMMM yyyy")
            font.bold: true
            TapHandler { onTapped: root.offset = 0 }        // click the title → back to today
        }
        IconButton { icon: "chevron_right"; size: 28; onClicked: root.offset++ }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 8
        columnSpacing: 2; rowSpacing: 2

        // weekday header (first column = week number)
        StyledText { text: "Wk"; color: Colors.outline; font.pixelSize: Appearance.font.size.tiny; Layout.alignment: Qt.AlignHCenter }
        Repeater {
            model: root.mondayFirst ? ["Mo","Tu","We","Th","Fr","Sa","Su"] : ["Su","Mo","Tu","We","Th","Fr","Sa"]
            StyledText {
                required property string modelData
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Colors.outline
                font.pixelSize: Appearance.font.size.small
            }
        }

        // 6 rows × (week number + 7 days)
        Repeater {
            model: 6 * 8
            Rectangle {
                id: cell
                required property int index
                readonly property int row: Math.floor(index / 8)
                readonly property int col: index % 8
                readonly property int dayIndex: row * 7 + (col - 1)
                readonly property int day: dayIndex - root.firstWeekday + 1
                readonly property bool inMonth: day >= 1 && day <= root.daysInMonth
                readonly property date cellDate: new Date(root.shown.getFullYear(), root.shown.getMonth(), day)
                readonly property bool isToday: inMonth && cellDate.toDateString() === root.today.toDateString()

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 16
                color: isToday ? Colors.primary : hov.hovered && col > 0 ? Colors.surfaceContainerHighest : "transparent"
                HoverHandler { id: hov }

                StyledText {
                    anchors.centerIn: parent
                    text: cell.col === 0 ? root.isoWeek(new Date(root.shown.getFullYear(), root.shown.getMonth(), cell.row * 7 - root.firstWeekday + 4))
                        : cell.inMonth ? cell.day
                        : cell.day < 1 ? root.daysInPrev + cell.day : cell.day - root.daysInMonth
                    color: cell.isToday ? Colors.onPrimary
                         : cell.col === 0 ? Colors.outline
                         : cell.inMonth ? Colors.onSurface : Colors.alpha(Colors.onSurface, 0.3)
                    font.pixelSize: cell.col === 0 ? Appearance.font.size.tiny : Appearance.font.size.normal
                    font.bold: cell.isToday
                }
            }
        }
    }

    // scroll to change month
    WheelHandler { onWheel: e => root.offset += e.angleDelta.y > 0 ? -1 : 1 }
}
```

## Optional: events from khal

```qml
Process {
    id: events
    command: ["khal", "list", "today", "7d", "--format", "{start-time} {title}"]
    running: popup.visible
    stdout: StdioCollector { onStreamFinished: eventText.text = text.trim() || "No events" }
}
StyledText { id: eventText; wrapMode: Text.Wrap; Layout.fillWidth: true; color: Colors.onSurfaceVariant }
```

## Optional: world clocks

```qml
Repeater {
    model: [{ name: "Tokyo", tz: 9 }, { name: "London", tz: 0 }, { name: "New York", tz: -5 }]
    StyledText {
        required property var modelData
        readonly property date t: new Date(Time.now.getTime() + (modelData.tz * 60 + Time.now.getTimezoneOffset()) * 60000)
        text: modelData.name + "  " + Qt.formatTime(t, "hh:mm")
    }
}
```

(Fixed offsets ignore daylight saving; use `TZ=… date` through Process for exact zones.)

> [!TRY] Exercises
> 1. Add a Config option to switch between Monday- and Sunday-first weeks.
> 2. Highlight weekends in `Colors.tertiary`.
> 3. Show the number of days until a date you care about.
