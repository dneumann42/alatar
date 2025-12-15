#!/usr/bin/env bash
set -euo pipefail

# Toggle a floating terminal with a stable app_id/class so we can show/hide it.

APP_ID="${APP_ID:-floating-term}"
TITLE="${TITLE:-$APP_ID}"
MARK="${MARK:-$APP_ID}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="${LAUNCHER:-$SCRIPT_DIR/launch-floating-command.sh}"
SESSION_NAME="${SESSION_NAME:-floating_toggle}"
CMD="${*:-zellij attach --create $SESSION_NAME}"

toggle() {
  swaymsg "$@" >/dev/null 2>&1 || true
}

node_json="$(swaymsg -t get_tree | jq -c --arg app "$APP_ID" --arg title "$TITLE" --arg mark "$MARK" '
  recurse(.nodes[]?, .floating_nodes[]?)
  | select(
      ((.marks // []) | index($mark))
      or .app_id == $app
      or (.window_properties.class? == $app)
      or (.name? == $title)
      or (.window_properties.title? == $title)
      or ((.name // "") | startswith($title))
      or ((.window_properties.title // "") | startswith($title))
    )
  | {id, focused, visible: (.visible // false)}
  ' | head -n1)"

if [[ -z "$node_json" ]]; then
  # Not running; launch new floating terminal.
  exec "$LAUNCHER" "$CMD"
fi

node_id="$(jq -r '.id' <<<"$node_json")"
node_focused="$(jq -r '.focused' <<<"$node_json")"
node_visible="$(jq -r '.visible' <<<"$node_json")"

if [[ "$node_focused" == "true" ]]; then
  toggle "[con_id=$node_id]" move scratchpad
elif [[ "$node_visible" == "true" ]]; then
  toggle "[con_id=$node_id]" focus
else
  toggle "[con_id=$node_id]" scratchpad show
fi
