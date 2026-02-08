#!/usr/bin/env tclsh
package require Tk

source [file join $::env(HOME) .alatar/lib/theme.tcl] 

load_wallust_theme "theme"
apply_ttk_theme
configure_root_window

# Re-apply and ensure all widgets use wallust theme colors
ttk::style configure TButton -padding {10 5} \
    -background $::theme(button_bg) -foreground $::theme(button_text)

ttk::style configure TLabel -background $::theme(base) -foreground $::theme(text)

ttk::style configure TFrame -background $::theme(base)

ttk::style configure TEntry -fieldbackground $::theme(entry_bg) \
    -foreground $::theme(entry_text) -insertcolor $::theme(text)

# Configure Treeview (table) styling
ttk::style configure Treeview -background $::theme(surface0) \
    -foreground $::theme(text) \
    -fieldbackground $::theme(surface0) \
    -bordercolor $::theme(border) \
    -lightcolor $::theme(border) \
    -darkcolor $::theme(border)

ttk::style configure Treeview.Heading -background $::theme(surface1) \
    -foreground $::theme(text) \
    -bordercolor $::theme(border) \
    -lightcolor $::theme(border) \
    -darkcolor $::theme(border)

ttk::style map Treeview \
    -background [list selected $::theme(selected_bg)] \
    -foreground [list selected $::theme(selected_text)]

ttk::style map Treeview.Heading \
    -background [list active $::theme(heading_active)]

# Configure Notebook (tabs) styling
ttk::style configure TNotebook -background $::theme(base)
ttk::style configure TNotebook.Tab -background $::theme(tab_bg) \
    -foreground $::theme(tab_text) -padding {12 6}

# Configure text widget colors (not handled by ttk theme)
option add *Text.background $::theme(entry_bg)
option add *Text.foreground $::theme(entry_text)
option add *Text.insertBackground $::theme(text)
option add *Text.selectBackground $::theme(selected_bg)
option add *Text.selectForeground $::theme(selected_text)

wm title . "Clyde - Package Manager"
wm geometry . "900x800"

ttk::notebook .nb
pack .nb -fill both -expand 1 -padx 5 -pady 5

ttk::frame .nb.search
.nb add .nb.search -text "Search"

ttk::frame .nb.updates
.nb add .nb.updates -text "Updates"

# Search field
ttk::frame .nb.search.top
pack .nb.search.top -fill x -padx 10 -pady 10

ttk::label .nb.search.top.label -text "Search:"
pack .nb.search.top.label -side left -padx {0 5}

ttk::entry .nb.search.top.entry -width 40
pack .nb.search.top.entry -side left -fill x -expand 1 -padx {0 5}

ttk::button .nb.search.top.button -text "Search" -command search_packages
pack .nb.search.top.button -side left

# Results table
ttk::frame .nb.search.results
pack .nb.search.results -fill both -expand 1 -padx 10 -pady {0 10}

# Create treeview with scrollbar
ttk::treeview .nb.search.results.tree -columns {repo name version} -show {headings} -yscrollcommand {.nb.search.results.scroll set}
ttk::scrollbar .nb.search.results.scroll -orient vertical -command {.nb.search.results.tree yview}

.nb.search.results.tree heading repo -text "Repository"
.nb.search.results.tree heading name -text "Package"
.nb.search.results.tree heading version -text "Version"

.nb.search.results.tree column repo -width 100
.nb.search.results.tree column name -width 250
.nb.search.results.tree column version -width 150

pack .nb.search.results.scroll -side right -fill y
pack .nb.search.results.tree -side left -fill both -expand 1

# Debounce timer
set ::search_timer ""

# Debounced search trigger
proc trigger_search {} {
    global search_timer
    # Cancel existing timer
    if {$search_timer ne ""} {
        after cancel $search_timer
    }
    # Set new timer (500ms debounce)
    set search_timer [after 500 search_packages]
}

# Search function
proc search_packages {} {
    global search_timer
    set search_timer ""

    set query [.nb.search.top.entry get]
    if {$query eq ""} {
        # Clear results if query is empty
        .nb.search.results.tree delete [.nb.search.results.tree children {}]
        return
    }

    # Clear existing results
    .nb.search.results.tree delete [.nb.search.results.tree children {}]

    # Run pacman -Ss
    if {[catch {exec pacman -Ss $query} output]} {
        # No results or error
        return
    }

    # Parse output
    set lines [split $output "\n"]
    set i 0
    while {$i < [llength $lines]} {
        set line [lindex $lines $i]

        # Check if this is a package line (repo/package version)
        if {[regexp {^([^/]+)/(\S+)\s+(.+)$} $line match repo name version]} {
            # Next line is the description (skip it for now)
            .nb.search.results.tree insert {} end -values [list $repo $name $version]
        }

        incr i
    }
}

# Bind Enter key and key release for debounced search
bind .nb.search.top.entry <Return> search_packages
bind .nb.search.top.entry <KeyRelease> trigger_search

# Updates tab header
ttk::frame .nb.updates.top
pack .nb.updates.top -fill x -padx 10 -pady 10

ttk::label .nb.updates.top.label -text "Available package updates:"
pack .nb.updates.top.label -side left -padx {0 10}

ttk::button .nb.updates.top.refresh -text "Refresh" -command load_updates
pack .nb.updates.top.refresh -side left

ttk::label .nb.updates.top.count -text ""
pack .nb.updates.top.count -side left -padx {10 0}

# Updates table
ttk::frame .nb.updates.results
pack .nb.updates.results -fill both -expand 1 -padx 10 -pady {0 10}

# Create treeview with scrollbar
ttk::treeview .nb.updates.results.tree -columns {package current new} -show {headings} -yscrollcommand {.nb.updates.results.scroll set}
ttk::scrollbar .nb.updates.results.scroll -orient vertical -command {.nb.updates.results.tree yview}

.nb.updates.results.tree heading package -text "Package"
.nb.updates.results.tree heading current -text "Current Version"
.nb.updates.results.tree heading new -text "New Version"

.nb.updates.results.tree column package -width 250
.nb.updates.results.tree column current -width 200
.nb.updates.results.tree column new -width 200

pack .nb.updates.results.scroll -side right -fill y
pack .nb.updates.results.tree -side left -fill both -expand 1

# Output console for update process
ttk::frame .nb.updates.console
pack .nb.updates.console -fill both -expand 0 -padx 10 -pady {0 10}

ttk::label .nb.updates.console.label -text "Update Output:"
pack .nb.updates.console.label -anchor w

text .nb.updates.console.text -height 15 -wrap word -yscrollcommand {.nb.updates.console.scroll set} -state disabled
ttk::scrollbar .nb.updates.console.scroll -orient vertical -command {.nb.updates.console.text yview}

pack .nb.updates.console.scroll -side right -fill y
pack .nb.updates.console.text -side left -fill both -expand 1

# Bottom buttons
ttk::frame .nb.updates.bottom
pack .nb.updates.bottom -fill x -padx 10 -pady {0 10}

button .nb.updates.bottom.update -text "Update All Packages" -command run_update \
    -background $::theme(button_bg) -foreground $::theme(button_text) \
    -activebackground $::theme(heading_active) -activeforeground $::theme(button_text) \
    -relief raised -borderwidth 1 -padx 10 -pady 5
pack .nb.updates.bottom.update -side left -padx {0 10}

ttk::label .nb.updates.bottom.status -text ""
pack .nb.updates.bottom.status -side left -padx {10 0}

# Load updates function
proc load_updates {} {
    # Clear existing results
    .nb.updates.results.tree delete [.nb.updates.results.tree children {}]
    .nb.updates.top.count configure -text "Checking for updates..."
    .nb.updates.top.refresh configure -state disabled

    # Force UI update
    update idletasks

    # Show in console
    console_append "=== Checking for updates ===\n"
    console_append "Running: pacman -Qu\n\n"

    # Run after a brief delay to allow UI to update
    after 100 [list load_updates_async]
}

proc load_updates_async {} {
    # Run pacman -Qu to check for updates
    if {[catch {exec pacman -Qu} output]} {
        # No updates available or error
        .nb.updates.top.count configure -text "No updates available"
        .nb.updates.top.refresh configure -state normal
        console_append "No updates available.\n\n"
        return
    }

    # Parse output
    set lines [split $output "\n"]
    set count 0

    foreach line $lines {
        if {$line eq ""} continue

        # Format: package current-version -> new-version
        if {[regexp {^(\S+)\s+(\S+)\s+->\s+(\S+)} $line match package current new]} {
            .nb.updates.results.tree insert {} end -values [list $package $current $new]
            incr count
        }
    }

    .nb.updates.top.count configure -text "$count update(s) available"
    .nb.updates.top.refresh configure -state normal
    console_append "Found $count update(s) available.\n\n"
}

# Global variable for update process
set ::update_channel ""

# Append text to console
proc console_append {text} {
    .nb.updates.console.text configure -state normal
    .nb.updates.console.text insert end $text
    .nb.updates.console.text see end
    .nb.updates.console.text configure -state disabled
}

# Clear console
proc console_clear {} {
    .nb.updates.console.text configure -state normal
    .nb.updates.console.text delete 1.0 end
    .nb.updates.console.text configure -state disabled
}

# Read output from update process
proc read_update_output {} {
    global update_channel

    if {[eof $update_channel]} {
        # Close the channel and check exit status
        if {[catch {close $update_channel} err]} {
            # Non-zero exit or error
            console_append "\n=== Update process finished with errors ===\n"
            console_append "Error: $err\n"
            .nb.updates.bottom.status configure -text "Update failed!"
        } else {
            # Success
            console_append "\n=== Update process completed successfully ===\n"
            .nb.updates.bottom.status configure -text "Update completed!"
        }

        set update_channel ""
        .nb.updates.bottom.update configure -state normal

        # Refresh the updates list
        after 1000 load_updates
        return
    }

    if {[catch {gets $update_channel line} result]} {
        console_append "Error reading output: $result\n"
        return
    }

    if {$result >= 0} {
        console_append "$line\n"
    }
}

# Run system update
proc run_update {} {
    global update_channel

    # Check if update is already running
    if {$update_channel ne ""} {
        return
    }

    # Clear console
    console_clear
    console_append "=== Starting system update ===\n"
    console_append "Running: pkexec pacman -Syu --noconfirm\n\n"

    # Disable update button
    .nb.updates.bottom.update configure -state disabled
    .nb.updates.bottom.status configure -text "Updating..."

    # Run pacman update with unbuffered output (using pkexec for polkit authentication)
    # Use setsid to detach from terminal and force GUI authentication
    # --noconfirm avoids interactive prompts
    if {[catch {open "|setsid -w stdbuf -oL -eL pkexec pacman -Syu --noconfirm --color=never 2>&1" r} update_channel]} {
        console_append "Error starting update: $update_channel\n"
        set update_channel ""
        .nb.updates.bottom.update configure -state normal
        .nb.updates.bottom.status configure -text "Update failed!"
        return
    }

    # Configure channel as non-blocking
    fconfigure $update_channel -blocking 0 -buffering none

    # Set up event handler to read output
    fileevent $update_channel readable read_update_output
}

# Load updates on startup
load_updates
