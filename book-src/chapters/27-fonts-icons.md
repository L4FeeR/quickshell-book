# Fonts and Icons

Typography and icons carry most of a rice's personality. This chapter covers using installed fonts, bundling fonts, icon fonts (Material Symbols, Nerd Fonts), icon themes for app icons, and Quickshell's [[IconImage]].

## Using installed fonts

```qml
Text {
    font.family: "Inter"               // exact family name from `fc-list : family`
    font.pixelSize: 14
    font.weight: Font.Medium
}
```

Find family names:

```bash
fc-list : family | sort -u | grep -i -E "inter|jetbrains|material"
```

If the family isn't found, Qt silently falls back to a default font. If your text looks "wrong", check the name.

### Font properties

| Property | Values |
|---|---|
| `family` | family name |
| `pixelSize` | size in logical pixels (**use this in shells**) |
| `pointSize` | size in points (DPI-dependent) |
| `weight` | `Font.Thin` (100), `ExtraLight`, `Light`, `Normal` (400), `Medium`, `DemiBold`, `Bold` (700), `ExtraBold`, `Black` (900), or a number |
| `bold`, `italic`, `underline`, `strikeout` | bools |
| `letterSpacing`, `wordSpacing` | px |
| `capitalization` | `Font.MixedCase`, `AllUppercase`, `AllLowercase`, `SmallCaps`, `Capitalize` |
| `hintingPreference` | `Font.PreferFullHinting` etc. |
| `features` | OpenType features: `({ "tnum": 1 })` for tabular numbers |
| `variableAxes` | variable-font axes (Qt 6.7+): `({ "wght": 650, "FILL": 1 })` |

> [!TIP] Tabular numbers for clocks
> In proportional fonts, "1" is narrower than "0", so a ticking clock or percentage jiggles. Enable tabular figures with `font.features: ({ "tnum": 1 })` or use a monospace font for numbers.

## Bundling a font with your config

```qml
FontLoader {
    id: rubik
    source: Qt.resolvedUrl("assets/fonts/Rubik-Variable.ttf")
}
Text { font.family: rubik.name; text: "bundled font" }
```

`FontLoader` has `source`, `name` (the loaded family name) and `status`. This makes your rice self-contained, so others don't need the font installed.

## Icon fonts

An **icon font** is a font whose glyphs are icons. Change the color and size like text, and they stay sharp at any size.

### Material Symbols (recommended)
Google's icon set, used by end-4, Caelestia and most M3-styled rices. It uses **ligatures**: you write the icon's *name* as text.

```qml
Text {
    font.family: "Material Symbols Rounded"      // also: Outlined, Sharp
    font.pixelSize: 22
    color: "#cdd6f4"
    text: "battery_charging_full"                // the icon NAME
}
```

Browse names at fonts.google.com/icons. Common shell icons:

| Area | Names |
|---|---|
| Audio | `volume_up` `volume_down` `volume_mute` `volume_off` `mic` `mic_off` `headphones` |
| Network | `wifi` `wifi_off` `wifi_1_bar` `wifi_2_bar` `signal_wifi_4_bar` `lan` `airplanemode_active` |
| Bluetooth | `bluetooth` `bluetooth_connected` `bluetooth_disabled` |
| Battery | `battery_full` `battery_0_bar`…`battery_6_bar` `battery_charging_full` `battery_alert` |
| Power | `power_settings_new` `restart_alt` `logout` `lock` `bedtime` |
| Media | `play_arrow` `pause` `skip_next` `skip_previous` `shuffle` `repeat` `music_note` |
| Misc | `notifications` `notifications_off` `do_not_disturb_on` `light_mode` `dark_mode` `settings` `apps` `search` `close` `coffee` `screenshot` `keyboard` |

#### Variable axes: filled icons and weight
Material Symbols Variable has axes: **FILL** (0–1), **wght** (100–700), **GRAD** (-25–200) and **opsz** (20–48). With Qt 6.7+:

```qml
Text {
    font.family: "Material Symbols Rounded"
    font.pixelSize: 22
    font.variableAxes: ({ "FILL": active ? 1 : 0, "wght": 500, "opsz": 24 })
    text: "favorite"
}
```

Animating FILL from 0 to 1 on hover or toggle is the "icon fills in" effect seen in M3 rices.

### Nerd Fonts
Patched programming fonts with thousands of icons (Font Awesome, Devicons, Codicons…). You write glyphs by **codepoint** rather than by name:

```qml
Text {
    font.family: "JetBrainsMono Nerd Font"
    text: ""        // nf-fa-wifi
}
```

Look up codepoints at nerdfonts.com/cheat-sheet. Nerd Fonts are popular in terminal-style and minimal rices.

## App icons: icon themes

App icons in launchers, docks, trays and notifications come from **icon themes** (Papirus, Adwaita…) by name, like `firefox` or `org.gnome.Nautilus`.

### Quickshell.iconPath()
Resolve a name to an image URL with [[Quickshell.iconPath()]]:

```qml
Image { source: Quickshell.iconPath("firefox") }                       // URL in the current theme
Image { source: Quickshell.iconPath(entry.icon, "application-x-executable") }   // with fallback name
Image { source: Quickshell.iconPath(name, true) }                      // "" if not found (check=true)
```

There's also [[Quickshell.hasThemeIcon()]] to test existence, and the raw `image://icon/<name>` URL scheme.

### Choosing the theme
Set the icon theme with a pragma at the top of `shell.qml`:

```qml
//@ pragma IconTheme Papirus-Dark
```

### IconImage
[[IconImage]] (from `Quickshell.Widgets`) is an `Image` specialized for icons: always square, sized with one `implicitSize`, crisp scaling:

```qml
import Quickshell.Widgets

IconImage {
    implicitSize: 32
    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
    asynchronous: true
}
```

Use it for every app or tray icon.

### Finding the right icon for a window
A window's app id (`kitty`, `firefox`, `org.gnome.Nautilus`) usually matches its `.desktop` file. Look it up with [[DesktopEntries.heuristicLookup()]], then use the entry's icon:

```qml
IconImage {
    implicitSize: 24
    source: Quickshell.iconPath(DesktopEntries.heuristicLookup(toplevel.appId)?.icon ?? toplevel.appId,
                                "application-x-executable")
}
```

## SVG icons of your own

Keep custom icons in `assets/icons/`. Use white or black SVGs and tint them with MultiEffect `colorization` ([[ch:25-effects]]). Always set `sourceSize` for crispness.

## A reusable MaterialIcon component

```qml file="widgets/MaterialIcon.qml"
import QtQuick

Text {
    id: root
    property string icon: ""
    property real fill: 0                   // 0 outline … 1 filled
    property int size: 20

    text: icon
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "opsz": Math.min(48, Math.max(20, size)) })
    color: "#cdd6f4"
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    Behavior on fill { NumberAnimation { duration: 180 } }
}
```

```qml
MaterialIcon { icon: "wifi"; fill: connected ? 1 : 0; size: 18 }
```

## Practice

::: exercise warm | Three icons
Show `volume_up`, `wifi` and `battery_full` Material Symbols in a row at 20 px.
--- solution
```qml
Row { spacing: 8
    Repeater { model: ["volume_up", "wifi", "battery_full"]
        Text { required property string modelData; text: modelData; color: "white"
               font.family: "Material Symbols Rounded"; font.pixelSize: 20 } } }
```
:::

::: exercise practice | Fill on hover
Build `MaterialIcon.qml` and make the icon fill in when hovered.
--- hint
Material Symbols has a `FILL` variable axis: `font.variableAxes: ({ "FILL": fill })`.
--- solution
```qml
import QtQuick
Text {
    property string icon
    property real fill: hov.hovered ? 1 : 0
    text: icon; color: "white"; font.family: "Material Symbols Rounded"; font.pixelSize: 24
    font.variableAxes: ({ "FILL": fill })
    Behavior on fill { NumberAnimation { duration: 180 } }
    HoverHandler { id: hov }
}
```
:::

::: exercise challenge | App icons
List 10 apps from `DesktopEntries.applications` with their icons using `IconImage`.
--- solution
```qml
Column { spacing: 4
    Repeater { model: DesktopEntries.applications.values.slice(0, 10)
        Row { required property DesktopEntry modelData; spacing: 8
            IconImage { implicitSize: 24; source: Quickshell.iconPath(modelData.icon, "application-x-executable") }
            Text { text: modelData.name; color: "white"; anchors.verticalCenter: parent.verticalCenter } } } }
```
:::
