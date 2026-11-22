# Eye Candy 0: Showcase Rices

Some rices are built around one spectacular thing: bars that dance to the music, lyrics that scroll in time with the song, a desktop that takes its colours from the album cover, a video wallpaper. This part builds those pieces as Quickshell widgets you can drop into any shell, then assembles them into a **music rice**.

<div class="preview"><svg width="640" height="300" viewBox="0 0 640 300"><defs><linearGradient id="ecc" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e85d75"/><stop offset="1" stop-color="#2b1b3d"/></linearGradient></defs><rect width="640" height="300" fill="#141018"/><g transform="translate(150 150)"><g fill="#e85d75">
<rect x="-2" y="-112" width="4" height="22" rx="2"/><rect x="-2" y="-118" width="4" height="28" rx="2" transform="rotate(15)"/><rect x="-2" y="-104" width="4" height="14" rx="2" transform="rotate(30)"/><rect x="-2" y="-122" width="4" height="32" rx="2" transform="rotate(45)"/><rect x="-2" y="-110" width="4" height="20" rx="2" transform="rotate(60)"/><rect x="-2" y="-100" width="4" height="10" rx="2" transform="rotate(75)"/><rect x="-2" y="-116" width="4" height="26" rx="2" transform="rotate(90)"/><rect x="-2" y="-106" width="4" height="16" rx="2" transform="rotate(105)"/><rect x="-2" y="-120" width="4" height="30" rx="2" transform="rotate(120)"/><rect x="-2" y="-102" width="4" height="12" rx="2" transform="rotate(135)"/><rect x="-2" y="-114" width="4" height="24" rx="2" transform="rotate(150)"/><rect x="-2" y="-108" width="4" height="18" rx="2" transform="rotate(165)"/><rect x="-2" y="-112" width="4" height="22" rx="2" transform="rotate(180)"/><rect x="-2" y="-118" width="4" height="28" rx="2" transform="rotate(195)"/><rect x="-2" y="-104" width="4" height="14" rx="2" transform="rotate(210)"/><rect x="-2" y="-122" width="4" height="32" rx="2" transform="rotate(225)"/><rect x="-2" y="-110" width="4" height="20" rx="2" transform="rotate(240)"/><rect x="-2" y="-100" width="4" height="10" rx="2" transform="rotate(255)"/><rect x="-2" y="-116" width="4" height="26" rx="2" transform="rotate(270)"/><rect x="-2" y="-106" width="4" height="16" rx="2" transform="rotate(285)"/><rect x="-2" y="-120" width="4" height="30" rx="2" transform="rotate(300)"/><rect x="-2" y="-102" width="4" height="12" rx="2" transform="rotate(315)"/><rect x="-2" y="-114" width="4" height="24" rx="2" transform="rotate(330)"/><rect x="-2" y="-108" width="4" height="18" rx="2" transform="rotate(345)"/></g><circle r="86" fill="url(#ecc)"/></g><g font-family="sans-serif"><text x="320" y="110" fill="#ffffff" opacity=".3" font-size="15">I didn't want to be the one to forget</text><text x="320" y="146" fill="#e85d75" font-size="22" font-weight="700">One thing I never see</text><text x="545" y="146" fill="#ffffff" font-size="22" font-weight="700"> the same</text><text x="320" y="182" fill="#ffffff" opacity=".45" font-size="15">I don't believe in him, his lips on the ground</text></g><rect x="40" y="262" width="250" height="28" rx="14" fill="#e85d75" opacity=".2"/><text x="56" y="281" fill="#fff" font-size="12">▂▅▇▃  One thing I never see the same…</text></svg></div>

*From the test run: a ring visualizer around the cover, karaoke lyrics filling with the cover's colour, and the same lyric in a bar chip.*

## What's in this part

| Chapter | Builds |
|---|---|
| [[ch:e1-visualizer]] | an audio spectrum service (cava) and three visualizers: bars, a wave, a ring |
| [[ch:e2-lyrics]] | synced lyrics from LRCLIB: a karaoke view, a one-line ticker, a floating overlay |
| [[ch:e3-now-playing]] | the active player, colours from the album cover, a now-playing card |
| [[ch:e4-music-rice]] | a music corner on the desktop, a bar chip, and matching Spotify and the terminal |
| [[ch:e5-more]] | a video wallpaper and a live weather card |

The code is in `examples/eyecandy/`, a runnable Quickshell config (`qs -p examples/eyecandy`). It's organised so each piece lifts out on its own: **services** (data), **widgets** (things to place anywhere) and **modules** (finished windows). The dynamic island, another favourite, is already in [[ch:g3-islands-popups]].

## Testing without the real thing

Every widget here was tested on screen with a **stand-in player** (a fake `Player` that "plays" a known song with a moving position) and a **fake cava** (a small script printing frames in cava's format), plus real requests to LRCLIB and Open-Meteo. You can test your own widgets the same way: copy the config, replace a service with a fake one, and run it. Your music, your speakers and your real config are never involved.

```bash
sudo pacman -S cava curl        # the visualizer and the web requests
```
