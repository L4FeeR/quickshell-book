# Settings App 1: How Rices Build Settings

Big rices ship a **settings app**: a normal window where you change the shell's look and behaviour with switches and sliders instead of editing JSON, and see each change on screen immediately. end-4's illogical-impulse has one, and Caelestia has **Nexus**. This part builds a complete settings app for the Caelestia rebuild from [[ch:cae1-overview]]: seven pages, search, a live preview, profiles to switch between whole rices, backups and reset.

<div class="preview"><svg width="660" height="340" viewBox="0 0 660 340"><g font-size="11"><rect width="660" height="340" rx="14" fill="#141218"/><text x="22" y="34" fill="#d0bcff" font-size="15">⚙</text><text x="42" y="34" fill="#e6e0e9" font-size="14">Settings</text><rect x="14" y="48" width="180" height="32" rx="16" fill="#2b2930"/><text x="30" y="68" fill="#938f99">⌕  Search settings</text><g transform="translate(14 92)"><rect width="180" height="36" rx="18" fill="#4a4458"/><text x="16" y="23" fill="#e8def8">◉  Appearance</text><text x="16" y="59" fill="#e6e0e9">▢  Frame</text><text x="16" y="95" fill="#e6e0e9">▤  Bar</text><text x="16" y="131" fill="#e6e0e9">▦  Panels</text><text x="16" y="167" fill="#e6e0e9">≡  Services</text><text x="16" y="203" fill="#e6e0e9">⌨  Keybinds</text><text x="16" y="239" fill="#e6e0e9">▣  Profiles &amp; data</text></g><g transform="translate(208 14)"><rect width="438" height="312" rx="24" fill="#1d1b20"/><text x="20" y="40" fill="#e6e0e9" font-size="20">Appearance</text><text x="20" y="60" fill="#cac4d0">Colours come from your wallpaper. Every change applies instantly.</text><text x="24" y="88" fill="#d0bcff" font-size="10">Colour scheme</text><rect x="16" y="96" width="406" height="50" rx="12" fill="#211f26"/><text x="32" y="125" fill="#e6e0e9">Mode</text><rect x="268" y="108" width="70" height="26" rx="13" fill="#4a4458"/><text x="282" y="125" fill="#e8def8">✓ Dark</text><rect x="340" y="108" width="70" height="26" rx="13" fill="#36343b"/><text x="356" y="125" fill="#e6e0e9">Light</text><text x="24" y="172" fill="#d0bcff" font-size="10">Shape and type</text><rect x="16" y="180" width="406" height="50" rx="12" fill="#211f26"/><text x="32" y="209" fill="#e6e0e9">Roundness</text><rect x="220" y="198" width="100" height="12" rx="6" fill="#d0bcff"/><rect x="324" y="196" width="3" height="16" fill="#d0bcff"/><rect x="330" y="198" width="44" height="12" rx="6" fill="#4a4458"/><text x="382" y="209" fill="#cac4d0">1.2×</text><text x="404" y="209" fill="#d0bcff">↺</text><rect x="16" y="234" width="406" height="50" rx="12" fill="#211f26"/><text x="32" y="263" fill="#e6e0e9">Transparency</text><rect x="360" y="246" width="44" height="26" rx="13" fill="#d0bcff"/><circle cx="391" cy="259" r="10" fill="#381e72"/></g></g></svg></div>

## Two ways to build one

### A window inside the shell (Caelestia's Nexus)

The settings window is created **by the running shell**, as a `FloatingWindow` (a normal app window, not a layer-shell panel). It uses the same singletons as everything else, so when a switch writes `Config.bar.persistent = false`, the bar sees the change in the same instant. Nothing goes through a file to reach the shell; the file is only written so the setting survives restarts.

> [!NOTE] In the original
> Caelestia's `modules/nexus/WindowFactory.qml` creates a `FloatingWindow` containing `Nexus.qml` on demand and destroys it when closed; the `nexus` global shortcut and `caelestia shell nexus open` open it. Nexus has pages for apps, audio, Bluetooth, network, panels, services, wallpaper and style, built from shared rows (`ToggleRow`, `SliderRow`, `SelectRow`, `TextFieldRow`, `StepperRow`, `ListEditor`).

### A separate program (end-4)

The settings app is a **second Quickshell process**: `qs -p ~/.config/quickshell/ii/settings.qml`. That file imports the same `Config` singleton, so the app reads and writes the same `config.json`. The running shell watches the file (`watchChanges: true`), reloads it within a few milliseconds of every save, and updates. The app can be opened, closed or crash without touching the shell.

> [!NOTE] In the original
> end-4's `settings.qml` is an `ApplicationWindow` with a page list (Quick, General, Bar, Background, Interface, Services, Advanced, About) that loads `modules/settings/*Config.qml` files. The pages are built from `ConfigSwitch`, `ConfigSlider`, `ConfigSpinBox`, `ConfigSelectionArray`… bound to `Config.options`. The shell opens it with `Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])`.

### This part does both

The app is written once, as a `SettingsWindow` component, and used in both ways:

<div class="preview"><svg width="660" height="230" viewBox="0 0 660 230"><g font-size="11"><g transform="translate(10 10)"><rect width="300" height="200" rx="14" fill="none" stroke="#585b70"/><text x="12" y="20" fill="#cdd6f4">qs -c cae (one process)</text><rect x="20" y="36" width="120" height="44" rx="10" fill="#2b2930"/><text x="80" y="62" fill="#e6e0e9" text-anchor="middle">SettingsWindow</text><rect x="160" y="36" width="120" height="44" rx="10" fill="#2b2930"/><text x="220" y="62" fill="#e6e0e9" text-anchor="middle">bar, drawers…</text><rect x="80" y="110" width="140" height="40" rx="10" fill="#4a4458"/><text x="150" y="134" fill="#e8def8" text-anchor="middle">Config singleton</text><path d="M80 80 L130 110 M220 80 L170 110" stroke="#d0bcff" stroke-width="2"/><rect x="100" y="166" width="100" height="26" rx="6" fill="#36343b"/><text x="150" y="183" fill="#cac4d0" text-anchor="middle">shell.json</text><path d="M150 150 V166" stroke="#a6adc8" stroke-dasharray="3 3"/><text x="230" y="182" fill="#a6adc8" font-size="9">(only to persist)</text></g><g transform="translate(340 10)"><rect width="310" height="200" rx="14" fill="none" stroke="#585b70"/><text x="12" y="20" fill="#cdd6f4">qs -p settings.qml + qs -c cae</text><rect x="16" y="36" width="130" height="44" rx="10" fill="#2b2930"/><text x="81" y="62" fill="#e6e0e9" text-anchor="middle">SettingsWindow</text><rect x="166" y="36" width="130" height="44" rx="10" fill="#2b2930"/><text x="231" y="62" fill="#e6e0e9" text-anchor="middle">the shell</text><rect x="16" y="100" width="130" height="34" rx="10" fill="#4a4458"/><text x="81" y="121" fill="#e8def8" text-anchor="middle">its own Config</text><rect x="166" y="100" width="130" height="34" rx="10" fill="#4a4458"/><text x="231" y="121" fill="#e8def8" text-anchor="middle">its own Config</text><rect x="106" y="160" width="100" height="28" rx="6" fill="#36343b"/><text x="156" y="178" fill="#cac4d0" text-anchor="middle">shell.json</text><path d="M81 134 L130 160" stroke="#d0bcff" stroke-width="2"/><path d="M182 160 L231 134" stroke="#d0bcff" stroke-width="2"/><text x="20" y="196" fill="#a6adc8" font-size="9">writes</text><text x="250" y="196" fill="#a6adc8" font-size="9">watches + reloads</text></g></g></svg></div>

| | Inside the shell | Separate program |
|---|---|---|
| Open with | `Super+,`, `>settings` in the launcher, the settings button in quick toggles, `qs -c cae ipc call settings open` | `qs -p ~/.config/quickshell/cae/settings.qml` |
| Changes reach the shell | instantly, same objects | after the file is saved and reloaded (a few ms) |
| If it crashes | takes the shell with it | the shell keeps running |
| Good for | everyday use | development, or opening settings when the shell is broken |

## How a change travels

Take the **Roundness** slider:

1. You drag it. The slider row emits `edited(1.2)`.
2. The page handles it: `onEdited: v => Config.appearance.roundingScale = v`.
3. `Config`'s `JsonAdapter` property changes. Its `FileView` saves `shell.json` (`onAdapterUpdated: writeAdapter()`).
4. `Tokens.rounding.large` is a binding `Math.round(16 * Config.appearance.roundingScale)`, so it becomes 19.
5. Every card, button and drawer whose `radius` uses that token updates, animated where there's a `Behavior`.

No restart, no "Apply" button: the whole shell is bindings, and the settings app just changes the values at the root.

To make that possible, three options were added to the shell for this part. `Config.qml` gained `appearance.mode`, `font`, `roundingScale` and `animationSpeed`; `Tokens.qml` now multiplies its roundings by `roundingScale`, divides its durations by `animationSpeed` and takes its font from the config ([[ch:cae2-foundations]] walks through it).

## Design rules for a good settings app

1. **Rows don't own data.** A row shows `value` and emits `edited(newValue)`; the page writes to `Config`. Rows stay reusable and never break bindings.
2. **Every setting knows its default**, so each row can offer a reset button that only appears when you've changed something.
3. **Everything is searchable.** Each row has a title, a description and hidden keywords; search hides non-matching rows and sections and shows a count per page.
4. **Show, don't describe.** Where a setting is visual, show it: the frame page draws a live, scaled-down frame with the shell's own components.
5. **Manage the whole rice.** Beyond single settings, let people save, switch, export and reset complete setups.

## Files

```text
~/.config/quickshell/cae/
├── settings.qml                    the standalone entry point
├── services/Profiles.qml           profiles, backups, reset
├── extras/defaults.json            the default settings, for "reset everything"
└── modules/settings/
    ├── SettingsState.qml           current page + search text (singleton)
    ├── Settings.qml                opens the window inside the shell (singleton)
    ├── SettingsWindow.qml          the window: search, navigation, pages
    ├── NavRail.qml
    ├── SettingsPage.qml  Section.qml  SettingRow.qml
    ├── SwitchRow  SliderRow  SpinRow  TextRow  ChoiceRow  FontRow   (typed rows)
    ├── M3Switch  M3Slider                                            (restyled controls)
    ├── EntriesEditor.qml  FramePreview.qml                           (special editors)
    └── pages/  AppearancePage  FramePage  BarPage  PanelsPage  ServicesPage  KeybindsPage  ProfilesPage
```

It's all in the [cae.zip](../examples/cae.zip) download.

## The plan

| Chapter | You build |
|---|---|
| [[ch:set2-building-blocks]] | the setting row, the typed rows, Material 3 switch and slider, sections and pages |
| [[ch:set3-window]] | the window, navigation rail, search, and both ways of opening it |
| [[ch:set4-pages]] | all seven pages, including the live frame preview and the bar module editor |
| [[ch:set5-profiles]] | profiles, backup and reset, and how to test a settings app without a running shell |

## Practice

::: exercise warm | Try both modes
Open the settings inside the shell (`qs -c cae ipc call settings open`), change the roundness, and watch the shell. Close it, then run `qs -p ~/.config/quickshell/cae/settings.qml` and change it again. Can you feel the difference in delay?
--- why
Inside the shell, the change is a property assignment on the same object the shell renders from. As a separate program, the change is written to `shell.json`, the shell's `FileView` gets a file-change notification, re-reads the file and updates its own `Config`. It's fast, but it's a round trip.
:::

::: exercise practice | Read end-4's settings
In the original dots-hyprland, open `modules/common/widgets/ConfigSwitch.qml` and `modules/settings/BarConfig.qml`. How does a switch write to the config?
--- solution
The page binds the switch's `checked` to `Config.options.bar.…` and writes the new value in `onCheckedChanged` (or a similar handler) back to `Config.options`. The `Config` singleton's `JsonAdapter` then saves `config.json`, which the running shell is watching.
:::
