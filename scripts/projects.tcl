#!/usr/bin/env tclsh
package require Tk

source [file join $::env(HOME) .alatar/lib/theme.tcl] 

load_wallust_theme "pathedit"
apply_ttk_theme
configure_root_window

wm title . "Clyde"
wm geometry . "800x600"

frame .main_container -b $theme(base)

pack .main_container -side top -fill both -expand 1 -padx 4 -pady 4

