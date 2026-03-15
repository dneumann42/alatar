#!/usr/bin/env tclsh
# confirm.tcl - Small centered confirmation dialog
# Usage: confirm.tcl "Message text" "command to run on yes"

package require Tk
tk appname "com.alatar.confirm"

source [file join $::env(HOME) .alatar/lib/theme.tcl]
load_wallust_theme "theme"
apply_ttk_theme
configure_root_window

set message [lindex $argv 0]
set action  [lindex $argv 1]

if {$message eq "" || $action eq ""} {
    puts stderr "Usage: confirm.tcl <message> <command>"
    exit 1
}

# Remove all window decorations and keep it floating/centered
wm title . $message
wm resizable . 0 0

# Remove title bar on sway (will be treated as floating due to small size)
# We set a fixed geometry and center it after mapping
wm geometry . "320x120"

# Outer border frame
frame .border -bg $::theme(border) -relief flat -borderwidth 2
pack .border -fill both -expand 1 -padx 6 -pady 6

frame .border.inner -bg $::theme(base)
pack .border.inner -fill both -expand 1 -padx 2 -pady 2

# Message label
label .border.inner.msg \
    -text $message \
    -background $::theme(base) \
    -foreground $::theme(text) \
    -font {TkDefaultFont 11} \
    -wraplength 280 \
    -justify center \
    -pady 12
pack .border.inner.msg -fill x -padx 16

# Button row
frame .border.inner.btns -background $::theme(base)
pack .border.inner.btns -fill x -padx 16 -pady {4 12}

shadow_button .border.inner.btns.yes -text "Yes" \
    -command [list run_action $action] \
    -bg $::theme(red) -fg $::theme(text) \
    -activebackground $::theme(mauve) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 20 -pady 6 -cursor hand2
pack .border.inner.btns.yes -side left -expand 1

shadow_button .border.inner.btns.no -text "No" \
    -command { exit 0 } \
    -bg $::theme(surface1) -fg $::theme(text) \
    -activebackground $::theme(surface2) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 20 -pady 6 -cursor hand2
pack .border.inner.btns.no -side left -expand 1

proc run_action {cmd} {
    exec setsid sh -c $cmd &
    exit 0
}

# Center on screen after window is mapped
proc center_window {} {
    set sw [winfo screenwidth .]
    set sh [winfo screenheight .]
    set ww [winfo reqwidth .]
    set wh [winfo reqheight .]
    set x [expr {($sw - $ww) / 2}]
    set y [expr {($sh - $wh) / 2}]
    wm geometry . "+$x+$y"
}

# Close on Escape or Enter (Enter = No for safety)
bind . <Escape> { exit 0 }
bind . <Return> { exit 0 }
bind . <y> { run_action $action }
bind . <n> { exit 0 }

after 1 center_window
