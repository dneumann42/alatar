#!/usr/bin/env bash
set -euo pipefail

# Focus or move within the current vertical column (splitv) without jumping to
# other columns. If there is no sibling in the requested direction, fall back
# to sway's default focus/move.
#
# Usage: column-nav.sh focus up|down
#        column-nav.sh move  up|down

action="${1:-}"
dir="${2:-}"

[[ "$action" =~ ^(focus|move)$ ]] || { echo "column-nav: first arg must be focus|move" >&2; exit 1; }
[[ "$dir" =~ ^(up|down)$ ]] || { echo "column-nav: second arg must be up|down" >&2; exit 1; }

tree="$(swaymsg -t get_tree)"
focused_id="$(printf '%s' "$tree" | jq '.. | select(.focused?==true) | .id' | head -n1)"
[[ -n "$focused_id" ]] || { echo "column-nav: no focused container" >&2; exit 1; }

target_id="$(printf '%s' "$tree" | jq -r --argjson target "$focused_id" --arg dir "$dir" '
  def has_target:
    (.id? == $target) or ((.nodes // []) | any(has_target));

  def nearest_splitv:
    if has_target and .layout=="splitv" and (.nodes // [] | length)>=2 then
      {found:true, node:., depth:0}
    else
      (.nodes // [] | map(nearest_splitv) | map(select(.found==true)))
      | if length==0 then {found:false}
        else (sort_by(.depth) | .[0]) // {found:false}
        end
      | if .found then .depth += 1 else . end
    end;

  nearest_splitv
  | select(.found==true)
  | .node as $n
  | $n.nodes as $kids
  | ([$kids[] | has_target] | indices(true) | first) as $idx
  | ([$kids[] | .id]) as $ids
  | if ($idx|type)=="number" then
      if $dir=="up" and $idx>0 then $ids[$idx-1]
      elif $dir=="down" and $idx<($ids|length-1) then $ids[$idx+1]
      else null end
    else null end
  end
')" || true

if [[ -n "$target_id" && "$target_id" != "null" ]]; then
  if [[ "$action" == "focus" ]]; then
    swaymsg "[con_id=$target_id]" focus >/dev/null
  else
    swaymsg "[con_id=$focused_id]" move "$dir" >/dev/null
  fi
else
  # Fallback to sway default behavior
  if [[ "$action" == "focus" ]]; then
    swaymsg focus "$dir" >/dev/null
  else
    swaymsg move "$dir" >/dev/null
  fi
fi
