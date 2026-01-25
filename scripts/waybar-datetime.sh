#!/usr/bin/env bash
set -euo pipefail

day=$(date +%-d)
case "$day" in
  1|21|31) suffix="st" ;;
  2|22) suffix="nd" ;;
  3|23) suffix="rd" ;;
  *) suffix="th" ;;
esac

text=$(date +"%B %-d${suffix}, %Y %-I:%M %p")
cal_raw=$(cal)
cal_escaped=${cal_raw//$'\n'/\\n}
cal_escaped=${cal_escaped//\"/\\\"}

printf '{"text":"%s","tooltip":"%s"}' "$text" "$cal_escaped"
