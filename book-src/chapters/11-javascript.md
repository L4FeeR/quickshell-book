# The JavaScript You Need

Every expression in QML is JavaScript. You don't need to learn all of JavaScript, just the part that shows up in shells: variables, conditions, strings, arrays, objects, functions, JSON, dates and math. This chapter teaches that subset from zero.

## Where JavaScript appears

```qml
Item {
    width: 100 * 2                                  // 1. binding expressions
    onWidthChanged: console.log(width)              // 2. signal handlers
    function double(x) { return x * 2 }             // 3. functions
    Component.onCompleted: {                        // 4. multi-line blocks
        const list = [1, 2, 3]
        console.log(list.map(double))
    }
}
```

## Variables

```js
const name = "kitty"        // can't be reassigned: use by default
let count = 0               // can be reassigned
count = count + 1
count += 1                  // same thing
count++                     // same thing
// var x = 1                // old style: avoid
```

Variables declared inside a handler or function exist only there. To remember a value between events, use a QML `property`.

## Conditions

```js
if (pct < 15) {
    color = "red"
} else if (pct < 40) {
    color = "orange"
} else {
    color = "green"
}

// ternary: condition ? valueIfTrue : valueIfFalse (perfect for bindings)
text: charging ? "charging" : "on battery"

// comparisons: === equal, !== not equal, <, >, <=, >=
// logic: && and, || or, ! not
visible: hasBattery && !hidden
```

> [!WARN] Use === not ==
> `==` converts types in surprising ways (`"0" == 0` is true). Always use `===` and `!==`.

### Truthy and falsy
These count as **false**: `false`, `0`, `""`, `null`, `undefined`, `NaN`. Everything else is **true**, including `"0"`, `[]` and `{}`. So `if (title)` means "if title is non-empty".

### ?? and ?.
```js
const t = player?.trackTitle ?? "Nothing playing"   // see Chapter 7
const n = count || 1     // || falls back on ANY falsy value (also 0!)
const m = count ?? 1     // ?? falls back only on null/undefined (keeps 0)
```

### switch
```js
switch (state) {
case "charging": icon = "battery_charging_full"; break
case "full":     icon = "battery_full"; break
default:         icon = "battery_5_bar"
}
```

## Strings

```js
const s = "  Hello World  "
s.trim()                    // "Hello World"
s.toLowerCase()             // "  hello world  "
s.includes("World")         // true
s.split(" ")                // ["", "", "Hello", "World", "", ""]
s.trim().split(/\s+/)       // ["Hello", "World"]: split on any whitespace
"a,b,c".split(",")          // ["a", "b", "c"]
["a", "b"].join(" · ")      // "a · b"
"abc".slice(1)              // "bc"
"7".padStart(2, "0")        // "07"
`CPU ${Math.round(cpu)}%`   // template string
```

### Regular expressions
Patterns for matching text, which is very useful for parsing command output:

```js
const line = "MemAvailable:    8123456 kB"
const m = line.match(/MemAvailable:\s+(\d+)/)   // ( ) captures a group
const kb = m ? parseInt(m[1]) : 0                // m[1] is the first captured group

"wifi_1_bar".replace(/_\d_bar/, "")              // "wifi"
/^\d+$/.test("123")                              // true: is it all digits?
```

Cheat sheet: `\d` digit, `\s` whitespace, `\w` word char, `.` any char, `+` one or more, `*` zero or more, `?` optional, `^` start, `$` end, `(…)` capture, `[abc]` one of, `g` flag = all matches, `i` flag = ignore case.

## Arrays

```js
const apps = ["firefox", "kitty", "spotify"]
apps.length                 // 3
apps[0]                     // "firefox"
apps[apps.length - 1]       // "spotify"
apps.includes("kitty")      // true
apps.indexOf("kitty")       // 1 (-1 if missing)
```

### The big four: map, filter, find, sort
These are what you'll use most, to turn system data into what you display:

```js
const nums = [5, 1, 4]
nums.map(n => n * 2)                  // [10, 2, 8]: transform every element
nums.filter(n => n > 2)               // [5, 4]: keep matching elements
nums.find(n => n > 2)                 // 5: first match (undefined if none)
nums.some(n => n > 4)                 // true: does any match?
nums.every(n => n > 0)                // true: do all match?
[...nums].sort((a, b) => a - b)       // [1, 4, 5]: sort a COPY numerically
nums.reduce((sum, n) => sum + n, 0)   // 10: combine into one value
```

> [!WARN] sort() changes the array in place
> `arr.sort()` modifies `arr`, and on a QML list that can confuse bindings. Sort a copy: `[...arr].sort(…)`. Also note `sort()` without a function sorts **as strings** (`[10, 9, 1]` becomes `[1, 10, 9]`).

Real example: the active media player, or the first one:

```js
readonly property var active: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
```

Real example: apps matching a search, best match first:

```js
DesktopEntries.applications.values
    .filter(a => a.name.toLowerCase().includes(query.toLowerCase()))
    .sort((a, b) => a.name.localeCompare(b.name))
    .slice(0, 20)
```

### Building new arrays
```js
const more = [...apps, "discord"]            // add (new array: notifies QML!)
const fewer = apps.filter(a => a !== "kitty") // remove
const copy = [...apps]
for (const app of apps) console.log(app)     // loop over values
apps.forEach((app, i) => console.log(i, app))
```

## Objects

```js
const bat = { pct: 80, charging: true }
bat.pct                      // 80
bat["charging"]              // true
bat.health = 95              // add a key
Object.keys(bat)             // ["pct", "charging", "health"]
Object.entries(bat)          // [["pct", 80], ...]
const { pct, charging } = bat          // destructuring
const updated = { ...bat, pct: 81 }    // copy with a change
```

## Functions

```js
function add(a, b) { return a + b }                 // declaration
const add2 = (a, b) => a + b                        // arrow function (short)
const square = x => x * x                           // one param: parens optional
const fmt = (sec) => {                              // multi-line arrow
    const m = Math.floor(sec / 60)
    return `${m}:${String(sec % 60).padStart(2, "0")}`
}
```

In QML you can add **type annotations**. They're optional but catch mistakes, and they're required for [[IpcHandler]] functions:

```qml
function formatTime(seconds: int): string {
    const m = Math.floor(seconds / 60), s = seconds % 60
    return `${m}:${String(s).padStart(2, "0")}`
}
```

## JSON

Many commands output JSON (`hyprctl -j`, `niri msg -j`, `curl` APIs). Parse it into objects:

```js
const data = JSON.parse('{"temp": 21.5, "city": "Kochi"}')
data.temp                         // 21.5
JSON.stringify(data)              // back to text
JSON.stringify(data, null, 2)     // pretty-printed, great for console.log debugging
```

Wrap parsing in try/catch, because malformed output would otherwise throw:

```js
try {
    root.weather = JSON.parse(text)
} catch (e) {
    console.warn("bad weather json:", e)
}
```

## Math

```js
Math.round(2.5)   // 3        Math.floor(2.9) // 2      Math.ceil(2.1) // 3
Math.max(1, 5)    // 5        Math.min(1, 5)  // 1      Math.abs(-3)   // 3
Math.random()     // 0..1     Math.PI                   Math.sin(x)
Math.pow(2, 8)    // 256      2 ** 8          // 256    Math.sqrt(16)  // 4
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))
```

## Dates

```js
const now = new Date()
now.getHours(); now.getMinutes(); now.getDay()   // 0 = Sunday
now.getFullYear(); now.getMonth()                // month is 0-based! (0 = January)
new Date(2026, 0, 1)                             // 1 Jan 2026
Date.now()                                       // milliseconds since 1970 (for timing)
```

For display, use Qt's formatter: `Qt.formatDateTime(now, "ddd d MMM hh:mm")` ([[ch:28-timers-time]]).

## Shared JavaScript files

Put reusable helpers in a `.js` file and import it:

```js file="utils/format.js"
.pragma library          // load once and share between all files (no access to QML ids)

function bytes(b) {
    const u = ["B", "KiB", "MiB", "GiB", "TiB"]
    let i = 0
    while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
    return b.toFixed(i ? 1 : 0) + " " + u[i]
}

function duration(sec) {
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60)
    return h ? `${h}h ${m}m` : `${m}m`
}
```

```qml
import "utils/format.js" as Format

Text { text: Format.bytes(1536000) }      // "1.5 MiB"
```

> [!WILD] In the wild
> end-4 bundles libraries like `fuzzysort.js` for launcher search this way, and keeps string and color helpers in `.js` files.

## Debugging JavaScript

```js
console.log("value:", x)                    // print
console.log(JSON.stringify(obj, null, 2))   // print an object readably
console.warn("something odd")               // yellow
console.error("broken")                     // red
console.trace()                             // print the call stack
console.time("sort"); /* … */ console.timeEnd("sort")   // measure duration
```

> [!TRY] Exercises
> 1. Write `function plural(n, word)` that returns `"1 item"` / `"3 items"`.
> 2. Given `const lines = ["a:1", "b:22", "c:3"]`, build `{a: 1, b: 22, c: 3}` with `map`, `split` and `Object.fromEntries`.
> 3. Parse `"MemTotal: 16000000 kB\nMemAvailable: 9000000 kB"` with regexes and compute the used percentage.
> 4. Put your `plural` function in `utils/text.js` with `.pragma library` and use it from QML.
