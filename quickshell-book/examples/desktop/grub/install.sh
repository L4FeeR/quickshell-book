#!/usr/bin/env bash
# Install the theme on this machine (needs sudo). Backs up /etc/default/grub,
# sets the theme and a screen mode, and regenerates GRUB's config.
# Undo: restore the backup, then run the grub-mkconfig line at the end again.
set -euo pipefail

theme="$(realpath "${1:-$(dirname "$0")/tokyo}")"
name="$(basename "$theme")"
mode="${2:-auto}"                       # e.g. 1920x1080, or auto

[ -f "$theme/background.png" ] || { echo "run ./make-assets.sh first"; exit 1; }
read -rp "Install GRUB theme '$name' (mode $mode)? [y/N] " ok
[ "$ok" = y ] || exit 0

sudo mkdir -p /boot/grub/themes
sudo cp -r "$theme" "/boot/grub/themes/$name"
sudo cp /etc/default/grub "/etc/default/grub.bak-$(date +%Y%m%d-%H%M%S)"

# replace (or add) the two settings
set_opt() {
    if grep -q "^#\?$1=" /etc/default/grub; then
        sudo sed -i "s|^#\?$1=.*|$1=\"$2\"|" /etc/default/grub
    else
        echo "$1=\"$2\"" | sudo tee -a /etc/default/grub >/dev/null
    fi
}
set_opt GRUB_THEME "/boot/grub/themes/$name/theme.txt"
set_opt GRUB_GFXMODE "$mode"
# the theme needs the graphical terminal, not the text console
sudo sed -i 's|^GRUB_TERMINAL_OUTPUT=.*|#&|' /etc/default/grub

sudo grub-mkconfig -o /boot/grub/grub.cfg
echo "done: reboot to see it"
