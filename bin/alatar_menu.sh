#!/usr/bin/env bash
set -euo pipefail

# Each entry is "name|description" so callers can split and display docs.
scripts=(
  "Change Wallpaper|Pick a new wallpaper to use on the desktop"
  "Generate Wallpaper|Generates a new wallpaper"
  "Show help|Display the keybindings and help manuals|show_help"
)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAPE="$ROOT/scripts/pape.sh"
ROFI_THEME="$ROOT/alatar_dots/rofi/config.rasi"

menu_entries=()
for entry in "${scripts[@]}"; do
  IFS='|' read -r name desc <<<"$entry"
  menu_entries+=("$name"$'\t'"$desc")
done

rofi_cmd=(rofi -dmenu -i -p 'alatar' -format 's')
[[ -f "$ROFI_THEME" ]] && rofi_cmd+=(-theme "$ROFI_THEME")

selection="$(printf '%s\n' "${menu_entries[@]}" | "${rofi_cmd[@]}")"
choice="${selection%%$'\t'*}"

[[ -z "$choice" ]] && exit 0

echo "$choice"

show_help() {
    $HOME/.alatar/scripts/help.tcl
}

case "$choice" in
    "Change Wallpaper") "$PAPE" pick ;;
    "Generate Wallpaper") "$PAPE" gen ;;
    "Show help") show_help ;;
esac
