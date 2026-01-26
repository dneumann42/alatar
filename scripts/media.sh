#!/usr/bin/env bash
set -euo pipefail

# Control media (play/pause/prev/next) and emit status for Waybar (JSON).
# Usage:
#   media.sh            -> prints status JSON with icon + track
#   media.sh icon       -> prints status JSON with icon only
#   media.sh track      -> prints status JSON with track only
#   media.sh toggle     -> toggles play/pause
#   media.sh next|prev  -> skip
#   media.sh play/pause -> explicit controls

playerctl_bin=$(command -v playerctl 2>/dev/null)

if [ -z "$playerctl_bin" ]; then
  echo '{"text":"playerctl missing","class":["media","stopped"]}'
  exit 0
fi

# Prefer playerctld if running, then known players, then any.
PLAYERS="${PLAYERCTL_PLAYERS:-playerctld,spotify,firefox,chromium,mpv,%any}"

cmd="${1:-status}"

pc() {
  "$playerctl_bin" -p "$PLAYERS" "$@" 2>/dev/null
}

case "$cmd" in
  toggle) pc play-pause || true ;;
  play) pc play || true ;;
  pause) pc pause || true ;;
  next) pc next || true ;;
  prev) pc previous || true ;;
  icon|track|status|"") ;; # fall through
  *) echo "unknown command" >&2 ;;
esac

status="$(pc status || true)"
[ -z "$status" ] && status="Stopped"

case "$status" in
  Playing) icon="" ;;
  Paused) icon="" ;;
  *) icon="" ;;
esac

info="$(pc metadata --format '{{artist}} — {{title}}' || true)"
info="$(echo "$info" | sed 's/^ *//;s/ *$//')"
[ -z "$info" ] && info="No track"

case "$cmd" in
  icon)
    text="$icon"
    tooltip="$status"
    ;;
  track)
    text="$info"
    tooltip="$info"
    ;;
  *)
    text="$icon $info"
    tooltip="$info"
    ;;
esac

cls="$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')"
cls="${cls:-stopped}"

json_escape() {
  # Minimal JSON string escaper: replace backslash and quotes.
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

text_esc=$(json_escape "$text")
tooltip_esc=$(json_escape "$tooltip")

printf '{"text":"%s","tooltip":"%s","class":["media","%s"]}\n' "$text_esc" "$tooltip_esc" "$cls"
