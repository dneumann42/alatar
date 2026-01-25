#!/usr/bin/env tclsh

# Sway Config File Watcher
# Watches Sway configuration files and reloads Sway when they change

set sway_config_dir "$::env(HOME)/.config/sway"
set watch_files [list \
    "$sway_config_dir/config" \
    "$sway_config_dir/keybindings.conf" \
    "$sway_config_dir/colors.conf" \
    "$sway_config_dir/variables.conf" \
]

proc log {msg} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts "\[$timestamp\] $msg"
    flush stdout
}

proc reload_sway {} {
    log "Config change detected, reloading Sway..."
    if {[catch {exec swaymsg reload 2>@1} result]} {
        log "ERROR: Failed to reload Sway: $result"
    } else {
        log "Sway reloaded successfully"
    }
}

proc watch_files {files} {
    # Build the inotifywait command
    set cmd [list inotifywait -m -e modify -e create -e delete -e move]
    foreach file $files {
        if {[file exists $file]} {
            lappend cmd $file
        } else {
            log "WARNING: File not found: $file"
        }
    }

    log "Starting Sway config watcher..."
    log "Watching files: $files"

    # Open a pipe to inotifywait
    if {[catch {open "|$cmd 2>@1" r} pipe]} {
        log "ERROR: Failed to start inotifywait: $pipe"
        log "Make sure inotify-tools is installed"
        exit 1
    }

    # Set non-blocking mode and configure the channel
    fconfigure $pipe -blocking 0 -buffering line

    # Set up event handler for readable data
    fileevent $pipe readable [list handle_event $pipe]
}

proc handle_event {pipe} {
    if {[eof $pipe]} {
        log "inotifywait process ended unexpectedly"
        catch {close $pipe}
        exit 1
    }

    if {[catch {gets $pipe line} result]} {
        log "ERROR reading from inotifywait: $result"
        return
    }

    if {$line ne ""} {
        reload_sway
    }
}

# Check if inotifywait is available
if {[catch {exec which inotifywait}]} {
    log "ERROR: inotifywait not found. Please install inotify-tools package."
    exit 1
}

# Check if swaymsg is available
if {[catch {exec which swaymsg}]} {
    log "ERROR: swaymsg not found. Is Sway installed?"
    exit 1
}

# Start watching
watch_files $watch_files

# Enter event loop
vwait forever
