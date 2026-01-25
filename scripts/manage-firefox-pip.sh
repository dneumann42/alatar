#!/usr/bin/env bash
set -euo pipefail

# Keep Firefox Picture-in-Picture windows floating and sized/positioned like
# the last focused Firefox window so they land on top of the browser.

last_rect=""
fallback_size="${FALLBACK_SIZE:-1600 900}"
offset_x="${PIP_OFFSET_X:-0}"
offset_y="${PIP_OFFSET_Y:-0}"
debug="${DEBUG_PIP:-0}"

focused_firefox_rect() {
  swaymsg -t get_tree | jq -r '
    recurse(.nodes[]?, .floating_nodes[]?)
    | select((.app_id=="firefox") or (.window_properties.class//"")== "firefox")
    | select(.focused==true)
    | .rect
    | "\(.x) \(.y) \(.width) \(.height)"
    ' | head -n1
}

apply_layout() {
  local con_id="$1"
  local rect="$(focused_firefox_rect)"
  if [[ -z "$rect" ]]; then
    rect="$last_rect"
  fi

  if [[ -n "$rect" ]]; then
    read -r x y w h <<<"$rect"
    x=$((x + offset_x))
    y=$((y + offset_y))
    swaymsg "[con_id=$con_id]" floating enable, move position "$x" "$y", resize set "$w" "$h", focus >/dev/null 2>&1 || true
    if [[ "$debug" == "1" ]]; then
      pip_rect="$(swaymsg -t get_tree | jq -r --argjson id "$con_id" '
        recurse(.nodes[]?, .floating_nodes[]?)
        | select(.id==$id)
        | .rect
        | "\(.x) \(.y) \(.width) \(.height)"
        ' | head -n1 || true)"
      if [[ -n "$pip_rect" ]]; then
        read -r px py pw ph <<<"$pip_rect"
        fx_x2=$((x + w))
        fx_y2=$((y + h))
        pip_x2=$((px + pw))
        pip_y2=$((py + ph))
        overlap_w=$(( (fx_x2 < pip_x2 ? fx_x2 : pip_x2) - (x > px ? x : px) ))
        overlap_h=$(( (fx_y2 < pip_y2 ? fx_y2 : pip_y2) - (y > py ? y : py) ))
        overlap_area=$(( overlap_w > 0 && overlap_h > 0 ? overlap_w * overlap_h : 0 ))
        >&2 echo "[pip-debug] firefox_rect=${x} ${y} ${w} ${h} pip_rect=${pip_rect} overlap_area=${overlap_area} delta_dx=$((px - x)) delta_dy=$((py - y)) delta_dw=$((pw - w)) delta_dh=$((ph - h))"
      else
        >&2 echo "[pip-debug] pip rect not found for con_id=${con_id}"
      fi
    fi
    return
  fi

  read -r fallback_w fallback_h <<<"$fallback_size"
  swaymsg "[con_id=$con_id]" floating enable, move position center, resize set "$fallback_w" "$fallback_h", focus >/dev/null 2>&1 || true
}

swaymsg -t subscribe -m '["window"]' | while IFS= read -r event; do
  change="$(jq -r '.change' <<<"$event")"
  con_id="$(jq -r '.container.id' <<<"$event")"
  app_id="$(jq -r '.container.app_id // .container.window_properties.class // ""' <<<"$event")"
  title="$(jq -r '.container.window_properties.title // .container.name // ""' <<<"$event")"
  rect="$(jq -r '.container.rect | "\(.x) \(.y) \(.width) \(.height)"' <<<"$event")"

  if [[ "$app_id" != "firefox" ]]; then
    continue
  fi

  if [[ "$title" == "Picture-in-Picture" ]]; then
    if [[ "$change" == "new" || "$change" == "focus" || "$change" == "title" ]]; then
      apply_layout "$con_id"
    fi
    continue
  fi

  if [[ "$change" == "focus" && -n "$rect" ]]; then
    last_rect="$rect"
  fi
done
