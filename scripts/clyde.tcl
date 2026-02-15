#!/usr/bin/env tclsh
package require Tk
tk appname "com.alatar.clyde"

source [file join $::env(HOME) .alatar/lib/theme.tcl]

load_wallust_theme "theme"
apply_ttk_theme
configure_root_window

# Re-apply and ensure all widgets use wallust theme colors
ttk::style configure TButton -padding {10 5} \
    -background $::theme(button_bg) -foreground $::theme(button_text) \
    -bordercolor $::theme(border) -relief raised

ttk::style map TButton \
    -background [list active $::theme(heading_active) pressed $::theme(selected_bg)] \
    -foreground [list active $::theme(button_text) pressed $::theme(button_text)]

ttk::style configure TLabel -background $::theme(base) -foreground $::theme(text)

ttk::style configure TFrame -background $::theme(base)

ttk::style configure TEntry -fieldbackground $::theme(entry_bg) \
    -foreground $::theme(entry_text) -insertcolor $::theme(text) \
    -bordercolor $::theme(border)

ttk::style map TEntry \
    -fieldbackground [list readonly $::theme(surface0) disabled $::theme(surface0)] \
    -bordercolor [list focus $::theme(sapphire)]

# Configure Treeview (table) styling with alternating colors
ttk::style configure Treeview -background $::theme(base) \
    -foreground $::theme(text) \
    -fieldbackground $::theme(base) \
    -bordercolor $::theme(border) \
    -lightcolor $::theme(border) \
    -darkcolor $::theme(border)

ttk::style configure Treeview.Heading -background $::theme(heading) \
    -foreground $::theme(lavender) \
    -bordercolor $::theme(border) \
    -lightcolor $::theme(border) \
    -darkcolor $::theme(border) \
    -font {TkDefaultFont 10 bold}

ttk::style map Treeview \
    -background [list selected $::theme(mauve)] \
    -foreground [list selected $::theme(base)]

ttk::style map Treeview.Heading \
    -background [list active $::theme(heading_active)] \
    -foreground [list active $::theme(sapphire)]

# Configure Notebook (tabs) styling
ttk::style configure TNotebook -background $::theme(base) -bordercolor $::theme(border)
ttk::style configure TNotebook.Tab -background $::theme(tab_bg) \
    -foreground $::theme(lavender) -padding {12 6} \
    -bordercolor $::theme(border)

ttk::style map TNotebook.Tab \
    -background [list selected $::theme(tab_selected_bg) active $::theme(tab_active_bg)] \
    -foreground [list selected $::theme(peach) active $::theme(sapphire)]

# Configure text widget colors (not handled by ttk theme)
option add *Text.background $::theme(entry_bg)
option add *Text.foreground $::theme(entry_text)
option add *Text.insertBackground $::theme(text)
option add *Text.selectBackground $::theme(selected_bg)
option add *Text.selectForeground $::theme(selected_text)

wm title . "Clyde - Package Manager"
wm geometry . "1200x800"

ttk::notebook .nb
pack .nb -fill both -expand 1 -padx 5 -pady 5

# ===== SEARCH TAB =====
ttk::frame .nb.search
.nb add .nb.search -text "Search"

# Search field
ttk::frame .nb.search.top
pack .nb.search.top -fill x -padx 10 -pady 10

ttk::label .nb.search.top.label -text "Search:"
pack .nb.search.top.label -side left -padx {0 5}

ttk::entry .nb.search.top.entry -width 40
pack .nb.search.top.entry -side left -fill x -expand 1 -padx {0 5}

shadow_button .nb.search.top.button -text "Search" -command search_packages \
    -bg $::theme(sapphire) -fg $::theme(base) \
    -activebackground $::theme(teal) -activeforeground $::theme(base) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.search.top.button -side left -padx {0 5}

shadow_button .nb.search.top.install -text "Install Selected" -command install_selected_package \
    -bg $::theme(green) -fg $::theme(base) \
    -activebackground $::theme(teal) -activeforeground $::theme(base) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.search.top.install -side left

# Main content area with table and details
ttk::frame .nb.search.content
pack .nb.search.content -fill both -expand 1 -padx 10 -pady {0 10}

# Results table (left side)
ttk::frame .nb.search.content.left
pack .nb.search.content.left -side left -fill both -expand 1 -padx {0 5}

ttk::treeview .nb.search.content.left.tree -columns {repo name version} -show {headings} -yscrollcommand {.nb.search.content.left.scroll set}
ttk::scrollbar .nb.search.content.left.scroll -orient vertical -command {.nb.search.content.left.tree yview}

.nb.search.content.left.tree heading repo -text "Repository"
.nb.search.content.left.tree heading name -text "Package"
.nb.search.content.left.tree heading version -text "Version"

.nb.search.content.left.tree column repo -width 100
.nb.search.content.left.tree column name -width 200
.nb.search.content.left.tree column version -width 150

pack .nb.search.content.left.scroll -side right -fill y
pack .nb.search.content.left.tree -side left -fill both -expand 1

# Package details (right side)
ttk::frame .nb.search.content.right
pack .nb.search.content.right -side right -fill both -expand 0 -ipadx 5

label .nb.search.content.right.label -text "Package Details" \
    -background $::theme(base) -foreground $::theme(sapphire) \
    -font {TkDefaultFont 11 bold}
pack .nb.search.content.right.label -anchor w -pady {0 5}

text .nb.search.content.right.text -width 50 -height 30 -wrap word -yscrollcommand {.nb.search.content.right.scroll set} -state disabled
ttk::scrollbar .nb.search.content.right.scroll -orient vertical -command {.nb.search.content.right.text yview}

pack .nb.search.content.right.scroll -side right -fill y
pack .nb.search.content.right.text -side left -fill both -expand 1

# Bind selection to show details
bind .nb.search.content.left.tree <<TreeviewSelect>> {show_package_details search}

# ===== INSTALLED TAB =====
ttk::frame .nb.installed
.nb add .nb.installed -text "Installed"

# Header
ttk::frame .nb.installed.top
pack .nb.installed.top -fill x -padx 10 -pady 10

ttk::label .nb.installed.top.label -text "Installed packages:"
pack .nb.installed.top.label -side left -padx {0 10}

shadow_button .nb.installed.top.refresh -text "Refresh" -command load_installed \
    -bg $::theme(lavender) -fg $::theme(base) \
    -activebackground $::theme(sapphire) -activeforeground $::theme(base) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.installed.top.refresh -side left

ttk::label .nb.installed.top.count -text ""
pack .nb.installed.top.count -side left -padx {10 0}

# Search field for installed packages
ttk::frame .nb.installed.search
pack .nb.installed.search -fill x -padx 10 -pady {0 10}

ttk::label .nb.installed.search.label -text "Filter:"
pack .nb.installed.search.label -side left -padx {0 5}

ttk::entry .nb.installed.search.entry -width 40
pack .nb.installed.search.entry -side left -fill x -expand 1

# Main content area with table and details
ttk::frame .nb.installed.content
pack .nb.installed.content -fill both -expand 1 -padx 10 -pady {0 10}

# Installed packages table (left side)
ttk::frame .nb.installed.content.left
pack .nb.installed.content.left -side left -fill both -expand 1 -padx {0 5}

ttk::treeview .nb.installed.content.left.tree -columns {name version} -show {headings} -yscrollcommand {.nb.installed.content.left.scroll set}
ttk::scrollbar .nb.installed.content.left.scroll -orient vertical -command {.nb.installed.content.left.tree yview}

.nb.installed.content.left.tree heading name -text "Package"
.nb.installed.content.left.tree heading version -text "Version"

.nb.installed.content.left.tree column name -width 300
.nb.installed.content.left.tree column version -width 200

pack .nb.installed.content.left.scroll -side right -fill y
pack .nb.installed.content.left.tree -side left -fill both -expand 1

# Package details (right side)
ttk::frame .nb.installed.content.right
pack .nb.installed.content.right -side right -fill both -expand 0 -ipadx 5

label .nb.installed.content.right.label -text "Package Details" \
    -background $::theme(base) -foreground $::theme(sapphire) \
    -font {TkDefaultFont 11 bold}
pack .nb.installed.content.right.label -anchor w -pady {0 5}

text .nb.installed.content.right.text -width 50 -height 30 -wrap word -yscrollcommand {.nb.installed.content.right.scroll set} -state disabled
ttk::scrollbar .nb.installed.content.right.scroll -orient vertical -command {.nb.installed.content.right.text yview}

pack .nb.installed.content.right.scroll -side right -fill y
pack .nb.installed.content.right.text -side left -fill both -expand 1

# Bind selection to show details
bind .nb.installed.content.left.tree <<TreeviewSelect>> {show_package_details installed}

# ===== UPDATES TAB =====
ttk::frame .nb.updates
.nb add .nb.updates -text "Updates"

# Updates tab header
ttk::frame .nb.updates.top
pack .nb.updates.top -fill x -padx 10 -pady 10

ttk::label .nb.updates.top.label -text "Available package updates:"
pack .nb.updates.top.label -side left -padx {0 10}

shadow_button .nb.updates.top.refresh -text "Refresh" -command load_updates \
    -bg $::theme(lavender) -fg $::theme(base) \
    -activebackground $::theme(sapphire) -activeforeground $::theme(base) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.updates.top.refresh -side left

ttk::label .nb.updates.top.count -text ""
pack .nb.updates.top.count -side left -padx {10 0}

# Search field for updates
ttk::frame .nb.updates.search
pack .nb.updates.search -fill x -padx 10 -pady {0 10}

ttk::label .nb.updates.search.label -text "Filter:"
pack .nb.updates.search.label -side left -padx {0 5}

ttk::entry .nb.updates.search.entry -width 40
pack .nb.updates.search.entry -side left -fill x -expand 1

# Main content area with table and details
ttk::frame .nb.updates.content
pack .nb.updates.content -fill both -expand 1 -padx 10 -pady {0 10}

# Updates table (left side)
ttk::frame .nb.updates.content.left
pack .nb.updates.content.left -side left -fill both -expand 1 -padx {0 5}

ttk::treeview .nb.updates.content.left.tree -columns {package current new} -show {headings} -yscrollcommand {.nb.updates.content.left.scroll set}
ttk::scrollbar .nb.updates.content.left.scroll -orient vertical -command {.nb.updates.content.left.tree yview}

.nb.updates.content.left.tree heading package -text "Package"
.nb.updates.content.left.tree heading current -text "Current Version"
.nb.updates.content.left.tree heading new -text "New Version"

.nb.updates.content.left.tree column package -width 200
.nb.updates.content.left.tree column current -width 150
.nb.updates.content.left.tree column new -width 150

pack .nb.updates.content.left.scroll -side right -fill y
pack .nb.updates.content.left.tree -side left -fill both -expand 1

# Package details (right side)
ttk::frame .nb.updates.content.right
pack .nb.updates.content.right -side right -fill both -expand 0 -ipadx 5

label .nb.updates.content.right.label -text "Package Details" \
    -background $::theme(base) -foreground $::theme(sapphire) \
    -font {TkDefaultFont 11 bold}
pack .nb.updates.content.right.label -anchor w -pady {0 5}

text .nb.updates.content.right.text -width 50 -height 20 -wrap word -yscrollcommand {.nb.updates.content.right.scroll set} -state disabled
ttk::scrollbar .nb.updates.content.right.scroll -orient vertical -command {.nb.updates.content.right.text yview}

pack .nb.updates.content.right.scroll -side right -fill y
pack .nb.updates.content.right.text -side left -fill both -expand 1

# Bind selection to show details
bind .nb.updates.content.left.tree <<TreeviewSelect>> {show_package_details updates}

# Output console for update process
ttk::frame .nb.updates.console
pack .nb.updates.console -fill both -expand 0 -padx 10 -pady {0 10}

label .nb.updates.console.label -text "Update Output:" \
    -background $::theme(base) -foreground $::theme(peach) \
    -font {TkDefaultFont 11 bold}
pack .nb.updates.console.label -anchor w

text .nb.updates.console.text -height 15 -wrap word -yscrollcommand {.nb.updates.console.scroll set} -state disabled
ttk::scrollbar .nb.updates.console.scroll -orient vertical -command {.nb.updates.console.text yview}

pack .nb.updates.console.scroll -side right -fill y
pack .nb.updates.console.text -side left -fill both -expand 1

# Bottom buttons
ttk::frame .nb.updates.bottom
pack .nb.updates.bottom -fill x -padx 10 -pady {0 10}

shadow_button .nb.updates.bottom.update -text "Update All Packages" -command run_update \
    -bg $::theme(peach) -fg $::theme(base) \
    -activebackground $::theme(red) -activeforeground $::theme(base) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.updates.bottom.update -side left -padx {0 10}

ttk::label .nb.updates.bottom.status -text ""
pack .nb.updates.bottom.status -side left -padx {10 0}

# ===== SHARED FUNCTIONS =====

# Debounce timers
set ::search_timer ""
set ::installed_search_timer ""
set ::updates_search_timer ""

# Store all packages for filtering
set ::all_installed_packages {}
set ::all_updates {}

# Debounced search trigger
proc trigger_search {} {
    global search_timer
    if {$search_timer ne ""} {
        after cancel $search_timer
    }
    set search_timer [after 500 search_packages]
}

# Search function
proc search_packages {} {
    global search_timer
    set search_timer ""

    set query [.nb.search.top.entry get]
    if {$query eq ""} {
        .nb.search.content.left.tree delete [.nb.search.content.left.tree children {}]
        return
    }

    .nb.search.content.left.tree delete [.nb.search.content.left.tree children {}]

    if {[catch {exec pacman -Ss $query} output]} {
        return
    }

    set lines [split $output "\n"]
    set i 0
    while {$i < [llength $lines]} {
        set line [lindex $lines $i]

        if {[regexp {^([^/]+)/(\S+)\s+(.+)$} $line match repo name version]} {
            .nb.search.content.left.tree insert {} end -values [list $repo $name $version]
        }

        incr i
    }
}

# Install selected package
proc install_selected_package {} {
    set selection [.nb.search.content.left.tree selection]
    if {[llength $selection] == 0} {
        return
    }

    set item [lindex $selection 0]
    set values [.nb.search.content.left.tree item $item -values]
    set package [lindex $values 1]

    # Run installation in terminal or show output
    console_append "=== Installing $package ===\n"
    console_append "Running: pkexec pacman -S --noconfirm $package\n\n"

    if {[catch {exec setsid -w pkexec pacman -S --noconfirm $package 2>@1} output]} {
        console_append "Error: $output\n"
    } else {
        console_append $output
        console_append "\n=== Installation completed ===\n"
    }
}

# Open URL in browser
proc open_url {url} {
    catch {exec xdg-open $url &}
}

# Tag URLs in text widget
proc tag_urls {text_widget} {
    global theme

    # Configure URL tag appearance
    $text_widget tag configure url -foreground $theme(sapphire) -underline 1
    $text_widget tag bind url <Enter> "$text_widget configure -cursor hand2"
    $text_widget tag bind url <Leave> "$text_widget configure -cursor xterm"

    # Remove existing url tags
    $text_widget tag remove url 1.0 end

    # Find and tag URLs using text widget search
    set pattern {https?://[^\s]+}
    set start 1.0

    while {1} {
        # Search for URL pattern
        set pos [$text_widget search -regexp $pattern $start end]
        if {$pos eq ""} {
            break
        }

        # Get text from found position to end to extract the full URL
        set remaining [$text_widget get $pos end]
        if {[regexp $pattern $remaining url]} {
            set url_length [string length $url]
            set end_pos [$text_widget index "$pos + $url_length chars"]

            # Apply tag
            $text_widget tag add url $pos $end_pos

            # Bind click event for this specific range
            set tag_name "url_[string map {. _} $pos]"
            $text_widget tag add $tag_name $pos $end_pos
            $text_widget tag bind $tag_name <Button-1> [list open_url $url]

            # Continue searching from the end of this URL
            set start $end_pos
        } else {
            break
        }
    }
}

# Show package details
proc show_package_details {tab} {
    if {$tab eq "search"} {
        set tree .nb.search.content.left.tree
        set text .nb.search.content.right.text
        set use_repo_info 1
    } elseif {$tab eq "installed"} {
        set tree .nb.installed.content.left.tree
        set text .nb.installed.content.right.text
        set use_repo_info 0
    } else {
        set tree .nb.updates.content.left.tree
        set text .nb.updates.content.right.text
        set use_repo_info 0
    }

    set selection [$tree selection]
    if {[llength $selection] == 0} {
        return
    }

    set item [lindex $selection 0]
    set values [$tree item $item -values]

    if {$tab eq "search"} {
        set package [lindex $values 1]
    } else {
        set package [lindex $values 0]
    }

    # Get package info
    if {$use_repo_info} {
        set cmd "pacman -Si $package"
    } else {
        set cmd "pacman -Qi $package"
    }

    if {[catch {exec {*}$cmd} output]} {
        set output "Error: Could not retrieve package information"
    }

    $text configure -state normal
    $text delete 1.0 end
    $text insert end $output

    # Tag and make URLs clickable
    tag_urls $text

    $text configure -state disabled
}

# Filter installed packages
proc filter_installed_packages {} {
    global all_installed_packages

    set query [string tolower [.nb.installed.search.entry get]]

    .nb.installed.content.left.tree delete [.nb.installed.content.left.tree children {}]

    set count 0
    foreach pkg $all_installed_packages {
        set name [lindex $pkg 0]
        set version [lindex $pkg 1]

        if {$query eq "" || [string first $query [string tolower $name]] != -1} {
            .nb.installed.content.left.tree insert {} end -values [list $name $version]
            incr count
        }
    }

    if {$query eq ""} {
        .nb.installed.top.count configure -text "$count package(s) installed"
    } else {
        set total [llength $all_installed_packages]
        .nb.installed.top.count configure -text "$count of $total package(s) shown"
    }
}

# Debounced installed search trigger
proc trigger_installed_search {} {
    global installed_search_timer
    if {$installed_search_timer ne ""} {
        after cancel $installed_search_timer
    }
    set installed_search_timer [after 300 filter_installed_packages]
}

# Load installed packages
proc load_installed {} {
    global all_installed_packages

    .nb.installed.content.left.tree delete [.nb.installed.content.left.tree children {}]
    .nb.installed.top.count configure -text "Loading..."
    .nb.installed.top.refresh configure -state disabled

    update idletasks

    after 100 [list load_installed_async]
}

proc load_installed_async {} {
    global all_installed_packages

    if {[catch {exec pacman -Q} output]} {
        .nb.installed.top.count configure -text "Error loading packages"
        .nb.installed.top.refresh configure -state normal
        return
    }

    set lines [split $output "\n"]
    set all_installed_packages {}

    foreach line $lines {
        if {$line eq ""} continue

        if {[regexp {^(\S+)\s+(\S+)} $line match name version]} {
            lappend all_installed_packages [list $name $version]
        }
    }

    .nb.installed.top.refresh configure -state normal

    # Apply current filter
    filter_installed_packages
}

# Filter updates
proc filter_updates {} {
    global all_updates

    set query [string tolower [.nb.updates.search.entry get]]

    .nb.updates.content.left.tree delete [.nb.updates.content.left.tree children {}]

    set count 0
    foreach upd $all_updates {
        set package [lindex $upd 0]
        set current [lindex $upd 1]
        set new [lindex $upd 2]

        if {$query eq "" || [string first $query [string tolower $package]] != -1} {
            .nb.updates.content.left.tree insert {} end -values [list $package $current $new]
            incr count
        }
    }

    if {$query eq ""} {
        .nb.updates.top.count configure -text "$count update(s) available"
    } else {
        set total [llength $all_updates]
        .nb.updates.top.count configure -text "$count of $total update(s) shown"
    }
}

# Debounced updates search trigger
proc trigger_updates_search {} {
    global updates_search_timer
    if {$updates_search_timer ne ""} {
        after cancel $updates_search_timer
    }
    set updates_search_timer [after 300 filter_updates]
}

# Load updates function
proc load_updates {} {
    global all_updates

    .nb.updates.content.left.tree delete [.nb.updates.content.left.tree children {}]
    .nb.updates.top.count configure -text "Checking for updates..."
    .nb.updates.top.refresh configure -state disabled

    update idletasks

    console_append "=== Checking for updates ===\n"
    console_append "Running: pacman -Qu\n\n"

    after 100 [list load_updates_async]
}

proc load_updates_async {} {
    global all_updates

    if {[catch {exec pacman -Qu} output]} {
        set all_updates {}
        .nb.updates.top.count configure -text "No updates available"
        .nb.updates.top.refresh configure -state normal
        console_append "No updates available.\n\n"
        filter_updates
        return
    }

    set lines [split $output "\n"]
    set all_updates {}

    foreach line $lines {
        if {$line eq ""} continue

        if {[regexp {^(\S+)\s+(\S+)\s+->\s+(\S+)} $line match package current new]} {
            lappend all_updates [list $package $current $new]
        }
    }

    .nb.updates.top.refresh configure -state normal
    console_append "Found [llength $all_updates] update(s) available.\n\n"

    # Apply current filter
    filter_updates
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
        if {[catch {close $update_channel} err]} {
            console_append "\n=== Update process finished with errors ===\n"
            console_append "Error: $err\n"
            .nb.updates.bottom.status configure -text "Update failed!"
        } else {
            console_append "\n=== Update process completed successfully ===\n"
            .nb.updates.bottom.status configure -text "Update completed!"
        }

        set update_channel ""
        .nb.updates.bottom.update configure -state normal

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

    if {$update_channel ne ""} {
        return
    }

    console_clear
    console_append "=== Starting system update ===\n"
    console_append "Running: pkexec pacman -Syu --noconfirm\n\n"

    .nb.updates.bottom.update configure -state disabled
    .nb.updates.bottom.status configure -text "Updating..."

    if {[catch {open "|setsid -w stdbuf -oL -eL pkexec pacman -Syu --noconfirm --color=never 2>&1" r} update_channel]} {
        console_append "Error starting update: $update_channel\n"
        set update_channel ""
        .nb.updates.bottom.update configure -state normal
        .nb.updates.bottom.status configure -text "Update failed!"
        return
    }

    fconfigure $update_channel -blocking 0 -buffering none
    fileevent $update_channel readable read_update_output
}

# Bind Enter key and key release for debounced search
bind .nb.search.top.entry <Return> search_packages
bind .nb.search.top.entry <KeyRelease> trigger_search

# Bind key release for installed packages filter
bind .nb.installed.search.entry <KeyRelease> trigger_installed_search

# Bind key release for updates filter
bind .nb.updates.search.entry <KeyRelease> trigger_updates_search

# Load initial data
load_updates
load_installed

# Start theme watcher (uses inotify for instant updates)
start_theme_watcher "theme"
