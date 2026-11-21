<div class="cover">
<div class="ch-part">From zero to shell author</div>
<h1>The <em>Quickshell</em> Book</h1>
<p class="lede">A complete, beginner-first guide to building your own Linux desktop with Quickshell and QML. You start knowing nothing about Linux ricing, Qt or programming, and finish able to build any bar, panel, launcher, lock screen or widget you can imagine.</p>
<div class="stats">
<div class="stat"><b>79</b><span>chapters</span></div>
<div class="stat"><b>157</b><span>API types documented</span></div>
<div class="stat"><b>19</b><span>complete projects</span></div>
<div class="stat"><b>60</b><span>cookbook recipes</span></div>
</div>
</div>

## How to use this book

**If you're new to everything**, read Parts I → III in order and type every example. Keep `qs -c playground` running in a terminal while you read: Quickshell reloads on every save, so you see each change instantly.

**If you know some QML**, skim Part II, then start at Part IV (Quickshell concepts).

**If you want to build something specific now**, jump to Part VI (projects) and use the **API Reference** as your dictionary: every Quickshell type has a page listing every property, function, signal and enum value, how to get the object, and complete examples.

| You want to… | Go to |
|---|---|
| Understand what all the words mean | [[ch:01-what-is-ricing]] and the [Glossary](glossary.html) |
| Put something on screen right now | [[ch:04-first-shell]] |
| Learn the language properly | [[ch:06-objects-properties]] → [[ch:14-lifecycle]] |
| Make things look good and move nicely | [[ch:16-rect-text-image]], [[ch:23-animation-basics]], [[ch:25-effects]] |
| Show workspaces, battery, volume, media | [[ch:40-compositors]], [[ch:41-services-tour]] |
| Organize a big config like end-4 or Caelestia | [[ch:42-project-layout]] → [[ch:46-state]] |
| Theme everything from your wallpaper | [[ch:44-theming]] |
| Build a bar / launcher / lock screen … | Part VI |
| Look up any property or method | [API Reference](ref/index.html) or press <kbd>/</kbd> |

## Navigation

- **Sidebar**: every part, chapter and API type. Modules expand to show their types; <span class="tb tb-S">S</span> marks singletons, <span class="tb tb-E">E</span> marks enums.
- **Search** (<kbd>/</kbd>): types, properties, functions, signals, enum values, chapter sections and glossary terms.
- **On this page** (right side): headings of the current page.
- <kbd>Alt</kbd>+<kbd>←</kbd> / <kbd>Alt</kbd>+<kbd>→</kbd>: previous / next page.
- [A–Z Index](az.html): every entry alphabetically. [Cheat Sheet](cheatsheet.html): one-page summary. [Whole book](print.html): everything on one page, ready to print or save as PDF.

## Conventions

- Code blocks show their **file path** in the top-right corner. Hover a block to get a **copy** button.
- `inline code` is something you type exactly. <kbd>Keys</kbd> are keys to press.
- Callout boxes: **Tip** (a good idea), **Note** (background), **Watch out** (a common mistake), **Danger** (could break your session), **Try it yourself** (exercises), **In the wild** (how popular rices do it).
- Links like [[PanelWindow]] go to the API reference; links like [[ch:09-bindings]] go to chapters.

## About versions

The API reference is generated from the Quickshell source (version 0.3.x), so every property listed exists in that version. Types marked **noctalia-qs fork only** (the `Quickshell.Niri` and `Quickshell.DWL` modules) come from the noctalia-qs fork. If something doesn't exist on your system, run `qs --version` and check the upstream docs at quickshell.org.
