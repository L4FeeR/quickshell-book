# Desktop Ricing 7: Browser, Spotify and Discord

Three apps that are open in most screenshots and refuse to follow GTK themes: the browser, Spotify and Discord. Each has its own way in: **userChrome.css** for Firefox (and Zen), **spicetify** for Spotify, **Vencord** for Discord.

## Firefox and Zen

Firefox's interface is drawn with CSS, and it loads your own from `userChrome.css` once you allow it.

@include desktop/firefox/userChrome.css

1. Open `about:config`, set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
2. Find your profile folder in `about:support` ("Profile Folder" → Open), create `chrome/` in it, and put `userChrome.css` there.
3. Restart Firefox.

The file sets Firefox's own CSS variables (`--toolbar-bgcolor`, `--toolbar-field-*`, `--arrowpanel-*`) to the palette, merges the tab strip and toolbars into one colour, rounds the tabs and the address bar into pills, outlines the address bar in the accent when focused, and hides the new-tab button. Use the **Browser Toolbox** (Ctrl+Alt+Shift+I, after enabling it in the developer tools settings) to inspect Firefox's interface and find more selectors.

For websites, the **Dark Reader** extension or a userContent.css can apply your colours; GTK's `color-scheme` (set in [[ch:d4-gtk-qt]]) makes sites that support it switch to dark by themselves. Zen Browser reads the same files; lyne-dots generates them on every theme switch (`lyne zen enable`).

## Spotify: spicetify

spicetify patches the Spotify desktop app to load themes and extensions.

```bash
yay -S spicetify-cli
spicetify backup apply           # once; run "spicetify restore" to undo everything
```

@include desktop/spicetify/color.ini

A theme is a folder in `~/.config/spicetify/Themes/` with a `color.ini` (one or more colour schemes) and a `user.css` (can be empty). The keys are Spotify's colour roles: `main` background, `sidebar` and `player` (the bottom bar), `card`, `button` (the accent), `text` and `subtext`. Values are hex without `#`.

```bash
spicetify config current_theme Tokyo color_scheme night
spicetify apply
```

Spotify updates undo the patch; run `spicetify backup apply` again after each update. The **Marketplace** (`spicetify-marketplace`) adds a store of themes and extensions inside Spotify, including full-screen lyrics and visualizers. [[ch:e4-music-rice]] matches Spotify with music widgets in your shell.

## Discord: Vencord / Vesktop

**Vesktop** (a Discord client with Vencord built in, and better on Wayland) or **Vencord** (patches the official client) lets you load CSS themes.

@include desktop/vencord/tokyo.css

Discord's whole interface is coloured by CSS variables: backgrounds from lowest to highest, text, interactive elements, the brand accent and status colours. Overriding them in **Settings › Vencord › Themes › Edit QuickCSS** recolours everything. Discord renames variables now and then; if something stops matching, inspect it with Ctrl+Shift+I and update the name. Complete themes (catppuccin/discord, Tokyo Night ports) are maintained by their communities and link in as one `@import`.

## Others

| App | How |
|---|---|
| VS Code | install the theme's extension; `"workbench.colorTheme"` in settings |
| Obsidian | a community theme, or a CSS snippet with the theme's variables |
| mpv | `~/.config/mpv/mpv.conf` (OSD colours), plus a UI script like uosc |
| zathura (PDF) | `set default-bg "#1a1b26"` and friends in `zathurarc`, `set recolor true` |
| Thunderbird | userChrome.css, like Firefox |

::: exercise warm | One app
Theme one of the three apps above with your palette.
:::

::: exercise practice | Follow the theme
Add a target to your shell's theme exporter that writes spicetify's `color.ini` and runs `spicetify apply` (it restarts Spotify, so only on manual theme changes).
:::
