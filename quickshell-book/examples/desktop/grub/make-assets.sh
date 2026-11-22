#!/usr/bin/env bash
# Builds every picture and font the theme needs, into the theme folder.
# Needs ImageMagick (magick) and grub-mkfont (from the grub package).
# Usage: ./make-assets.sh [theme-folder] [font.ttf]
set -euo pipefail

dir="${1:-$(dirname "$0")/tokyo}"
font="${2:-/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf}"
bold="${font/Regular/Bold}"; [ -f "$bold" ] || bold="$font"

bg="#16161e"; surface="#1a1b26"; raised="#24283b"; line="#292e42"
accent="#7aa2f7"; magenta="#bb9af7"; cyan="#7dcfff"

mkdir -p "$dir/icons"
cd "$dir"

# GRUB reads only plain RGB/RGBA PNGs. ImageMagick picks the smallest format by
# itself (palette, 1-bit…), which GRUB silently ignores, so every file is
# written with the PNG32: prefix (8-bit RGBA) or PNG24: (8-bit RGB).

# ── Background: a soft radial glow with a few wave lines ───────────────────
magick -size 1920x1080 radial-gradient:"$raised"-"$bg" \
    -fill none -strokewidth 2 -stroke "$line" \
    -draw "path 'M 0,780 C 480,700 960,880 1920,760'" \
    -draw "path 'M 0,830 C 520,740 1000,940 1920,810'" \
    -draw "path 'M 0,880 C 560,790 1040,990 1920,860'" \
    -depth 8 PNG24:background.png

# ── Nine-slice pictures ────────────────────────────────────────────────────
# GRUB draws boxes from 9 pieces: 4 corners (nw ne sw se), 4 edges (n e s w)
# that stretch, and a centre (c) that fills. slice NAME COLOUR RADIUS draws a
# rounded square and cuts it into NAME_nw.png … NAME_c.png.
slice() {
    local name=$1 colour=$2 r=$3 s=$(( $3 * 2 + 2 ))
    magick -size ${s}x${s} xc:none -fill "$colour" -draw "roundrectangle 0,0 $((s-1)),$((s-1)) $r,$r" "tmp_$name.png"
    local m=$(( s - 2 * r ))
    magick "tmp_$name.png" -crop ${r}x${r}+0+0         +repage -depth 8 "PNG32:${name}_nw.png"
    magick "tmp_$name.png" -crop ${m}x${r}+${r}+0      +repage -depth 8 "PNG32:${name}_n.png"
    magick "tmp_$name.png" -crop ${r}x${r}+$((r+m))+0  +repage -depth 8 "PNG32:${name}_ne.png"
    magick "tmp_$name.png" -crop ${r}x${m}+0+${r}      +repage -depth 8 "PNG32:${name}_w.png"
    magick "tmp_$name.png" -crop ${m}x${m}+${r}+${r}   +repage -depth 8 "PNG32:${name}_c.png"
    magick "tmp_$name.png" -crop ${r}x${m}+$((r+m))+${r} +repage -depth 8 "PNG32:${name}_e.png"
    magick "tmp_$name.png" -crop ${r}x${r}+0+$((r+m))  +repage -depth 8 "PNG32:${name}_sw.png"
    magick "tmp_$name.png" -crop ${m}x${r}+${r}+$((r+m)) +repage -depth 8 "PNG32:${name}_s.png"
    magick "tmp_$name.png" -crop ${r}x${r}+$((r+m))+$((r+m)) +repage -depth 8 "PNG32:${name}_se.png"
    rm "tmp_$name.png"
}
slice menu   "${surface}e6" 18      # the menu panel, slightly see-through
slice select "$accent" 8            # the highlight bar (its corners are drawn outside the entry)
slice progress_bar "$raised" 12     # the countdown's track
slice progress_highlight "$magenta" 12   # the countdown's fill

# ── Icons: one per menu entry class (--class arch, --class windows…) ───────
icon() {   # icon NAME COLOUR GLYPH
    magick -size 64x64 xc:none -fill "$2" -draw "roundrectangle 0,0 63,63 16,16" \
        -font "$font" -pointsize 38 -fill "$surface" -gravity center -annotate +0+2 "$3" \
        -depth 8 "PNG32:icons/$1.png"
}
icon arch    "$accent"  $''
icon cachyos "$cyan"    $''
icon linux   "$cyan"    $''
icon windows "$magenta" $''
icon efi     "$line"    $''
cp icons/efi.png icons/recovery.png

# ── The logo above the menu ────────────────────────────────────────────────
magick -size 72x72 xc:none -fill "$accent" -draw "circle 36,36 36,0" \
    -font "$font" -pointsize 40 -fill "$surface" -gravity center -annotate +0+2 $'' logo.png

# ── Fonts: GRUB only reads its own PF2 format ──────────────────────────────
# -n names the family, so theme.txt can say "Tokyo Regular 18".
for size in 14 16 18; do grub-mkfont -n Tokyo -s $size -o "tokyo-regular-$size.pf2" "$font"; done
grub-mkfont -n Tokyo -s 18 -b -o tokyo-bold-18.pf2 "$bold"
grub-mkfont -n Tokyo -s 22 -b -o tokyo-bold-22.pf2 "$bold"

echo "assets written to $dir"
