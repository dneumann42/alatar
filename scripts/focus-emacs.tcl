#!/usr/bin/env tclsh

# Find emacs using swaymsg

set out [exec bash -lc {
 swaymsg -t get_tree | jq -r '
    .. | objects
    | select(.type=="workspace")
    | select((.. | objects | select(.app_id=="emacs")))
    | .name
  ' | head -n1
}]
set ws [string trim $out]
if {$ws eq ""} {
  exec emacsclient -c &
} else {
  puts $ws
}

if {$ws ne ""} {
  catch {exec swaymsg "workspace $ws" 2>/dev/null}
  catch {
    exec swaymsg {[app_id="emacs"] focus} 2>/dev/null
  }
}
