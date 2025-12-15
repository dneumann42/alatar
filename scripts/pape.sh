#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.alatar/bin/packages.sh"

install_pkgs "imagemagick"
install_pkgs "image-viewer"
install_pkgs "notify"
install_pkgs "window-manager"

WALLPAPER="$HOME/.config/wallpaper.png"
WALLPAPERS="$HOME/Pictures/wallpapers"

mkdir -p "$WALLPAPERS"

function generate_default_wallpaper {
    notify-send "Generating default wallpaper, please wait..."

magick -seed $RANDOM -size 2560x1080 plasma:fractal \
  -blur 0x6 \
  -auto-level -gamma 0.85 \
  -modulate 100,135,195 \
  \( +clone -colorspace gray -blur 0x20 -contrast-stretch 0x3% \) \
  -compose displace -set option:compose:args 22x10 -composite \
  \( -size 2560x1080 xc:black -attenuate 0.15 +noise Uniform -blur 0x0.9 \) \
  -compose softlight -composite \
  \( -size 2560x1080 radial-gradient:white-black -blur 0x30 \) \
  -compose multiply -composite \
  -resize 2560x1080 "$HOME/.config/wallpaper.png"

    notify-send "Default wallpaper was generated."
}

set_wallpaper() {
    notify-send "Setting wallpaper"
  if [[ "${1##*.}" != "png" ]]; then
      notify-send "Converting to png... (convert your images to 'PNG' avoid this delay)"
    magick "$1" "$WALLPAPER"
  else
    cp "$1" "$WALLPAPER"
  fi
  swaymsg reload
}

pick_wallpaper() {
  dir="${1:-$WALLPAPERS}"
  cfg="$(mktemp)"
  trap 'rm -f "$cfg"' EXIT
  cat >"$cfg"<<'EOF'
[keys.gallery]
Return      = exec sh -c 'echo "$1"' _ "%"; exit
Space       = exec sh -c 'echo "$1"' _ "%"; exit
MouseDouble = exec sh -c 'echo "$1"' _ "%"; exit
h = step_left
l = step_right
j = step_down
k = step_up
Ctrl+d = page_down
Ctrl+u = page_up
g = first_file
G = last_file
q = exit
EOF
  sel="$(swayimg --gallery --recursive --order=alpha --config-file="$cfg" "$dir")"
  printf '%s\n' "$sel"
}

if [ ! -f "$WALLPAPER" ]; then
    generate_default_wallpaper
    swaymsg reload
fi

case "${1:-}" in
  set) set_wallpaper "${@:2}" ;;
  gen) generate_default_wallpaper
       swaymsg reload ;;
  pick)
    PAPE="$(pick_wallpaper || true)"
    if [[ -n "${PAPE:-}" && -e "$PAPE" ]]; then
      set_wallpaper "$PAPE"
    fi
    printf '%s\n' "${PAPE:-}"
    ;;
  *) echo "Invalid parameter, expected 'gen', 'set' or 'pick'";;
esac
