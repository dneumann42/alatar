#!/usr/bin/env bash

set -euo pipefail

find_spotify_id() {
  swaymsg -t get_tree \
  | jq -r '
    def walk: recurse(.nodes[]?, .floating_nodes[]?);
    walk
    | select((.app_id=="spotify") or (.window_properties.class=="Spotify"))
    | .id' \
  | head -n1
}

launch_spotify() {
  if command -v spotify >/dev/null 2>&1; then spotify >/dev/null 2>&1 & disown
  elif command -v flatpak >/dev/null 2>&1; then flatpak run com.spotify.Client >/dev/null 2>&1 & disown
  elif command -v snap >/dev/null 2>&1; then snap run spotify >/dev/null 2>&1 & disown
  else echo "spotify client not found" >&2; exit 1
  fi
}

id="$(find_spotify_id || true)"
if [[ -z "${id:-}" ]]; then
  launch_spotify
  for _ in $(seq 1 80); do
    sleep 0.25
    id="$(find_spotify_id || true)"
    [[ -n "${id:-}" ]] && break
  done
fi

[[ -z "${id:-}" ]] && { echo "failed to find spotify window"; exit 1; }
swaymsg "[con_id=$id]" move to scratchpad >/dev/null
swaymsg scratchpad show >/dev/null

