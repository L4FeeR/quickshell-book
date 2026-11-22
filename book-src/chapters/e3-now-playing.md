# Eye Candy 3: Now Playing and Album-Art Colours

A music widget that's **coloured by the song**: when the track changes, its accent and background change to match the album cover. This chapter builds the player service every music widget uses, extracts colours from the cover, and puts both together in a now-playing card with a blurred cover behind it.

<div class="preview"><svg width="560" height="180" viewBox="0 0 560 180"><defs><linearGradient id="np1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e85d75"/><stop offset="1" stop-color="#2b1b3d"/></linearGradient><filter id="npb"><feGaussianBlur stdDeviation="14"/></filter></defs><rect width="560" height="180" rx="22" fill="#20121f"/><rect x="-20" y="-20" width="600" height="220" fill="url(#np1)" opacity=".45" filter="url(#npb)"/><rect x="18" y="18" width="144" height="144" rx="14" fill="url(#np1)"/><text x="184" y="50" fill="#fff" font-size="20" font-weight="700">Instant Crush</text><text x="184" y="72" fill="#fff" opacity=".7" font-size="13">Daft Punk</text><rect x="184" y="96" width="350" height="4" rx="2" fill="#fff" opacity=".2"/><rect x="184" y="96" width="70" height="4" rx="2" fill="#f07c90"/><text x="184" y="118" fill="#fff" opacity=".6" font-size="11">0:48</text><text x="510" y="118" fill="#fff" opacity=".6" font-size="11">5:37</text><text x="320" y="152" fill="#fff" font-size="15">⏮</text><circle cx="360" cy="147" r="18" fill="#f07c90"/><text x="352" y="153" fill="#fff" font-size="16">⏸</text><text x="390" y="152" fill="#fff" font-size="15">⏭</text></svg></div>

## The player service

@include eyecandy/services/Player.qml

::: walk
@ 6-7 | MPRIS
Players publish what they're playing over D-Bus with the MPRIS standard; Quickshell's [[Mpris]] lists them. mpv needs the `mpv-mpris` plugin; browsers expose each playing tab.
@ 12-16 | Which player
Spotify while it's playing, then any player that's playing, then the first one. Change the order to taste: a music rice usually wants the music app first, not a YouTube tab.
@ 17-22 | Track info
Title, artist, album, cover URL and length (in seconds), with empty defaults when nothing plays.
@ 24-35 | The position
Players don't announce their position continuously; you ask. Every 250 ms while playing, calling `positionChanged()` makes Quickshell fetch a fresh value, which is copied into `position`. Lyrics need this resolution; a progress bar would be fine with once a second.
@ 37-41 | Jumps
A new track resets the position; a seek (the player emits `positionChanged` itself) updates it immediately instead of waiting for the next tick.
@ 43-46 | Seeking
Only if the player allows it, kept inside the track.
@ 49-52 | Formatting
Seconds to "3:17".
:::

## Colours from the cover

@include eyecandy/services/ArtColors.qml

::: walk
@ 6-8 | The idea
[[ColorQuantizer]] reduces an image to a small set of representative colours (by repeatedly splitting the image's colours into groups). From those, pick one to use as an accent and one as a background.
@ 15-19 | Results
The quantized palette, the chosen accent and background, and a text colour that reads well on the accent (dark on light accents, white on dark ones).
@ 21-26 | Quantizing
`depth: 3` gives 2³ = 8 colours. `rescaleSize: 64` shrinks the cover to 64 px first: colours don't need detail, and it takes a fraction of the time. The source follows the cover, so a new track recomputes it.
@ 29-39 | The accent
Skip colours that are too dark or too light to stand out, then score the rest by saturation, preferring a lightness near 60%. A dull winner is lifted to a minimum saturation and lightness so it still reads as an accent. (`Math.max(0, hue)` handles greys, whose hue Qt reports as −1.)
@ 42-47 | The background
The darkest colour, kept in its hue but darkened to 14% lightness at most, so text is always readable on it.
:::

## The now-playing card

@include eyecandy/widgets/NowPlayingCard.qml

::: walk
@ 10-20 | The card
Its background is the cover's dark colour, and it fades over 600 ms when the track changes. Hidden when there's no player.
@ 22-39 | The blurred cover
The cover again, decoded tiny (128 px, it's blurred anyway), blurred fully, darkened and at 45% opacity over the background colour. This is the "Apple Music" look, and it makes every song's card different.
@ 46-58 | The cover
In a `ClippingRectangle` (from `Quickshell.Widgets`), which clips its content to its **rounded** shape. A plain `Rectangle` with `clip: true` only clips to the square box, and the image's corners would stick out.
@ 60-79 | Title and artist
White text, the artist dimmer; long names are cut with "…".
@ 81-110 | Progress
A thin track with a fill in the cover's accent, and a click anywhere on it seeks there. Elapsed and total times below.
@ 112-135 | Controls
Previous, play/pause, next. The middle button is a circle in the accent with the matching text colour.
:::

Because everything reads `ArtColors`, any of your other widgets can follow the music too: `color: ArtColors.accent` on your bar's workspace indicator makes the whole desktop change colour with each song.

::: exercise warm | Show the palette
Add a row of eight small circles under the card showing `ArtColors.palette`, to see what the quantizer found.
:::

::: exercise practice | The whole shell follows
In your shell's theme service, add a "music" mode that uses `ArtColors.accent` as the accent while music plays and your normal theme otherwise.
:::
