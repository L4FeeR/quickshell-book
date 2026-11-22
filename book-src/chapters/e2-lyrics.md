# Eye Candy 2: Synced Lyrics

Spotify shows lyrics that follow the song line by line; this chapter puts that on your desktop, for **any** player (Spotify, Firefox, mpv…). The lyrics come from **LRCLIB** (lrclib.net), a free, open database of time-stamped lyrics that needs no account or key. Then three ways to show them: a **karaoke view** that scrolls and fills each line as it's sung, a **one-line ticker** for your bar, and a **floating overlay** like subtitles.

<div class="preview"><svg width="620" height="220" viewBox="0 0 620 220"><rect width="620" height="220" rx="14" fill="#1a1b26"/><g font-family="sans-serif" text-anchor="middle"><text x="310" y="46" fill="#fff" opacity=".2" font-size="15">I didn't want to be the one to forget</text><text x="310" y="78" fill="#fff" opacity=".4" font-size="16">I thought of everything I'd never regret</text><text x="310" y="118" font-size="24" font-weight="700"><tspan fill="#7aa2f7">A little time with</tspan><tspan fill="#fff"> you is all that I get</tspan></text><text x="310" y="156" fill="#fff" opacity=".4" font-size="16">That's all we need because it's all we can take</text><text x="310" y="188" fill="#fff" opacity=".2" font-size="15">One thing I never see the same when you're 'round</text></g></svg></div>

## The LRC format

```text
[00:26.31] I didn't want to be the one to forget
[00:30.70] I thought of everything I'd never regret
[00:34.93] A little time with you is all that I get
```

Each line starts with the time it's sung, `[minutes:seconds.hundredths]`. The line being sung is simply the **last one whose time has passed**. A line can have several times (a chorus that repeats: `[00:45.00][01:50.00] …`).

LRCLIB answers two kinds of requests:

```bash
# exact: track, artist, album and duration (seconds) pick the right version
curl -s "https://lrclib.net/api/get?track_name=Instant%20Crush&artist_name=Daft%20Punk&album_name=Random%20Access%20Memories&duration=337"
# search: when the exact request finds nothing
curl -s "https://lrclib.net/api/search?track_name=Instant%20Crush&artist_name=Daft%20Punk"
```

The answer is JSON with `syncedLyrics` (LRC text), `plainLyrics` (no times) and `instrumental`.

## The lyrics service

@include eyecandy/services/Lyrics.qml

::: walk
@ 16-20 | State
The parsed lines (`{ time, text }`), plain lyrics when there are no timings, whether the track is instrumental, a status for the views, and an `offset` to nudge lyrics that run early or late.
@ 23-33 | The current line
Walk the lines, which are sorted by time, and keep the last one whose time has passed. Because it reads `Player.position`, it re-evaluates four times a second as the position updates ([[ch:e3-now-playing]]). For a few dozen lines this is instant.
@ 34-35 | Current and next text
For the ticker and the overlay.
@ 37-42 | Progress through the line
From 0 at the line's start to 1 when the next line begins. The karaoke fill uses it. The last line has no end, so it stays at 0.
@ 47-58 | Parsing
For each line: remove every `[…]` tag to get the text, then find each time tag with a global regular expression. QML's JavaScript engine has no `String.matchAll`, so the loop calls `exec()`, which returns the next match each time (and `null` at the end). `lastIndex = 0` resets it for each line. Minutes × 60 + seconds gives the time in seconds. Finally sort by time.
@ 62-65 | When the track changes
`key` is artist + title. A change starts a 600 ms timer, so skipping through five songs quickly makes one request, not five.
@ 67-71 | The cache
One small JSON file per song in `~/.cache/qs-lyrics/`, named from artist and title with anything but letters and digits replaced. A song you've heard before needs no request.
@ 73-84 | Loading
Reset, then point the `FileView` at the cache file. Setting the path to "" first makes sure it reloads even when the path is the same.
@ 86-91 | Applying
Parse the synced lyrics if there are any, keep the plain ones, and set the status.
@ 93-101 | Cache hit or miss
A cached file is applied directly; a missing or broken one triggers a fetch.
@ 105-117 | Fetching
One `curl` command makes **both** requests: the exact one, a newline (`-w "\n"`), then `--next` starts the search request. If the exact match fails, its output is empty and the search still runs. The `Lrclib-Client` header tells LRCLIB which app is asking, as its documentation asks. The track's key is remembered with the request.
@ 119-146 | Reading the answer
If the track changed while the request was running, ignore the answer. The first line is the exact match; if it has no synced lyrics, use the first search result that does (or any result). Then apply it and write it to the cache (path and JSON as arguments to `sh`).
@ 148-153 | From the terminal
`qs ipc call lyrics offsetBy 0.5` delays the lyrics by half a second; `current` prints the line being sung; `reload` fetches again.
:::

> [!NOTE] In the original
> lyne-dots' `LyricsService` works the same way with LRCLIB, plus a second source (NetEase) for songs LRCLIB doesn't have, cleaning of titles like "Song (Remastered 2011)" before searching, and matching by duration within a few seconds.

## The karaoke view

@include eyecandy/widgets/LyricsView.qml

::: walk
@ 10-14 | Options
Colours, size and font. `clip` keeps lines that scroll out from drawing outside.
@ 16-27 | A list that follows the song
A `ListView` of the lines whose `currentIndex` is the line being sung. `StrictlyEnforceRange` with a highlight range in the middle keeps the current line centred: when it changes, the list glides up in 450 ms. Scrolling by hand is off.
@ 29-36 | One line
Active or not, and how far from the current line.
@ 39-52 | The text
Bigger and bold when active; others fade with distance, so the eye goes to the current line. Size and opacity animate. An empty line (an instrumental break) shows a note.
@ 56-69 | The karaoke fill
The same text again in the accent, inside an item that clips it. The clip's width grows with `lineProgress`, so the colour sweeps across the line as it's sung. The text is centred, so the clip starts where the text starts: half the empty space plus progress × the text's width.
@ 74-89 | No synced lyrics
"Looking for lyrics…", "♪ Instrumental ♪", "No lyrics found", or a note when only plain lyrics exist.
:::

## The one-line ticker

@include eyecandy/widgets/LyricsLine.qml

Just the current line, centred and cut with "…" if long. When the line changes, it slides up from below and fades in (a 300 ms `ParallelAnimation` on `y` and `opacity`), so changes feel smooth in a bar. It hides itself when there's nothing to show.

## The floating overlay

[[ch:e4-music-rice]] builds `LyricsOverlay`, subtitles over everything with a shadow for readability, that never take clicks. It uses `Lyrics.currentText`, `Lyrics.nextText` and `Lyrics.lineProgress` from this service.

::: exercise warm | Try the API
Run the two `curl` commands above with a song you like, and find the `syncedLyrics` field.
:::

::: exercise practice | Click to seek
Make clicking a line in the karaoke view jump the song to that line's time (`Player.seek(line.modelData.time)`). Turn `interactive` on so you can scroll too.
:::

::: exercise practice | Word by word
LRCLIB sometimes has word-level timing ("enhanced LRC": `<00:26.31>I <00:26.80>didn't …`). Extend `parse()` to keep word times and colour each word when its time passes.
:::
