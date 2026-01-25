#!/usr/bin/env tclsh

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir theme.tcl]

# I should be smarter than this but eh

set out [exec bash -lc {
 swaymsg -t get_tree | jq -r '
    .. | objects
    | select(.type=="workspace")
    | select((.. | objects | select(.app_id=="org.qutebrowser.qutebrowser")))
    | .name
  ' | head -n1
}]

set app_id "org.qutebrowser.qutebrowser"

proc toggle {} {
    global app_id out
    set ws [string trim $out]
    set js [expr 1 + 2]
    puts $ws
    puts $js
}

toggle

# set ws [string trim $out]
# if {$ws eq ""} {
#     
#     exec qutebrowser [lindex $argv 0]
#     catch {
# 	exec swaymsg "[]"
#     }
#     
# } else {
#     puts $ws
# }
