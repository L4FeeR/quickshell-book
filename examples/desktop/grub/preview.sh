#!/usr/bin/env bash
# Preview a GRUB theme without touching your boot setup: build a tiny bootable
# image with the theme and some fake menu entries, boot it in QEMU with no
# window, and save a screenshot of the menu.
# Needs: grub (grub-mkrescue), xorriso, mtools, qemu-system-x86_64, python3,
# and ImageMagick for the PNG.
# Usage: ./preview.sh [theme-folder] [screenshot.png] [WIDTHxHEIGHT]
set -euo pipefail

theme="$(realpath "${1:-$(dirname "$0")/tokyo}")"
out="$(realpath -m "${2:-grub-preview.png}")"
mode="${3:-1920x1080}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

name="$(basename "$theme")"
mkdir -p "$work/iso/boot/grub/themes"
cp -r "$theme" "$work/iso/boot/grub/themes/$name"

# The menu GRUB will show: fake entries with the classes real ones have,
# so the icons appear. Nothing here boots anything.
{
    echo "set gfxmode=$mode,auto"
    echo "insmod all_video"
    echo "insmod gfxterm"
    echo "insmod png"
    # load every font of the theme (grub-mkconfig does this for you on a real system)
    for f in "$theme"/*.pf2; do echo "loadfont /boot/grub/themes/$name/$(basename "$f")"; done
    echo "terminal_output gfxterm"
    echo "set theme=/boot/grub/themes/$name/theme.txt"
    echo "set timeout=30"
    echo 'menuentry "Arch Linux" --class arch { true }'
    echo 'menuentry "Arch Linux (fallback initramfs)" --class arch { true }'
    echo 'menuentry "Windows Boot Manager" --class windows { true }'
    echo 'menuentry "UEFI Firmware Settings" --class efi { true }'
} > "$work/iso/boot/grub/grub.cfg"

grub-mkrescue -o "$work/test.iso" "$work/iso" >/dev/null 2>&1

# Boot it headless. QEMU's monitor listens on a local TCP port; sending it
# "screendump FILE" saves the screen, "quit" stops the machine.
port="${PREVIEW_PORT:-45541}"
qemu-system-x86_64 -m 256 -cdrom "$work/test.iso" -vga std -display none \
    -monitor "tcp:127.0.0.1:$port,server,nowait" &
qemu=$!
sleep "${PREVIEW_WAIT:-15}"          # GRUB takes a few seconds to load its fonts and pictures
python3 - "$port" "$work/shot.ppm" <<'PY'
import socket, sys, time
s = socket.create_connection(("127.0.0.1", int(sys.argv[1]))); time.sleep(0.3)
s.sendall(f"screendump {sys.argv[2]}\n".encode()); time.sleep(1)
s.sendall(b"quit\n"); time.sleep(0.5)
PY
wait "$qemu" 2>/dev/null || true
magick "$work/shot.ppm" "$out"
echo "screenshot: $out"
