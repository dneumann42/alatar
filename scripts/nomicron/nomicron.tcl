#!/usr/bin/env tclsh
# Nomicron - System control and media interface
# Main entry point

package require Tk
# Set instance name for XWayland (will appear in window_properties.instance)
tk appname "com.alatar.nomicron"

# Set script directory for use by action procedures
set script_dir [file join $::env(HOME) .alatar/scripts]

# Load theme
source [file join $::env(HOME) .alatar/lib/theme.tcl]
load_wallust_theme "nomicron"
apply_ttk_theme
configure_root_window

# Set window title and geometry
wm title . "nomicron"
wm geometry . "640x720+0+32"

# Set unique Sway mark for scratchpad toggling (target this window by instance)
after 100 {catch {exec swaymsg {[instance="^com\.alatar\.nomicron"] mark nomicron-scratchpad}}}

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
build_bordered_container
build_tome_image
build_main_layout
setup_keybindings

# Start media timer
start_spotify_timer

# Start theme watcher (uses inotify for instant updates)
start_theme_watcher "nomicron"
