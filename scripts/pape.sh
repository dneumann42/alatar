#!/usr/bin/env bash
WALL="$HOME/.config/wallpaper.png"
set -euo pipefail

set_wallpaper() {
    notify-send "Setting wallpaper"
  if [[ "${1##*.}" != "png" ]]; then
      notify-send "Converting to png... (convert your images to 'PNG' avoid this delay)"
    magick "$1" "$WALL"
  else
    cp "$1" "$WALL"
  fi
  swaymsg reload
}

pick_wallpaper() {
  dir="${1:-$HOME/Media/Pictures/Wallpapers}"
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

case "${1:-}" in
  set)  set_wallpaper "${@:2}" ;;
  pick)
    PAPE="$(pick_wallpaper || true)"
    if [[ -n "${PAPE:-}" && -e "$PAPE" ]]; then
      set_wallpaper "$PAPE"
    fi
    printf '%s\n' "${PAPE:-}"
    ;;
  *) echo "Invalid parameter, expected 'set' or 'pick'";;
esac

