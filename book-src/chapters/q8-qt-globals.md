# Qt Reference: The Qt Object and JS Globals

## The `Qt` global object

| Function | Description |
|---|---|
| `Qt.rgba(r, g, b, a)` | color from 0–1 components |
| `Qt.hsla(h, s, l, a)`, `Qt.hsva(h, s, v, a)` | colors from HSL/HSV |
| `Qt.lighter(c, factor)`, `Qt.darker(c, factor)` | brightness (default factor 1.5) |
| `Qt.tint(base, tint)` | blend a translucent tint over a base |
| `Qt.alpha(c, a)` | same color with alpha (Qt 6.8+) |
| `Qt.colorEqual(a, b)` | compare colors |
| `Qt.point(x, y)`, `Qt.size(w, h)`, `Qt.rect(x, y, w, h)` | value types |
| `Qt.vector2d/3d/4d()`, `Qt.quaternion()`, `Qt.matrix4x4()` | math types |
| `Qt.font({ family, pixelSize, … })` | font value |
| `Qt.formatDateTime(date, fmt)`, `Qt.formatDate`, `Qt.formatTime` | formatting ([[ch:28-timers-time]]) |
| `Qt.locale(name)` | locale object (`toString`, number/date formatting, `uiLanguages`) |
| `Qt.binding(fn)` | create a binding from JS |
| `Qt.callLater(fn, …args)` | run once at the end of the event loop tick (coalesces repeated calls) |
| `Qt.resolvedUrl(url)` | absolute URL relative to the current file |
| `Qt.openUrlExternally(url)` | open with the default handler |
| `Qt.createComponent(url)`, `Qt.createQmlObject(qml, parent)` | dynamic creation |
| `Qt.md5(str)`, `Qt.btoa(str)`, `Qt.atob(str)` | hashing / base64 |
| `Qt.quit()`, `Qt.exit(code)` | quit (in Quickshell, prefer leaving it running) |
| `Qt.platform.os`, `Qt.platform.pluginName` | `"linux"`, `"wayland"` |
| `Qt.application.name`, `.arguments`, `.state` | application info |
| `Qt.styleHints` | `mousePressAndHoldInterval`, `startDragDistance`, `colorScheme` (light/dark system preference, Qt 6.5+) |
| `Qt.inputMethod` | on-screen keyboard state |

## Enums on `Qt`

| Group | Values |
|---|---|
| Mouse buttons | `Qt.LeftButton`, `RightButton`, `MiddleButton`, `BackButton`, `ForwardButton`, `AllButtons`, `NoButton` |
| Modifiers | `Qt.NoModifier`, `ShiftModifier`, `ControlModifier`, `AltModifier`, `MetaModifier`, `KeypadModifier` |
| Alignment | `Qt.AlignLeft`, `AlignRight`, `AlignHCenter`, `AlignJustify`, `AlignTop`, `AlignBottom`, `AlignVCenter`, `AlignBaseline`, `AlignCenter` |
| Orientation | `Qt.Horizontal`, `Qt.Vertical` |
| Edges | `Qt.TopEdge`, `LeftEdge`, `RightEdge`, `BottomEdge` |
| Check state | `Qt.Unchecked`, `PartiallyChecked`, `Checked` |
| Cursors | `Qt.ArrowCursor`, `PointingHandCursor`, `IBeamCursor`, `CrossCursor`, `WaitCursor`, `BusyCursor`, `SizeHorCursor`, `SizeVerCursor`, `SizeAllCursor`, `OpenHandCursor`, `ClosedHandCursor`, `ForbiddenCursor`, `BlankCursor` |
| Layout direction | `Qt.LeftToRight`, `Qt.RightToLeft` |
| Keys | `Qt.Key_Escape`, `Key_Return`, `Key_Enter`, `Key_Tab`, `Key_Backtab`, `Key_Backspace`, `Key_Delete`, `Key_Space`, `Key_Up/Down/Left/Right`, `Key_Home`, `Key_End`, `Key_PageUp`, `Key_PageDown`, `Key_A`…`Key_Z`, `Key_0`…`Key_9`, `Key_F1`…`Key_F35`, `Key_VolumeUp`, `Key_MediaPlay`, … |
| Text format | `Qt.PlainText`, `RichText`, `AutoText`, `MarkdownText` |

## `console`

`log`, `info`, `debug`, `warn`, `error`, `assert(cond, msg)`, `trace()`, `time(label)`, `timeEnd(label)`, `count(label)`, `profile()`, `profileEnd()`, `exception()`.

## JavaScript built-ins available in QML

| Object | Highlights |
|---|---|
| `Math` | `round floor ceil abs min max pow sqrt sin cos atan2 random PI E sign trunc hypot log log2 exp` |
| `JSON` | `parse(text, reviver)`, `stringify(value, replacer, indent)` |
| `Date` | `new Date()`, `getFullYear getMonth getDate getDay getHours getMinutes getSeconds getTime toISOString toLocaleString`, `Date.now()` |
| `String` | `length trim split slice substring indexOf includes startsWith endsWith replace replaceAll toUpperCase toLowerCase padStart padEnd repeat match matchAll localeCompare charAt at` |
| `Array` | `length push pop shift unshift slice splice concat join map filter find findIndex findLast some every reduce sort reverse includes indexOf flat flatMap fill Array.from Array.isArray at` |
| `Object` | `keys values entries assign fromEntries freeze` |
| `Number` | `toFixed toPrecision parseInt parseFloat Number.isInteger Number.isNaN` |
| `RegExp` | `/pattern/flags`, `test`, `exec`, flags `g i m s u y` |
| `Map`, `Set`, `WeakMap` | ES collections |
| `Promise`, `async`/`await` | supported (limited usefulness without async APIs) |
| `encodeURIComponent`, `decodeURIComponent`, `escape` | URL encoding |
| `setTimeout`/`setInterval` | **not available** in plain QML: use `Timer` or `Qt.callLater` |
| `XMLHttpRequest` | HTTP requests (GET/POST) from JS; works, but `curl` via Process is often simpler |

### XMLHttpRequest example

```qml
function fetchJson(url, cb) {
    const xhr = new XMLHttpRequest()
    xhr.onreadystatechange = () => {
        if (xhr.readyState === XMLHttpRequest.DONE)
            cb(xhr.status === 200 ? JSON.parse(xhr.responseText) : null)
    }
    xhr.open("GET", url)
    xhr.send()
}
Component.onCompleted: fetchJson("https://wttr.in/?format=j1", d => console.log(d?.current_condition[0].temp_C))
```

## QML-only value type methods

| Type | Members |
|---|---|
| `color` | `r g b a`, `hsvHue hsvSaturation hsvValue`, `hslHue hslSaturation hslLightness`, `valid`, `lighter(f)`, `darker(f)`, `alpha(a)` (6.8+), `tint(c)` |
| `point` | `x y` |
| `size` | `width height` |
| `rect` | `x y width height left right top bottom` |
| `font` | all `font.*` sub-properties |
| `date` | JS Date |
| `url` | `toString()`; compare with `==` |
