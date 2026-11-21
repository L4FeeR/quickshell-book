# Value Types in Depth

Every property has a **type** that says what kind of value it holds. Using the right type gives you better error messages, faster code and editor autocomplete. This chapter is a complete tour, with the traps beginners fall into.

## Overview

| Type | Holds | Example literal | Default |
|---|---|---|---|
| `bool` | true or false | `true` | `false` |
| `int` | whole number | `42`, `-3`, `0xff` | `0` |
| `real` | decimal number | `3.14`, `0.5`, `1e3` | `0` |
| `double` | same as `real` | `0.25` | `0` |
| `string` | text | `"hello"`, `'hi'` | `""` |
| `color` | a color | `"#cba6f7"`, `"red"` | black / invalid |
| `url` | a file or web address | `"icons/a.svg"`, `"file:///…"` | empty |
| `date` | a date and time | `new Date()` | invalid |
| `point` | x, y | `Qt.point(10, 20)` | `(0,0)` |
| `size` | width, height | `Qt.size(100, 50)` | `(0,0)` |
| `rect` | x, y, width, height | `Qt.rect(0, 0, 100, 50)` | zero |
| `font` | a font description | `Qt.font({ family: "Inter", pixelSize: 14 })` | system font |
| `var` | **anything** (JS value) | `({ a: 1 })`, `[1, 2]` | `undefined` |
| `list<T>` | a typed list | `["a", "b"]` | empty |
| *object types* | a reference to an object | `property Item target`, `property UPowerDevice bat` | `null` |

## bool

```qml
property bool open: false
visible: open                    // an object is shown only when this is true
onOpenChanged: console.log("open is now", open)
```

Any expression that yields a truthy or falsy JS value converts to `bool`: `visible: someList.length` shows the item when the list isn't empty.

## int and real

```qml
property int count: 3
property real ratio: 0.75

width: 100 * ratio               // 75
```

> [!WARN] Division always gives a decimal
> `7 / 2` is `3.5` in JavaScript, even between ints. If you assign `3.5` to an `int` property it's **truncated** to `3`. Use `Math.round()`, `Math.floor()` or `Math.ceil()` to control rounding: `Math.round(bat.percentage * 100)`.

Handy number methods:

```qml
text: ratio.toFixed(2)           // "0.75": a STRING with 2 decimals
text: Math.round(cpu * 100) + "%"
property real clamped: Math.max(0, Math.min(1, value))   // keep between 0 and 1
```

## string

```qml
property string name: "kitty"
text: "Hello " + name                       // concatenation
text: `Hello ${name}, you have ${n} items`  // template string: easiest for mixing
```

Common string methods (plain JavaScript):

| Method | Result |
|---|---|
| `s.length` | number of characters |
| `s.toUpperCase()` / `toLowerCase()` | case conversion |
| `s.trim()` | remove whitespace at both ends (essential for command output!) |
| `s.includes("x")` | contains? |
| `s.startsWith("x")` / `endsWith` | prefix/suffix check |
| `s.split("\n")` | split into an array of lines |
| `s.slice(0, 10)` | first 10 characters |
| `s.replace(/foo/g, "bar")` | regex replace |
| `s.padStart(2, "0")` | `"7"` → `"07"` |

Special characters: `"\n"` newline, `"\t"` tab, `"\""` a quote, `"\\"` a backslash, `"°"` a Unicode character (°).

## color

```qml
color: "red"                    // SVG color names
color: "#cba6f7"                // #RRGGBB
color: "#80cba6f7"              // #AARRGGBB, alpha FIRST
color: Qt.rgba(1, 0.5, 0, 0.8)  // components 0.0–1.0
color: Qt.hsla(0.75, 0.6, 0.7, 1)
color: "transparent"
```

> [!WARN] Alpha comes first in Qt
> In CSS, `#rrggbbaa` puts alpha last. In QML, 8-digit hex is **`#aarrggbb`**: alpha first. `"#80000000"` is 50% transparent black. Mixing these up is the #1 color bug.

Color helpers:

```qml
color: Qt.lighter(base, 1.2)            // 20% lighter
color: Qt.darker(base, 1.5)
color: Qt.tint(base, "#40ffffff")        // blend a transparent overlay on top
color: Qt.alpha(base, 0.5)               // same color, 50% alpha (Qt 6.8+)
color: Qt.rgba(base.r, base.g, base.b, 0.5)   // same, works on every version
```

A `color` value has readable components: `c.r`, `c.g`, `c.b`, `c.a` (0–1), and `c.hsvHue`, `c.hsvSaturation`, `c.hsvValue`, `c.hslHue`, `c.hslSaturation`, `c.hslLightness`.

## url

```qml
source: "icons/wifi.svg"                         // relative: to THIS .qml file's folder
source: "file:///home/me/Pictures/wall.jpg"      // absolute file URL
source: "file://" + Quickshell.env("HOME") + "/.face"
source: Qt.resolvedUrl("assets/logo.png")       // make a relative path absolute
source: "image://icon/firefox"                   // icon-theme lookup (Quickshell provides this)
```

A relative URL resolves against the **file that contains it**, not the folder you ran `qs` from. That's handy: a component in `widgets/` can say `source: "icons/x.svg"` and find `widgets/icons/x.svg`.

## date

```qml
property date now: new Date()
text: Qt.formatDateTime(now, "dddd, d MMMM yyyy · hh:mm")
text: now.getHours() + ":" + String(now.getMinutes()).padStart(2, "0")
```

[[ch:28-timers-time]] covers date formatting in detail, plus [[SystemClock]].

## point, size, rect

Small value types with named parts:

```qml
property point p: Qt.point(10, 20)          // p.x, p.y
property size s: Qt.size(300, 200)          // s.width, s.height
property rect r: Qt.rect(0, 0, 100, 50)     // r.x, r.y, r.width, r.height

Image { sourceSize: Qt.size(128, 128) }     // decode an image at 128×128
```

## var: anything at all

`var` holds any JavaScript value: objects, arrays, functions, null.

```qml
property var config: ({ height: 32, modules: ["clock", "tray"] })   // note the ( )
property var callback: (x) => console.log(x)
property var nothing: null
```

> [!DANGER] Wrap object literals in parentheses
> `property var obj: { a: 1 }` is parsed as a **code block**, not an object, and gives `undefined`. Always write `({ a: 1 })`.

> [!WARN] Changes *inside* a var are invisible
> QML notices when a property is **assigned**, not when something inside it changes:
> ```qml
> property var items: []
> function add(x) {
>     items.push(x)          // ✗ nothing that uses `items` updates
>     items = [...items, x]  // ✓ a new array is assigned, so bindings update
> }
> ```
> The same applies to `list<T>` and to objects: `obj.a = 2` doesn't notify, `obj = Object.assign({}, obj, { a: 2 })` does.

## list&lt;T&gt;

A typed list. Prefer it over `var` when every element has the same type:

```qml
property list<string> pinned: ["firefox", "kitty", "spotify"]
property list<int> sizes: [12, 14, 18]
property list<Item> panels               // list of objects
```

Use them like JS arrays: `pinned.length`, `pinned[0]`, `pinned.includes("kitty")`, `pinned.map(…)`. The same "assign a new list to notify" rule applies.

## Object types: references to other objects

A property can hold a **reference** to an object of a specific type:

```qml
import Quickshell.Services.UPower

Item {
    property UPowerDevice battery: UPower.displayDevice   // typed reference
    property Item target                                  // null until assigned
    property QtObject anything                            // any object at all
}
```

Typed references give you autocomplete and errors if you assign the wrong kind of object. Every Quickshell type in the API reference can be used as a property type.

## null and undefined, and optional chaining

Object references are often **null**, for example before a service is ready or when no media player is running. Reading a property of null throws an error:

```text
TypeError: Cannot read property 'trackTitle' of null
```

Use **optional chaining** `?.` and **nullish coalescing** `??`:

```qml
text: Mpris.players.values[0]?.trackTitle ?? "Nothing playing"
//                             ^^ stop here if null      ^^ fallback value
```

You'll write `?.` and `??` constantly in shells, because system state comes and goes.

## Type conversion cheatsheet

| From → to | How |
|---|---|
| number → string | `String(n)`, `n.toString()`, `n.toFixed(1)`, `` `${n}` `` |
| string → int | `parseInt("42")` |
| string → real | `parseFloat("3.5")`, `Number("3.5")`, `+"3.5"` |
| string → bool | `s === "true"` |
| anything → JSON text | `JSON.stringify(x)` |
| JSON text → object | `JSON.parse(text)` |
| color → string | `String(c)` gives `"#rrggbb"` |

> [!TRY] Exercises
> 1. Make a `property real level: 0.42` and show it as `42%` using `Math.round`.
> 2. Make a semi-transparent (40%) version of `#89b4fa` in two ways: 8-digit hex, then `Qt.rgba`.
> 3. Create `property var apps: []` and a `Timer` that appends a new string every second. First use `push` and see nothing update. Then fix it.
