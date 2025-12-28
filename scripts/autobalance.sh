#!/usr/bin/env bash
set -euo pipefail

# Rebalance the focused workspace to a 2/3 left : 1/3 right horizontal split.
# Exits if the focused workspace is not a simple horizontal split with exactly
# two tiling children (each child can itself be a stack/tabbed container).

LEFT_PCT="${LEFT_PCT:-67}"   # Left side percent (approx 2/3)
RIGHT_PCT=$((100 - LEFT_PCT))

die() { echo "autobalance: $*" >&2; exit 1; }

tree="$(swaymsg -t get_tree)"
focused_id="$(printf '%s' "$tree" | jq '.. | select(.focused?==true) | .id' | head -n1)"
[[ -n "$focused_id" ]] || die "no focused container found"

# Find the nearest ancestor (workspace or container) that:
# - has layout splith
# - has exactly two tiling children (.nodes length == 2)
# - contains the focused container somewhere in its subtree
target_json="$(printf '%s' "$tree" | jq -c --argjson target "$focused_id" '
  def contains_target:
    .. | objects | select(.id==$target) | length > 0;

  def walk(depth):
    . as $n
    | ($n.nodes // []) as $kids
    | (
        (if $n.layout=="splith" and ($kids|length)==2 and ($n | contains_target) then
            [{id:$n.id, depth:depth, nodes:$kids}]
          else [] end)
        + ($kids | map(walk(depth+1)) | add // [])
      );
  walk(0)
  | sort_by(.depth)
  | last // empty
')"

[[ -n "$target_json" ]] || die "no 2-child horizontal split containing the focused window"

nodes_json="$(printf '%s' "$target_json" | jq -c '.nodes')"

readarray -t ids < <(printf '%s' "$nodes_json" | jq -r 'sort_by(.rect.x) | .[].id')
readarray -t widths < <(printf '%s' "$nodes_json" | jq -r 'sort_by(.rect.x) | .[].rect.width')

left_id="${ids[0]}"
right_id="${ids[1]}"
left_w="${widths[0]}"
right_w="${widths[1]}"

swaymsg "[con_id=$left_id]" resize set width "$LEFT_PCT" ppt >/dev/null
swaymsg "[con_id=$right_id]" resize set width "$RIGHT_PCT" ppt >/dev/null

echo "Left width=${left_w}px -> ${LEFT_PCT}% | Right width=${right_w}px -> ${RIGHT_PCT}%"
