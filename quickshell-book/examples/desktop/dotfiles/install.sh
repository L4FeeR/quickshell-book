#!/usr/bin/env bash
# install.sh: link a dotfiles repository into $HOME with GNU Stow.
# Layout: one folder per program, mirroring $HOME:
#   kitty/.config/kitty/kitty.conf   zsh/.zshrc   nvim/.config/nvim/init.lua …
# Usage:  ./install.sh            link every package
#         ./install.sh kitty nvim link only these
set -euo pipefail

cd "$(dirname "$0")"
backup="$HOME/.dotfiles-backup/$(date +%Y-%m-%d_%H-%M-%S)"

command -v stow >/dev/null || { echo "install GNU stow first: sudo pacman -S stow"; exit 1; }

# every top-level folder except hidden ones is a package
packages=("$@")
if [ ${#packages[@]} -eq 0 ]; then
    for d in */; do packages+=("${d%/}"); done
fi

for pkg in "${packages[@]}"; do
    [ -d "$pkg" ] || { echo "no package '$pkg'"; continue; }
    # move away real files that would block the links (never delete them)
    while IFS= read -r -d '' file; do
        target="$HOME/${file#"$pkg"/}"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$backup/$(dirname "${file#"$pkg"/}")"
            mv "$target" "$backup/${file#"$pkg"/}"
            echo "backed up $target"
        fi
    done < <(find "$pkg" -type f -print0)
    stow --restow --target="$HOME" "$pkg"
    echo "linked $pkg"
done

[ -d "$backup" ] && echo "your old files are in $backup"
