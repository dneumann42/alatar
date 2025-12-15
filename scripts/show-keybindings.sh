#!/usr/bin/env bash
set -uo pipefail

# Print Sway keybindings in two columns.
# Each binding in keybindings.conf should be preceded by a comment
# that serves as its description.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDINGS_FILE="${BINDINGS_FILE:-$HOME/.alatar/alatar_dots/sway/keybindings.conf}"

if [ ! -f "$BINDINGS_FILE" ]; then
  echo "Missing keybindings file: $BINDINGS_FILE" >&2
  exit 1
fi

cols=${COLUMNS:-172}
pad=2

awk -v cols="$cols" -v pad="$pad" '
BEGIN {
  mode = "default"
  desc = ""
  count = 0
}
function add(entry) { items[count++] = entry }
function visual_width(s,    i, c, len) {
  len = 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    # crude width accounting; treat tabs as 4
    if (c == "\t") len += 4
    else len += 1
  }
  return len
}
{
  sub(/\r$/, "")
  if ($0 ~ /^[[:space:]]*mode[[:space:]]*"/) {
    match($0, /mode[[:space:]]*"([^"]+)"/, m)
    mode = m[1]
    next
  }
  if ($0 ~ /^[[:space:]]*}/) { mode = "default"; next }
  if ($0 ~ /^[[:space:]]*#/) { desc = $0; sub(/^[[:space:]]*#[[:space:]]*/, "", desc); next }
  if ($0 ~ /^[[:space:]]*bindsym/) {
    line = $0
    sub(/^[[:space:]]*bindsym[[:space:]]*/, "", line)
    sub(/[[:space:]]*\\[[:space:]]*$/, "", line)
    n = split(line, toks, /[[:space:]]+/)
    idx = 1
    while (idx <= n && toks[idx] ~ /^--/) idx++
    key = (idx <= n) ? toks[idx] : ""
    idx++
    cmd = (idx <= n) ? substr(line, index(line, toks[idx])) : ""
    text = desc != "" ? desc : cmd
    add(sprintf("[%s] %s - %s", mode, key, text))
    desc = ""
  }
}
END {
  col_width = int((cols - pad) / 2)
  if (col_width < 20) col_width = 20
  padstr = sprintf("%" pad "s", "")

  cyan = "\033[36m"
  white = "\033[37m"
  reset = "\033[0m"

  printf "\nSway Keybindings\n\n"
  for (i = 0; i < count; ) {
    left = items[i++]
    right = (i < count) ? items[i++] : ""
    split(left, la, " - ")
    split(right, ra, " - ")
    lkey = la[1]; ldesc = (length(la) > 1) ? la[2] : ""
    rkey = ra[1]; rdesc = (length(ra) > 1) ? ra[2] : ""

    ltext = lkey
    if (ldesc != "") ltext = ltext " - " ldesc
    rtext = rkey
    if (rdesc != "") rtext = rtext " - " rdesc

    if (visual_width(ltext) > col_width)  ldesc = substr(ldesc, 1, col_width - visual_width(lkey) - 5) "…"
    if (visual_width(rtext) > col_width)  rdesc = substr(rdesc, 1, col_width - visual_width(rkey) - 5) "…"

    lplain = lkey; if (ldesc != "") lplain = lplain " - " ldesc
    rplain = rkey; if (rdesc != "") rplain = rplain " - " rdesc

    lcolored = cyan lkey reset
    if (ldesc != "") lcolored = lcolored " " white "- " ldesc reset
    rcolored = cyan rkey reset
    if (rdesc != "") rcolored = rcolored " " white "- " rdesc reset

    lpad = col_width - visual_width(lplain); if (lpad < 0) lpad = 0
    rpad = col_width - visual_width(rplain); if (rpad < 0) rpad = 0

    printf "%s%*s%s%s%*s\n", lcolored, lpad, "", padstr, rcolored, rpad, ""
  }
}
' "$BINDINGS_FILE"
