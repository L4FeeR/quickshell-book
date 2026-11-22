# Theming 6: Adding and Creating Themes

You'll want more than 19 themes. This chapter shows three ways to add one: **port** a popular theme by hand (the way the Catppuccin and Tokyo Night files were made), **convert** any of the thousands of base16 schemes with a small script, and **design** your own. All three end with the same thing: one JSON file in `~/.config/theming/themes/`.

## The workflow

1. Create `~/.config/theming/themes/<id>.json`.
2. Run `qs -c theming ipc call theme reload`.
3. Open the picker (Super+T); your theme is there. Hover to preview, click to keep.
4. Check it: the contrast readout in the picker footer, and the checklist at the end of this chapter.

Your folder is separate from the kit's built-in `themes/` folder, so updating the kit never touches your files. A file with the **same id** as a built-in theme replaces it, which is how you tweak a built-in without editing it.

## Way 1: Porting a theme by hand

This is how every built-in theme was made. Take Catppuccin Mocha as the worked example:

**Step 1: Copy the official palette.** Catppuccin publishes its colours at catppuccin.com/palette. Copy every name and hex value into `palette`, exactly as published. Keep the original names; they make the file easy to check against the source.

**Step 2: Decide the roles.** Go through the 17 roles and pick the palette colour that fits each **purpose**. Most themes tell you: Catppuccin's style guide says the background is `base`, secondary panes `mantle`, surface elements `surface0–2`, body text `text`, sub-headlines `subtext1/0`, and subtle text `overlay`. The accent is up to you; Catppuccin suggests mauve as a default, so `primary` is `mauve`.

**Step 3: Choose `onPrimary`.** Look at your `primary`. If it's light (most dark themes), use the background for text on it; if it's dark (most light themes), use the background too if that's light. Then check the contrast (below).

**Step 4: Fill in the meta.** `id`, `name`, `family`, `variant`, `author`, `url`.

The same steps for the other Tokyo Night styles took minutes: the Storm file is the Night file with three background values changed, because the original theme defines Storm exactly that way.

> [!TIP] Where to find official palettes
> Most themes publish their palette in their repository's README or in a "palette" file for Neovim, kitty or VS Code. A kitty theme file (`color0`…`color15`, `background`, `foreground`) is often the quickest source. Copy values, never eyeball them from screenshots.

## Way 2: Converting base16 schemes

**base16** is a standard for colour schemes with exactly 16 colours, `base00` to `base0F`, where each has a fixed job: `base00` is the default background, `base05` the default text, `base08` red, `base0D` blue and so on. Hundreds of schemes exist in that format (the tinted-theming project collects them), so one converter gives you all of them.

@include theming/extras/base16-to-theme.py

::: walk
@ 12-18 | The mapping
Because every base16 slot has a defined purpose, the roles can be fixed once: background `base00`, raised surfaces `base01`/`base02`, comments and borders `base03`, dark text `base04`, text `base05`, and the eight accents `base08`–`base0F`. Blue (`base0D`) is a natural primary accent; `base0E` (usually purple) is the secondary.
@ 21-29 | Reading the YAML
base16 files are simple `key: "value"` lines. A regular expression reads each line's key and value, with or without quotes and with or without a trailing `# comment`, so no YAML library is needed. Newer schemes nest the colours under `palette:`; the indentation doesn't matter to this regex, so they work too.
@ 32-34 | Light or dark?
HSL lightness of the background: above 0.5 means a light scheme. This fills in `variant` automatically.
@ 37-46 | Collecting the 16 colours
Check that all 16 slots exist (stopping with a clear message if one is missing), and normalise them to lowercase `#rrggbb`.
@ 47-56 | Building the theme
The scheme's name becomes the display name and, lower-cased with dashes, the id (prefixed `base16-` so it can't clash with built-ins). All converted themes share the family "Base16".
@ 57 | Output
The theme is printed as JSON; redirect it into your themes folder.
:::

Try it with the classic **Ocean** scheme, which ships with the kit:

@include theming/extras/base16-ocean.yaml

```bash
cd ~/.config/quickshell/theming/extras
python3 base16-to-theme.py base16-ocean.yaml > ~/.config/theming/themes/base16-ocean.json
qs -c theming ipc call theme reload
qs -c theming ipc call theme set base16-ocean
```

To convert a whole collection at once:

```bash
git clone --depth 1 https://github.com/tinted-theming/schemes ~/src/schemes
for f in ~/src/schemes/base16/*.yaml; do
  python3 base16-to-theme.py "$f" > ~/.config/theming/themes/base16-"$(basename "${f%.yaml}")".json
done
qs -c theming ipc call theme reload
```

The picker's search then becomes essential. Type "gruvbox" or "solarized" to find the variants.

> [!NOTE] Base16 vs hand-made ports
> A base16 conversion is good, not perfect: base16 forces every scheme into the same 16 slots, so some (like Catppuccin's 26 colours) lose nuance. For themes you use every day, a hand-made port is worth the ten minutes.

## Way 3: Designing your own theme

Designing from scratch is easier than it sounds if you pick colours in **HSL** (hue, saturation, lightness) instead of hex:

1. **Pick one hue for the base.** Dark themes look best with a slightly tinted background rather than pure grey. A blue-violet hue around 250° is common (Catppuccin, Tokyo Night).
2. **Make the surfaces from that hue.** Keep hue and saturation the same and step the lightness: background 12%, surface 10%, surfaceHigh 18%, border 26% (for a dark theme).
3. **Text from the same hue, with low saturation.** text 88%, textMuted 70%, textFaint 45%.
4. **Pick the accents** around the colour wheel: red ~350°, orange ~25°, yellow ~45°, green ~120°, cyan ~180°, blue ~220°, magenta ~300°. Give them similar saturation and lightness so none shouts.
5. **Choose a primary** from the accents (the one you like most).

Here's a theme made that way, "Midnight Rose":

```json
{
  "id": "midnight-rose",
  "name": "Midnight Rose",
  "family": "Midnight Rose",
  "variant": "dark",
  "author": "you",
  "palette": {
    "night": "#1c1a24", "deep": "#17151e", "raised": "#2a2734", "line": "#3d3949",
    "moon": "#e6e1ef", "mist": "#b4adc4", "shadow": "#716a82",
    "rose": "#f38ba8", "coral": "#f5a97f", "sand": "#eed49f", "sage": "#a6da95",
    "lagoon": "#8bd5ca", "sky": "#8aadf4", "orchid": "#e2a6f4"
  },
  "roles": {
    "background": "night", "surface": "deep", "surfaceHigh": "raised", "border": "line",
    "text": "moon", "textMuted": "mist", "textFaint": "shadow",
    "primary": "rose", "onPrimary": "night", "secondary": "orchid",
    "red": "rose", "orange": "coral", "yellow": "sand", "green": "sage",
    "cyan": "lagoon", "blue": "sky", "magenta": "orchid"
  }
}
```

Notice how the palette uses its **own** poetic names; the roles translate them for the shell. Save it as `~/.config/theming/themes/midnight-rose.json`, reload, and it appears in the picker.

## Making a light twin

To give your theme a light version, add a second file with the **same family** and `"variant": "light"`. The light/dark toggle (Super+Alt+T) finds twins by family, so it will jump between them. For the light version, flip the lightness of the base colours (background ~96%, surfaces ~92% and ~88%, text ~20%) and darken the accents by 15–25% lightness, as Catppuccin does from Mocha to Latte.

## Checklist for a new theme

- [ ] Every role points to a palette name that exists (no bright pink anywhere in the picker card).
- [ ] `text` on `background`: at least 7:1 (the picker footer shows it).
- [ ] `textMuted` on `background`: at least 4.5:1. `textFaint` can be lower; it's for hints.
- [ ] `onPrimary` on `primary`: at least 4.5:1 (check the "Aa" button on the card).
- [ ] `surface`, `surfaceHigh` and `border` are distinguishable from `background`, but subtly.
- [ ] The accents look balanced: none is much brighter or darker than the others.
- [ ] `family` matches the twin, if there is one; `variant` is right.

## Practice

::: exercise warm | Install a base16 scheme
Convert the included Ocean scheme and switch to it. Then find one more base16 scheme you like and convert it.
:::

::: exercise practice | Port a theme
Port **Ayu Mirage**, **Material Ocean** or another theme you like from its official palette. Write the role mapping yourself, then compare your choices with the theme's own editor or terminal ports.
:::

::: exercise practice | A contrast checker command
Add an IPC function `check(): string` to the Theme service that returns the contrast of `text`, `textMuted` and `onPrimary` on their backgrounds for the current theme, like `text 12.3  muted 6.1  onPrimary 8.4`.
--- solution
```qml
function check(): string {
    const c = root.colors;
    const f = x => x.toFixed(1);
    return `text ${f(root.contrast(c.text, c.background))}  muted ${f(root.contrast(c.textMuted, c.background))}  onPrimary ${f(root.contrast(c.onPrimary, c.primary))}`;
}
```
:::

::: exercise challenge | Generate a light twin
Write a small script (Python or QML) that takes a dark theme file and produces a light twin by inverting the lightness of the base colours and darkening the accents. Compare its output with Catppuccin Latte.
:::
