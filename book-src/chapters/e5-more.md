# Eye Candy 5: Video Wallpapers and Live Weather

Two more showpieces: a **video wallpaper** that loops silently behind your windows and pauses when it can't be seen, and a **weather card** with live data and a four-day forecast.

## A video wallpaper

@include eyecandy/modules/AnimatedWallpaper.qml

::: walk
@ 8-16 | One window per screen
A `Variants` over the screens, with one property, the video file. Use any short, seamlessly looping video (mp4/webm); wallpaper sites and r/LivingBackgrounds have many.
@ 18-26 | On the background layer
Covering the whole screen, under everything, black until the first frame arrives.
@ 28-30 | When to pause
`hasFullscreen` on the monitor's active workspace says a fullscreen window covers the wallpaper; `UPower.onBattery` says you're unplugged. Either pauses the video, so it costs nothing while hidden or on battery.
@ 32-40 | The video
Qt Multimedia's `Video` item: cropped to fill the screen, looping forever, muted, playing on start.
@ 41 | Pause and play
React to the `paused` value.
:::

Video decoding uses the GPU when Qt Multimedia's FFmpeg backend can, but it's still the most expensive wallpaper there is. Other options: **mpvpaper** (mpv as a wallpaper, very efficient) and **swww** (animated GIF transitions between still images).

## Live weather

@include eyecandy/modules/WeatherCard.qml

::: walk
@ 12-16 | State
Your city, the current conditions, the next days, and the city's coordinates.
@ 18-25 | A desktop card
Top right, on the desktop layer.
@ 27-37 | Weather codes
Open-Meteo reports conditions as WMO codes (0 clear, 1–3 cloudy, 45–48 fog, 51–67 rain, 71–77 snow, 80–82 showers, 95+ storms). One function turns a code into an emoji and a word.
@ 39-54 | The city's coordinates
Open-Meteo's geocoding API turns a name into latitude and longitude, once at startup.
@ 55-74 | The forecast
The current temperature, weather code and wind, plus daily highs, lows and codes for four days, in your own time zone (`timezone=auto`). Today is skipped in the list because the big number already shows it. `toLocaleDateString` gives short weekday names in your language.
@ 75 | Every 30 minutes
Weather doesn't change faster than that, and Open-Meteo asks clients not to poll too often.
@ 77-111 | The card
A big emoji and temperature with the condition and city, then three days in a row. "Loading weather…" until the first answer.
:::

Open-Meteo is free for personal use, without a key. Set `city` to yours, or use `latitude`/`longitude` directly if your city name is ambiguous.

::: exercise warm | Your city
Set your city and put the card where it fits your layout.
:::

::: exercise practice | Weather in the bar
Make a small bar chip showing the emoji and temperature, reusing the two requests. Move the data into a `Weather` singleton so the card and the chip share one set of requests.
:::

::: exercise challenge | Wallpaper by weather
Switch between two video (or still) wallpapers depending on the weather code: rain on rainy days, clear skies otherwise.
:::
