#!/usr/bin/env bash
set -euo pipefail

# Prompt for a URL and launch mpv as a floating window in a chosen corner.

corner="tr"
first_arg="${1:-}"
case "$first_arg" in
  tr|tl|br|bl)
    corner="$first_arg"
    shift || true
    ;;
esac

url="${1:-}"

float_width="${MPV_FLOAT_WIDTH:-480}"
float_height="${MPV_FLOAT_HEIGHT:-270}"
float_margin="${MPV_FLOAT_MARGIN:-16}"
title="floating-mpv-$(date +%s%N)"

require_mpv() {
  if ! command -v mpv >/dev/null 2>&1; then
    echo "mpv is required. Install with: alatar packages install mpv yt-dlp" >&2
    exit 1
  fi
}

prompt_url() {
  local seed=""
  if command -v wl-paste >/dev/null 2>&1; then
    seed="$(wl-paste 2>/dev/null || true)"
  fi

  if command -v rofi >/dev/null 2>&1; then
    printf '%s\n' "$seed" | rofi -dmenu -p "MPV URL" || true
  else
    local input=""
    read -rp "MPV URL: " input || true
    printf '%s' "$input"
  fi
}

output_rect() {
  swaymsg -t get_outputs | jq -r '
    (map(select(.focused==true)) + .)[0].rect // empty
    | "\(.x) \(.y) \(.width) \(.height)"
  ' | head -n1
}

fallback_rect() {
  swaymsg -t get_tree | jq -r '
    recurse(.nodes[]?, .floating_nodes[]?)
    | select(.focused==true)
    | .rect
    | "\(.x) \(.y) \(.width) \(.height)"
  ' | head -n1
}

calc_position() {
  local ox="$1" oy="$2" ow="$3" oh="$4"

  local x=$((ox + float_margin))
  local y=$((oy + float_margin))
  local right=$((ox + ow - float_width - float_margin))
  local bottom=$((oy + oh - float_height - float_margin))

  (( right < ox + float_margin )) && right=$((ox + float_margin))
  (( bottom < oy + float_margin )) && bottom=$((oy + float_margin))

  case "$corner" in
    tr) x=$right; y=$((oy + float_margin)) ;;
    tl) x=$((ox + float_margin)); y=$((oy + float_margin)) ;;
    br) x=$right; y=$bottom ;;
    bl) x=$((ox + float_margin)); y=$bottom ;;
  esac

  echo "$x $y"
}

mark_and_float() {
  local pid="$1"
  local x="$2"
  local y="$3"

  for _ in $(seq 1 40); do
    con_id="$(swaymsg -t get_tree | jq -r --arg pid "$pid" --arg title "$title" '
      recurse(.nodes[]?, .floating_nodes[]?)
      | select(
          (.pid|tostring==$pid)
          or ((.app_id=="mpv") and ((.name//"")==$title or (.window_properties.title//"")==$title))
          or ((.window_properties.class//"")== "mpv" and ((.name//"")==$title or (.window_properties.title//"")==$title))
        )
      | .id
      ' | head -n1)"
    if [[ -n "$con_id" ]]; then
      swaymsg "[con_id=$con_id]" floating enable, sticky enable, resize set "$float_width" "$float_height", move position "$x" "$y", focus >/dev/null 2>&1 || true
      sleep 0.2
      swaymsg "[con_id=$con_id]" resize set "$float_width" "$float_height", move position "$x" "$y" >/dev/null 2>&1 || true
      return
    fi
    sleep 0.05
  done
}

main() {
  require_mpv

  if [[ -z "$url" ]]; then
    url="$(prompt_url)"
  fi

  if [[ -z "$url" ]]; then
    exit 0
  fi

  rect="$(output_rect)"
  [[ -z "$rect" ]] && rect="$(fallback_rect)"
  [[ -z "$rect" ]] && rect="0 0 1920 1080"
  read -r ox oy ow oh <<<"$rect"

  # Clamp to available space so the window is not oversized for the output.
  max_width=$((ow - 2 * float_margin))
  max_height=$((oh - 2 * float_margin))
  (( max_width < 1 )) && max_width=1
  (( max_height < 1 )) && max_height=1
  (( float_width > max_width )) && float_width=$max_width
  (( float_height > max_height )) && float_height=$max_height

  read -r x y <<<"$(calc_position "$ox" "$oy" "$ow" "$oh")"

  geometry="${float_width}x${float_height}+${x}+${y}"

  mpv \
    --force-window=immediate \
    --title="$title" \
    --geometry="$geometry" \
    --autofit-larger="${float_width}x${float_height}" \
    --autofit="${float_width}x${float_height}" \
    "$url" >/dev/null 2>&1 &
  pid=$!
  mark_and_float "$pid" "$x" "$y"
}

main "$@"
