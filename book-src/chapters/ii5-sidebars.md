# end-4 5: The Left and Right Sidebars

ii has two full-height sidebars. The **right sidebar** is the control centre: uptime and system buttons, quick toggles, volume and brightness sliders, notifications, and a calendar. The **left sidebar** is a toolbox with tabs; in the original those are an AI chat, a translator and an image browser.

<div class="preview"><svg width="620" height="330" viewBox="0 0 620 330"><g font-size="10"><g transform="translate(10 10)"><rect width="230" height="310" rx="22" fill="#141218" stroke="#49454f"/><g transform="translate(14 14)"><text y="10" fill="#d0bcff">✎ Translator</text><text x="110" y="10" fill="#cac4d0">▤ Clipboard</text><rect x="20" y="16" width="70" height="3" rx="1.5" fill="#d0bcff"/><text y="40" fill="#938f99">Translate to  en</text><rect y="50" width="202" height="90" rx="12" fill="#1d1b20"/><text x="10" y="70" fill="#e6e0e9">Bonjour tout le monde</text><rect y="150" width="202" height="130" rx="12" fill="#1d1b20"/><text x="10" y="170" fill="#e6e0e9">Hello everyone</text></g><text x="115" y="330" fill="#a6adc8" text-anchor="middle" opacity="0">.</text></g><g transform="translate(380 10)"><rect width="230" height="310" rx="22" fill="#141218" stroke="#49454f"/><text x="14" y="26" fill="#e6e0e9" font-size="11">Up 3h, 12m</text><g fill="#1d1b20"><circle cx="140" cy="22" r="12"/><circle cx="170" cy="22" r="12"/><circle cx="200" cy="22" r="12"/></g><rect x="12" y="44" width="206" height="52" rx="16" fill="#1d1b20"/><g transform="translate(20 52)"><rect width="34" height="34" rx="12" fill="#d0bcff"/><rect x="40" width="34" height="34" rx="17" fill="#211f26"/><rect x="80" width="34" height="34" rx="12" fill="#d0bcff"/><rect x="120" width="34" height="34" rx="17" fill="#211f26"/><rect x="160" width="34" height="34" rx="17" fill="#211f26"/></g><rect x="40" y="106" width="178" height="12" rx="6" fill="#4a4458"/><rect x="40" y="106" width="120" height="12" rx="6" fill="#d0bcff"/><text x="14" y="117" fill="#e6e0e9">🔊</text><rect x="40" y="126" width="178" height="12" rx="6" fill="#4a4458"/><rect x="40" y="126" width="80" height="12" rx="6" fill="#d0bcff"/><text x="14" y="137" fill="#e6e0e9">☀</text><rect x="12" y="148" width="206" height="90" rx="16" fill="#1d1b20"/><rect x="20" y="156" width="190" height="34" rx="12" fill="#211f26"/><rect x="20" y="196" width="190" height="34" rx="12" fill="#211f26"/><rect x="12" y="246" width="206" height="54" rx="16" fill="#1d1b20"/><text x="22" y="266" fill="#cac4d0">November 2026  ‹ ›</text></g><g fill="#cdd6f4"><text x="260" y="40">← left: tools in tabs</text><text x="260" y="150">right: control centre →</text></g></g></svg></div>

```text
modules/sidebarRight/  SidebarRight  SidebarRightContent  MonthGrid
modules/sidebarLeft/   SidebarLeft  Translator  ClipboardHistory
modules/common/widgets/ NotificationItem
services/              Notifications  DateTime  Audio  Brightness
```

## Module 1: The right sidebar window

@include impulse/modules/sidebarRight/SidebarRight.qml

::: walk
@ 11-20 | A full-height panel
Anchored top, right and bottom, `sidebarWidth` wide, with `exclusiveZone: 0` so it overlays windows without pushing them. While open it asks for keyboard focus **on demand**: it only takes the keyboard when you click into it, so your app keeps typing until you do.
@ 22 | Opening marks notifications read
Popups are dismissed (they'd duplicate the list) and the unread counter on the bar resets.
@ 24-28 | Click outside to close
[[HyprlandFocusGrab]] closes the sidebar when you click anywhere else.
@ 30-36 | The content
Inset by Hyprland's gaps on the outer edges and by a larger "elevation" margin on the inner edge, so the panel floats like a window. Esc closes it.
@ 39-47 | IPC and shortcut
`qs -c impulse ipc call sidebarRight toggle`, or the `impulse:sidebarRightToggle` global shortcut.
:::

## Module 2: The control centre

@include impulse/modules/sidebarRight/SidebarRightContent.qml

The content is one `ColumnLayout` of cards in `colLayer1` on a `colLayer0` panel:

| Part | How it works |
|---|---|
| **Header** | uptime from `DateTime.uptime`; three round buttons from a `Repeater` over `[icon, function]` pairs: reload the shell (`Quickshell.reload(true)`), open `config.json`, open the session screen |
| **Quick toggles** | the `QuickToggle` inline component (bottom of the file) is a `RippleButton` whose shape morphs from a circle to a rounded square when toggled, like ii's Android-style toggles. Night light runs `hyprsunset` as a [[Process]] (running = on) |
| **Sliders** | the `SliderRow` inline component: a thick track with a thin vertical handle, ii's slider style |
| **Notifications** | a `ListView` of `NotificationItem`s with an empty state and a count + "Clear" row at the bottom |
| **Calendar** | `MonthGrid` (Module 4) |

Inline components keep this long file readable: the layout at the top reads like a description of the sidebar, and the two reusable pieces are defined once at the bottom.

## Module 3: The notification item

@include impulse/modules/common/widgets/NotificationItem.qml

Shared by the popups ([[ch:ii7-popups]]) and the sidebar list. Collapsed it shows one line of the body; the chevron expands it to show the full body, the action buttons and a "Dismiss" button. Critical notifications use the error container colour.

@include impulse/services/Notifications.qml

The service is like Caelestia's ([[ch:cae7-right-drawers]]): every notification is wrapped with a popup flag, a timestamp and a timer, `popupList` is derived from `list`, and `silent` (Do Not Disturb) skips popups. ii adds an `unread` counter, shown on the bar until you open the sidebar.

## Module 4: The calendar

@include impulse/modules/sidebarRight/MonthGrid.qml

A 7×6 grid with today highlighted and chevrons to change month. The date maths is the same as the Caelestia calendar ([[ch:cae5-dashboard]]).

> [!NOTE] In the original
> The right sidebar's bottom area is a **tabbed widget group**: calendar, a to-do list (`services/Todo.qml`, saved to a file) and a timer/Pomodoro. The quick toggles come in two styles ("classic" and "Android") with long-press dialogs for Wi-Fi, Bluetooth, audio devices and more. There's also a volume mixer page.

## Module 5: The left sidebar

@include impulse/modules/sidebarLeft/SidebarLeft.qml

::: walk
@ 15-29 | Same window pattern
The mirror image of the right sidebar: anchored left, overlaying, on-demand keyboard, closed by a focus grab.
@ 31-40 | The panel
A rounded `colLayer0` panel with a hairline border, floating inside the gaps. It has keyboard focus so Esc closes it.
@ 47-84 | Tabs with a sliding underline
Two `RippleButton` tabs share the width; the selected one gets a filled icon and the primary colour. One underline rectangle slides between them with the `elementMove` preset.
@ 86-92 | Pages
A `StackLayout` shows the current page. The clipboard page is only asked to load its list when it's visible.
:::

### The translator tab

@include impulse/modules/sidebarLeft/Translator.qml

Type in the top box; 600 ms after you stop typing, `trans -brief :en "text"` (translate-shell) runs and its output appears below. The target language is editable. This "debounce then run a command" pattern is the same as the calculator in the widget gallery.

### The clipboard tab

@include impulse/modules/sidebarLeft/ClipboardHistory.qml

`cliphist list` prints `id<TAB>preview` lines. Clicking one pipes it back through `cliphist decode` into `wl-copy`. The entry is passed as `$1` to `sh`, never pasted into the command string, so clipboard content with quotes or `$` can't break or inject anything.

> [!NOTE] In the original: the AI chat
> ii's left sidebar is best known for its **AI chat**: `services/Ai.qml` supports several providers (Gemini, OpenAI-compatible APIs, local Ollama models), streams responses with `curl`, renders Markdown and LaTeX, and lets the model run a few "tools" (like changing a setting). API keys are stored in the system keyring (`services/KeyringStorage.qml`). To add one to the rebuild: a `ListModel` of messages, a `TextArea`, and a `Process` running `curl` with a `SplitParser` that appends streamed tokens to the last message.

## Practice

::: exercise warm | Swap sides
Make the right sidebar open from the left and the left one from the right. Which lines change?
--- solution
The `anchors` of each window and the inner/outer margins of the content (`leftMargin` ↔ `rightMargin`).
:::

::: exercise practice | A to-do tab
Add a third tab to the left sidebar: a to-do list saved with `FileView` + `JsonAdapter` (a `property var items: []`). Enter adds, clicking an item toggles it done.
:::

::: exercise practice | Brightness for external monitors
Add a second brightness slider that uses `ddcutil setvcp 10 <value>` for an external monitor.
:::

::: exercise challenge | AI chat tab
Build a minimal AI chat tab using a local Ollama model: POST to `http://localhost:11434/api/chat` with `curl -N`, read the streamed JSON lines with a `SplitParser`, and append each `message.content` to the reply as it arrives.
:::
