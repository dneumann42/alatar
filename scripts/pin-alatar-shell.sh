#!/usr/bin/env bash
swaymsg -t subscribe '["window"]' | jq -r --unbuffered '
      select(.change=="move" or .change=="resize" or .change=="floating")
    | select(.container.title=="Alatar Shell")
    | .container.id' | while read -r id; do
      swaymsg "[con_id=$id]" "floating enable, sticky enable, border pixel 0, resize set width 300
  px height 80 px, move position 100%-300px 0px"
  done
