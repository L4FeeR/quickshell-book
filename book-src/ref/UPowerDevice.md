@@@ intro
A `UPowerDevice` is **one thing that has a battery or supplies power**: your laptop battery, the AC adapter, a wireless mouse, a Bluetooth headset, a game controller, a UPS. Quickshell reads these from the **UPower** system service over D-Bus, so you get live updates without running any command or polling anything.

You never create a `UPowerDevice` yourself. You get them from the [[UPower]] singleton:

| Where | What you get |
|---|---|
| [[UPower.displayDevice]] | One combined "virtual" battery for your whole system. **Use this for a bar battery icon.** On laptops with two batteries it combines them. |
| [[UPower.devices]] | Every real device UPower knows: each battery, the AC adapter, mice, keyboards, headsets… |

Everything on this page is **read-only**. You can read the numbers and react to changes, but you can't change them (you can't "set" a battery to 100%).

> [!TIP] Requirements
> The `upower` daemon must be running (`systemctl status upower`). It ships with almost every desktop distro. Install it with `sudo pacman -S upower` if it's missing.

@@@ example Example: a battery widget that uses every property
This complete file shows every property of `UPowerDevice` in a small dashboard card. Save it as `~/.config/quickshell/battery-test/shell.qml` and run `qs -c battery-test`.

```qml file="~/.config/quickshell/battery-test/shell.qml"
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    implicitWidth: 520
    implicitHeight: 640
    color: "#1e1e2e"

    // The combined system battery. Swap this for any entry of UPower.devices.
    readonly property UPowerDevice bat: UPower.displayDevice

    // helper: seconds -> "1 h 23 min"
    function duration(sec: real): string {
        if (sec <= 0) return "—"
        const h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60)
        return h > 0 ? `${h} h ${m} min` : `${m} min`
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 6

        component Row2: RowLayout {
            property string label
            property string value
            Text { text: parent.label; color: "#a6adc8"; Layout.preferredWidth: 190 }
            Text { text: parent.value; color: "#cdd6f4"; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
        }

        // --- is it real and ready? ----------------------------------------
        Row2 { label: "ready";            value: bat.ready }             // statistics loaded yet?
        Row2 { label: "isLaptopBattery";  value: bat.isLaptopBattery }   // true on laptops, false on desktops
        Row2 { label: "isPresent";        value: bat.isPresent }         // battery physically inserted?
        Row2 { label: "powerSupply";      value: bat.powerSupply }       // powers the computer itself?

        // --- what kind of device ------------------------------------------
        Row2 { label: "type";             value: UPowerDeviceType.toString(bat.type) }
        Row2 { label: "model";            value: bat.model || "(none)" }
        Row2 { label: "nativePath";       value: bat.nativePath || "(virtual)" }
        Row2 { label: "iconName";         value: bat.iconName }

        // --- charge level ---------------------------------------------------
        Row2 { label: "percentage";       value: Math.round(bat.percentage * 100) + " %" }
        Row2 { label: "energy";           value: bat.energy.toFixed(1) + " Wh" }
        Row2 { label: "energyCapacity";   value: bat.energyCapacity.toFixed(1) + " Wh" }
        Row2 { label: "changeRate";       value: bat.changeRate.toFixed(1) + " W" }

        // --- state and time -------------------------------------------------
        Row2 { label: "state";            value: UPowerDeviceState.toString(bat.state) }
        Row2 { label: "timeToEmpty";      value: duration(bat.timeToEmpty) }
        Row2 { label: "timeToFull";       value: duration(bat.timeToFull) }

        // --- health -----------------------------------------------------------
        Row2 { label: "healthSupported";  value: bat.healthSupported }
        Row2 { label: "healthPercentage"; value: bat.healthSupported ? Math.round(bat.healthPercentage) + " %" : "n/a" }

        // --- a visual bar driven by the same data ---------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 14
            implicitHeight: 26
            radius: 13
            color: "#313244"
            Rectangle {
                width: parent.width * bat.percentage
                height: parent.height
                radius: 13
                color: bat.state === UPowerDeviceState.Charging ? "#a6e3a1"
                     : bat.percentage < 0.15 ? "#f38ba8" : "#89b4fa"
                Behavior on width { NumberAnimation { duration: 400 } }
            }
        }
    }

    // React to a change (every property has an xxxChanged signal):
    Connections {
        target: bat
        function onStateChanged() {
            console.log("battery state is now", UPowerDeviceState.toString(bat.state))
        }
    }
}
```

**How it works, line by line:**

- `import Quickshell.Services.UPower` makes `UPower`, `UPowerDevice`, `UPowerDeviceState` and `UPowerDeviceType` available.
- `readonly property UPowerDevice bat: UPower.displayDevice` stores the device in a typed property, so the rest of the file can say `bat.percentage` instead of `UPower.displayDevice.percentage`.
- `bat.percentage` is a number from **0.0 to 1.0**, so multiply by 100 to display it.
- `bat.state` is an enum number. `UPowerDeviceState.toString()` turns it into text like `"Charging"`. Compare with `UPowerDeviceState.Charging` in conditions.
- Every `Text` uses a [[g:binding|binding]]: when UPower reports a new value, only that text updates. There's no timer anywhere.

@@@ example Example: the bar battery icon you will actually use
```qml file="modules/bar/BatteryIndicator.qml"
import QtQuick
import Quickshell.Services.UPower

Row {
    id: root
    readonly property UPowerDevice bat: UPower.displayDevice
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
                                  || bat.state === UPowerDeviceState.PendingCharge
    readonly property bool full: bat.state === UPowerDeviceState.FullyCharged
    readonly property int pct: Math.round(bat.percentage * 100)

    visible: bat.isLaptopBattery          // hide completely on desktops
    spacing: 4

    Text {
        // Material Symbols icon names: battery_0_bar … battery_6_bar, battery_full, battery_charging_full
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        text: root.charging ? "battery_charging_full"
            : root.full ? "battery_full"
            : "battery_" + Math.min(6, Math.floor(root.pct / 15)) + "_bar"
        color: root.pct <= 15 && !root.charging ? "#f38ba8" : "#cdd6f4"
    }
    Text {
        text: root.pct + "%"
        color: "#cdd6f4"
        anchors.verticalCenter: parent.verticalCenter
    }
}
```

@@@ example Example: list every device (mouse, headset, controller batteries)
```qml
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Column {
    spacing: 4
    Repeater {
        // UPower.devices is an ObjectModel: pass it straight to a Repeater
        model: UPower.devices
        Text {
            required property UPowerDevice modelData
            // skip the AC adapter (LinePower) because it has no percentage
            visible: modelData.type !== UPowerDeviceType.LinePower
            text: `${UPowerDeviceType.toString(modelData.type)} ${modelData.model}: ${Math.round(modelData.percentage * 100)}%`
            color: "white"
        }
    }
}
```

@@@ example Example: low-battery notification
```qml
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Scope {
    readonly property UPowerDevice bat: UPower.displayDevice
    property bool warned: false

    Connections {
        target: bat
        function onPercentageChanged() {
            const discharging = bat.state === UPowerDeviceState.Discharging
            if (discharging && bat.percentage <= 0.10 && !warned) {
                warned = true
                Quickshell.execDetached(["notify-send", "-u", "critical", "Battery low",
                                         Math.round(bat.percentage * 100) + "% remaining"])
            }
            if (bat.percentage > 0.15) warned = false     // re-arm after charging
        }
    }
}
```

@@@ member percentage
Range **0.0 – 1.0** (not 0–100). Show it with `Math.round(bat.percentage * 100) + "%"`.

@@@ member state
Compare against [[UPowerDeviceState]] values: `bat.state === UPowerDeviceState.Charging`. Show text with `UPowerDeviceState.toString(bat.state)`.

@@@ member type
Compare against [[UPowerDeviceType]] values, e.g. `UPowerDeviceType.Battery`, `UPowerDeviceType.Mouse`, `UPowerDeviceType.Headset`.

@@@ member timeToEmpty
In **seconds**. `0` means "unknown" or "currently charging".

@@@ member timeToFull
In **seconds**. `0` means "unknown" or "currently discharging".

@@@ member isLaptopBattery
The safest single check for "should I show a battery icon at all?". It's `false` on desktop PCs.

@@@ member iconName
A freedesktop icon name such as `battery-good-charging-symbolic`. Show it with [[IconImage]]: `source: Quickshell.iconPath(bat.iconName)`.

@@@ member ready
`UPower.displayDevice` is returned immediately (never `null`), but its numbers may still be zero for a split second at startup. Check `ready` if a flash of "0%" bothers you.

@@@ notes
- **Desktop PCs:** `UPower.displayDevice` still exists but `isLaptopBattery` is `false` and `percentage` is `0`. Always gate your UI on `isLaptopBattery`.
- **The AC adapter** is a separate device of type `LinePower`. To know if you're plugged in, check [[UPower.onBattery]] instead.
- **Wireless peripherals** (Logitech mice, many Bluetooth headsets, Xbox/PlayStation controllers) show up in `UPower.devices` only if their driver reports battery to the kernel.
- **Values update at the rate UPower polls the hardware**, usually every 30–120 seconds for batteries. That's normal and very cheap.

@@@ see
- [[UPower]], the singleton that gives you devices
- [[UPowerDeviceState]], [[UPowerDeviceType]], the enums used by `state` and `type`
- [[PowerProfiles]], for power-saver/balanced/performance switching
- [[ch:41-services-tour|Chapter 41: A Tour of the System Services]]
