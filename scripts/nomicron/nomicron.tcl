#!/usr/bin/env tclsh
# Nomicron - System control and media interface
# Main entry point

package require Tk

# Set script directory for use by action procedures
set script_dir [file join $::env(HOME) .alatar/scripts]

# Load theme
source [file join $::env(HOME) .alatar/lib/theme.tcl]
load_wallust_theme "nomicron"
apply_ttk_theme
configure_root_window

# Set window title and geometry
wm title . "nomicron"
wm geometry . "640x640"

# Load modules
set nomicron_dir [file dirname [file normalize [info script]]]
source [file join $nomicron_dir ui.tcl]
source [file join $nomicron_dir actions.tcl]
source [file join $nomicron_dir media.tcl]
source [file join $nomicron_dir layout.tcl]

# Exit handler
proc cleanup_and_exit {} {
    exit
}

bind . <Escape> cleanup_and_exit
wm protocol . WM_DELETE_WINDOW cleanup_and_exit

# Build UI
build_tome_image
build_main_layout
setup_keybindings

# Start media timer
start_spotify_timer
