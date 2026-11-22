# Settings App 2: Setting Rows and Controls

A settings app is mostly the same thing repeated a hundred times: an icon, a title, a description and a control. Get that one piece right and every page becomes a short list of declarations. This chapter builds the row, six typed rows, two Material 3 controls, and the section and page containers.

```text
modules/settings/  SettingRow  SwitchRow  SliderRow  SpinRow  TextRow  ChoiceRow  FontRow
                   M3Switch  M3Slider  Section  SettingsPage
```

<div class="preview"><svg width="620" height="150" viewBox="0 0 620 150"><g font-size="11"><rect x="10" y="20" width="600" height="64" rx="14" fill="#211f26"/><text x="34" y="58" fill="#d0bcff" font-size="18">◐</text><text x="66" y="48" fill="#e6e0e9" font-size="13">Roundness</text><text x="66" y="66" fill="#cac4d0">Scales every corner radius (cards, buttons, drawers)</text><rect x="370" y="46" width="110" height="14" rx="7" fill="#d0bcff"/><rect x="484" y="42" width="3" height="22" fill="#d0bcff"/><rect x="491" y="46" width="40" height="14" rx="7" fill="#4a4458"/><text x="540" y="57" fill="#cac4d0">1.2×</text><text x="584" y="58" fill="#d0bcff" font-size="15">↺</text><g fill="#a6adc8" font-size="10"><text x="26" y="104">icon</text><text x="66" y="104">title + description (searchable)</text><text x="370" y="104">control (any item)</text><text x="566" y="104">reset</text><text x="566" y="118">(only if changed)</text></g></g></svg></div>

## Module 1: The setting row

@include cae/modules/settings/SettingRow.qml

::: walk
@ 14-20 | What a row knows
Display text (`icon`, `title`, `description`), hidden search words (`keywords`), the current `value`, its `defaultValue`, and a slot for the control (`default property alias control`), so derived rows just put a control inside.
@ 22-24 | Computed state
`isSettingRow` lets sections and pages find rows among other items. `matches` asks the search state whether this row should show. `isDefault` compares the value with the default through `JSON.stringify`, which also works for lists such as the bar's module list.
@ 26 | One way out
The row never writes anywhere. It emits `edited(newValue)`, and whoever uses the row decides what that means. This keeps rows reusable and is the main design rule of the whole app.
@ 28-34 | Look
A full-width tonal card that lightens on hover. It hides itself when it doesn't match the search.
@ 44-69 | Icon and text
The description wraps, so long explanations are fine.
@ 71-75 | The control slot
An `Item` sized to whatever control is put inside.
@ 77-86 | Reset
Always present, so the layout doesn't jump, but invisible and disabled while the value is the default. Clicking emits `edited(defaultValue)`: resetting goes through exactly the same path as any edit.
:::

## Module 2: Typed rows

Each typed row is a `SettingRow` with one control inside. They're tiny.

@include cae/modules/settings/SwitchRow.qml

::: walk
@ 8-9 | Show the value
The switch is checked when the row's value is `true`.
@ 10-13 | Report, then re-bind
A Qt Quick Controls switch flips its own `checked` when clicked, which **replaces** the binding `checked: root.value === true` with a fixed value. After reporting the click, the binding is put back with `Qt.binding`, so the switch keeps following the real setting even if it's changed somewhere else (in the JSON file, from IPC, from the other settings process). Forget this and switches slowly drift out of sync with reality.
:::

@include cae/modules/settings/SliderRow.qml

The value is rounded to `decimals` before it's reported, so `shell.json` stores `0.85` and not `0.8500000000000001`. `snapMode: Slider.SnapAlways` makes the handle jump between steps. The number next to the slider uses the monospace font so it doesn't wobble.

@include cae/modules/settings/SpinRow.qml

Two round buttons and the value. Clamping (`Math.max`/`Math.min`) happens before reporting, so the page always gets a valid number.

@include cae/modules/settings/TextRow.qml

Text is reported on `editingFinished` (Enter or leaving the field), not on every keystroke: a half-typed path or prefix shouldn't be applied to the shell.

@include cae/modules/settings/ChoiceRow.qml

A Material 3 **segmented button**: pills joined in a row, outer corners round, inner corners nearly square (per-corner radii), and the selected segment filled with a check mark.

@include cae/modules/settings/FontRow.qml

`Qt.fontFamilies()` lists every font installed on the system. Each entry in the drop-down is drawn in its own font, so you can see what you're choosing.

## Module 3: Material 3 controls

The Basic style's switch and slider look plain. Restyling them once gives every page a consistent Material look.

@include cae/modules/settings/M3Switch.qml

::: walk
@ 16-21 | The track
A pill: filled with the primary colour when on, outlined when off.
@ 23-33 | The knob
Small (16 px) and on the left when off, large (24 px) and on the right when on. Position and size animate with the fast springy curve, so it "pops" across.
@ 35-41 | The check
A check mark appears inside the knob when on, as Material 3 switches do.
@ 44 | No label
`contentItem` is emptied because the row already shows the title.
:::

@include cae/modules/settings/M3Slider.qml

Material 3's newer slider: a thick active track, a small gap around a thin vertical handle, then the inactive track. The two track parts are separate rectangles positioned around `visualPosition`.

## Module 4: Sections and pages

@include cae/modules/settings/Section.qml

::: walk
@ 13 | Rows go inside
Anything declared inside a `Section` lands in its inner column.
@ 15-19 | Hide when nothing matches
The section is visible while at least one row matches the search. Non-row items (a preview, a wallpaper grid) count only when there's no search, so a search never shows a section that has nothing relevant in it. Reading `c.matches` inside the binding makes the section re-check whenever any row's match state changes.
:::

@include cae/modules/settings/SettingsPage.qml

::: walk
@ 17-25 | Counting matches
`countMatches` walks every descendant and counts matching rows. Because the binding reads `children` lists and `matches` properties as it walks, it re-runs whenever the search changes. The navigation rail shows this number as a badge.
@ 27-29 | Scrolling
A plain `Flickable` whose content height is the column's height. `StopAtBounds` stops the "rubber band" effect, which feels out of place in a settings window.
@ 31-56 | Title, subtitle, sections
A large title, a short explanation, then whatever sections the page declares.
@ 58-64 | Empty search results
A message when searching and nothing on this page matches.
:::

With these pieces, a whole setting is one declaration:

```qml
SwitchRow {
    icon: "push_pin"
    title: "Always visible"
    description: "Off: the bar hides and slides out when you touch the left edge"
    keywords: "persistent autohide"
    value: Config.bar.persistent
    defaultValue: true
    onEdited: v => Config.bar.persistent = v
}
```

## Practice

::: exercise warm | A colour row
Write `ColorRow.qml`: a `SettingRow` with a small circle showing `value` as a colour, and a row of five preset colours to pick from.
:::

::: exercise practice | Keyboard for spin rows
Let ↑ and ↓ change a `SpinRow` while it's hovered (or focused).
--- hint
Give the row `focus` on click (`TapHandler { onTapped: root.forceActiveFocus() }`) and handle `Keys.onUpPressed`/`Keys.onDownPressed` by emitting `edited` with the new value.
:::

::: exercise practice | Confirm dangerous rows
Make an `ActionRow` with a button that needs two clicks: the first turns it red with "Click again to confirm" for 3 seconds.
:::

::: exercise challenge | Highlight search matches
When searching, highlight the matched part of the title (like the launcher does in [[ch:r3-launcher]]) using `Text.StyledText`.
:::
