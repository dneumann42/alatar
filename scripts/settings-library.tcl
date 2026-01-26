#!/usr/bin/env tclsh

package require Tk
source [file join $::env(HOME) .alatar/lib/theme.tcl] 

load_wallust_theme "help"
apply_ttk_theme
configure_root_window

tk title . "Settings Library"
