#!/usr/bin/env bash
set -euo pipefail

# Launch a command inside a floating Ghostty window (fallback to the generic launcher).

TITLE="${TITLE:-Floating Command}"
APP_ID="${APP_ID:-floating-term}"
MARK="${MARK:-$APP_ID}"
WIDTH="${WIDTH:-110}"
HEIGHT="${HEIGHT:-32}"
FLOAT_WIDTH="${FLOAT_WIDTH:-1400}"
FLOAT_HEIGHT="${FLOAT_HEIGHT:-900}"
CMD="${*:-bash}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

float_and_center() {
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

if command -v ghostty >/dev/null 2>&1; then
  ghostty --class="$APP_ID" --title="$TITLE" --window-width="$WIDTH" --window-height="$HEIGHT" -e bash -lc "$CMD" &
  sleep 0.15
  float_and_center $!
  exit 0
fi

exec "$SCRIPT_DIR/launch-floating-command.sh" "$CMD"
