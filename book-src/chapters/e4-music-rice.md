# Eye Candy 4: The Music Rice

Everything from the last three chapters, assembled into a desktop built around music: a **music corner** on the desktop with the cover spinning inside a ring visualizer and lyrics scrolling beside it, **floating karaoke lyrics** over your windows, a **bar chip** with tiny bars and the current line, and Spotify and the terminal in matching colours.

<div class="preview"><svg width="640" height="320" viewBox="0 0 640 320"><defs><linearGradient id="mr" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e85d75"/><stop offset="1" stop-color="#2b1b3d"/></linearGradient></defs><rect width="640" height="320" fill="#120d16"/><rect x="0" y="0" width="640" height="30" fill="#1a1b26" opacity=".9"/><rect x="230" y="5" width="180" height="20" rx="10" fill="#e85d75" opacity=".25"/><text x="244" y="19" fill="#fff" font-size="10">▂▅▇▃  One thing I never see…</text><g transform="translate(120 140)"><g fill="#e85d75"><rect x="-2" y="-92" width="4" height="20" rx="2"/><rect x="-2" y="-96" width="4" height="24" rx="2" transform="rotate(30)"/><rect x="-2" y="-86" width="4" height="14" rx="2" transform="rotate(60)"/><rect x="-2" y="-94" width="4" height="22" rx="2" transform="rotate(90)"/><rect x="-2" y="-88" width="4" height="16" rx="2" transform="rotate(120)"/><rect x="-2" y="-98" width="4" height="26" rx="2" transform="rotate(150)"/><rect x="-2" y="-90" width="4" height="18" rx="2" transform="rotate(180)"/><rect x="-2" y="-96" width="4" height="24" rx="2" transform="rotate(210)"/><rect x="-2" y="-86" width="4" height="14" rx="2" transform="rotate(240)"/><rect x="-2" y="-94" width="4" height="22" rx="2" transform="rotate(270)"/><rect x="-2" y="-88" width="4" height="16" rx="2" transform="rotate(300)"/><rect x="-2" y="-98" width="4" height="26" rx="2" transform="rotate(330)"/></g><circle r="66" fill="url(#mr)"/></g><rect x="20" y="245" width="200" height="60" rx="14" fill="#20121f"/><rect x="28" y="253" width="44" height="44" rx="8" fill="url(#mr)"/><text x="80" y="272" fill="#fff" font-size="11" font-weight="700">Instant Crush</text><text x="80" y="288" fill="#fff" opacity=".6" font-size="10">Daft Punk</text><g font-family="sans-serif"><text x="260" y="110" fill="#fff" opacity=".3" font-size="13">I didn't want to be the one to forget</text><text x="260" y="140" fill="#e85d75" font-size="18" font-weight="700">One thing I never see</text><text x="260" y="168" fill="#fff" opacity=".4" font-size="13">I don't believe in him, his lips on the ground</text></g><text x="250" y="290" fill="#fff" font-size="20" font-weight="700" opacity=".95">One thing I never see the same…</text></svg></div>

## The music corner

@include eyecandy/modules/MusicDesktop.qml

::: walk
@ 9-24 | A desktop window
In the bottom-left corner, on the **bottom layer**, so it sits on the wallpaper behind your windows, like a desktop widget. `mask: Region {}` makes it ignore clicks: it's decoration, and clicks go to the desktop. Hidden when nothing plays.
@ 26-34 | Two columns
On the left the ring and card (a fixed 420 px column: `Layout.fillWidth: false` stops the layout from stretching it), on the right the lyrics.
@ 35-47 | The ring
The ring visualizer ([[ch:e1-visualizer]]) in the cover's accent, fading to a lighter version of it.
@ 48-72 | The spinning cover
The cover in a round `ClippingRectangle`, slowly turning (one turn every 30 s) while playing, like a vinyl record. `from: cover.rotation` makes it continue from where it stopped instead of jumping back after a pause.
@ 73 | The card
The now-playing card from [[ch:e3-now-playing]].
@ 76-82 | Lyrics
The karaoke view ([[ch:e2-lyrics]]), filling lines with the cover's accent.
:::

## Floating lyrics

@include eyecandy/modules/LyricsOverlay.qml

::: walk
@ 12-27 | Over everything, touching nothing
A wide window near the bottom on the **overlay** layer, above your windows, with an empty input mask, so you can click and type through it. It only shows while music with synced lyrics is playing. `qs ipc call overlay toggle` turns it off and on (bind it to a key).
@ 32-45 | The current line
Big and bold in white.
@ 46-52 | The sung part
The same text in the cover's accent, clipped to `lineProgress`: the colour sweeps across as the line is sung.
@ 53-60 | Readable anywhere
A soft black shadow behind the whole line ([[MultiEffect]] as a layer effect), so it stays readable over a white web page or a dark terminal.
@ 62-70 | The next line
Smaller, dimmer, with a thin outline.
:::

## A chip for your bar

@include eyecandy/modules/MusicChip.qml

A pill tinted with the cover's accent: tiny mirrored bars, then the current lyric, or the title and artist when the song has no synced lyrics. Its width animates as the lyric changes. Click to play or pause, scroll to skip. Drop it into any bar's `RowLayout`: the gallery shell ([[ch:g10-full-shell]]) or the lyne rebuild ([[ch:ly5-bar]]) for example.

## The demo shell

@include eyecandy/shell.qml

All of it running together, with a minimal bar to show the chip. Run it with `qs -p examples/eyecandy` while some music plays.

## Matching the rest of the desktop

A music rice looks best when Spotify and the terminal join in:

- **Spotify**: a spicetify theme in your palette ([[ch:d7-apps]]). For colours that follow each album, spicetify's "Dynamic" themes (like `DribbblishDynamic`) tint Spotify from the cover, just as `ArtColors` does for the shell.
- **The terminal**: cava with the same gradient ([[ch:d2-shell]]) in a small floating kitty window makes a classic screenshot. A Hyprland rule floats it: `class = "cava"` with `kitty --class cava cava`.
- **The dynamic island** from [[ch:g3-islands-popups]] can show the track and a progress ring at the top of the screen.
- **Hyprland**: blur behind the overlay and the music corner (`layerrule = blur, eyecandy_.*`) gives them a glassy look.

::: exercise warm | Your corner
Move the music corner to the right side of your screen and make the cover a rounded square instead of a circle.
:::

::: exercise practice | Show only while playing
Fade the whole music corner out after 30 seconds of pause, and back in when playback resumes.
:::

::: exercise project | Your music rice
Combine the music corner, the overlay and the chip with your own bar, theme Spotify and cava to match, and take a screenshot with a song playing.
:::
