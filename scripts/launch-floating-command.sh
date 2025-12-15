#!/usr/bin/env bash
set -euo pipefail

# Launch an arbitrary command inside a floating terminal window.

TITLE="${TITLE:-Floating Command}"
APP_ID="${APP_ID:-floating-term}"
MARK="${MARK:-$APP_ID}"
WIDTH="${WIDTH:-110}"
HEIGHT="${HEIGHT:-32}"
FLOAT_WIDTH="${FLOAT_WIDTH:-1400}"
FLOAT_HEIGHT="${FLOAT_HEIGHT:-900}"

CMD="${*:-bash}"

mark_and_float() {
  local pid="$1"
  for _ in $(seq 1 40); do
    node_id="$(swaymsg -t get_tree | jq -r --arg pid "$pid" --arg title "$TITLE" --arg app "$APP_ID" '
      recurse(.nodes[]?, .floating_nodes[]?)
      | select(
          (.pid|tostring==$pid)
          or .app_id==$app
          or (.name//"")==$title
          or (.window_properties.title//"")==$title
        )
      | .id
      ' | head -n1)"
    if [[ -n "$node_id" ]]; then
      swaymsg "[con_id=$node_id]" mark "$MARK", floating enable, resize set $FLOAT_WIDTH $FLOAT_HEIGHT, move position center >/dev/null 2>&1 || true
      return
    fi
    sleep 0.05
  done
}

launch() {
  "$@" &
  pid=$!
  mark_and_float "$pid"
  exit 0
}

if command -v ghostty >/dev/null 2>&1; then
  launch ghostty --class="$APP_ID" --title="$TITLE" --window-width="$WIDTH" --window-height="$HEIGHT" -e bash -lc "$CMD"
elif command -v foot >/dev/null 2>&1; then
  launch foot -a "$APP_ID" -T "$TITLE" -W "$WIDTH" -H "$HEIGHT" bash -lc "$CMD"
elif command -v alacritty >/dev/null 2>&1; then
  launch alacritty --class "$APP_ID" --title "$TITLE" --option window.dimensions.columns="$WIDTH" --option window.dimensions.lines="$HEIGHT" -e bash -lc "$CMD"
elif command -v kitty >/dev/null 2>&1; then
  launch kitty --class "$APP_ID" --title "$TITLE" --override font_size=11.0 --override initial_window_width=${WIDTH}c --override initial_window_height=${HEIGHT}c bash -lc "$CMD"
elif command -v wezterm >/dev/null 2>&1; then
  launch wezterm start --class "$APP_ID" --title "$TITLE" --initial-size "${WIDTH}x${HEIGHT}" -- bash -lc "$CMD"
elif command -v xterm >/dev/null 2>&1; then
  launch xterm -class "$APP_ID" -T "$TITLE" -geometry "${WIDTH}x${HEIGHT}" -e bash -lc "$CMD"
else
  echo "No supported terminal found (ghostty, foot, alacritty, kitty, wezterm, xterm)." >&2
  exit 1
fi
