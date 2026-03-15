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
    -bg $::theme(sapphire) -fg $::theme(text) \
    -activebackground $::theme(teal) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.search.top.button -side left -padx {0 5}

shadow_button .nb.search.top.install -text "Install Selected" -command install_selected_package \
    -bg $::theme(green) -fg $::theme(text) \
    -activebackground $::theme(teal) -activeforeground $::theme(text) \
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
    -bg $::theme(lavender) -fg $::theme(text) \
    -activebackground $::theme(sapphire) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.installed.top.refresh -side left -padx {0 5}

shadow_button .nb.installed.top.uninstall -text "Uninstall Selected" -command uninstall_selected_package \
    -bg $::theme(red) -fg $::theme(text) \
    -activebackground $::theme(mauve) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.installed.top.uninstall -side left

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

# Output console for uninstall process
ttk::frame .nb.installed.console
pack .nb.installed.console -fill both -expand 0 -padx 10 -pady {0 10}

label .nb.installed.console.label -text "Uninstall Output:" \
    -background $::theme(base) -foreground $::theme(red) \
    -font {TkDefaultFont 11 bold}
pack .nb.installed.console.label -anchor w

text .nb.installed.console.text -height 8 -wrap word -yscrollcommand {.nb.installed.console.scroll set} -state disabled
ttk::scrollbar .nb.installed.console.scroll -orient vertical -command {.nb.installed.console.text yview}

pack .nb.installed.console.scroll -side right -fill y
pack .nb.installed.console.text -side left -fill both -expand 1

# ===== UPDATES TAB =====
ttk::frame .nb.updates
.nb add .nb.updates -text "Updates"

# Updates tab header
ttk::frame .nb.updates.top
pack .nb.updates.top -fill x -padx 10 -pady 10

ttk::label .nb.updates.top.label -text "Available package updates:"
pack .nb.updates.top.label -side left -padx {0 10}

shadow_button .nb.updates.top.refresh -text "Refresh" -command load_updates \
    -bg $::theme(lavender) -fg $::theme(text) \
    -activebackground $::theme(sapphire) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.updates.top.refresh -side left -padx {0 5}

shadow_button .nb.updates.top.updateall -text "Update All" -command run_update \
    -bg $::theme(peach) -fg $::theme(text) \
    -activebackground $::theme(red) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.updates.top.updateall -side left

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
    -bg $::theme(peach) -fg $::theme(text) \
    -activebackground $::theme(red) -activeforeground $::theme(text) \
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

# Append text to installed console
proc installed_console_append {text} {
    .nb.installed.console.text configure -state normal
    .nb.installed.console.text insert end $text
    .nb.installed.console.text see end
    .nb.installed.console.text configure -state disabled
}

# Clear installed console
proc installed_console_clear {} {
    .nb.installed.console.text configure -state normal
    .nb.installed.console.text delete 1.0 end
    .nb.installed.console.text configure -state disabled
}

# Uninstall selected package
proc uninstall_selected_package {} {
    set selection [.nb.installed.content.left.tree selection]
    if {[llength $selection] == 0} {
        return
    }

    set item [lindex $selection 0]
    set values [.nb.installed.content.left.tree item $item -values]
    set package [lindex $values 0]

    installed_console_clear
    installed_console_append "=== Uninstalling $package ===\n"
    installed_console_append "Running: pkexec pacman -R --noconfirm $package\n\n"

    .nb.installed.top.uninstall configure -state disabled
    .nb.installed.top.refresh configure -state disabled

    if {[catch {exec setsid -w pkexec pacman -R --noconfirm $package 2>@1} output]} {
        installed_console_append "Error: $output\n"
        installed_console_append "\n=== Uninstall failed ===\n"
    } else {
        installed_console_append $output
        installed_console_append "\n=== Uninstall completed ===\n"
        # Refresh installed list after successful removal
        after 500 load_installed
    }

    .nb.installed.top.uninstall configure -state normal
    .nb.installed.top.refresh configure -state normal
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
proc load_updates {{sync 1}} {
    global all_updates

    .nb.updates.content.left.tree delete [.nb.updates.content.left.tree children {}]
    .nb.updates.top.count configure -text "Checking for updates..."
    .nb.updates.top.refresh configure -state disabled

    update idletasks

    console_append "=== Checking for updates ===\n"

    after 100 [list load_updates_async $sync]
}

proc load_updates_async {{sync 1}} {
    global all_updates

    # Prefer checkupdates (pacman-contrib) - runs without root and syncs a temp DB
    # Fall back to pkexec pacman -Sy then pacman -Qu if checkupdates is not available
    set use_checkupdates [expr {![catch {exec which checkupdates}]}]

    set output ""
    set exit_ok 1

    if {$use_checkupdates} {
        console_append "Running: checkupdates\n\n"
        if {[catch {exec checkupdates} result]} {
            # checkupdates exits 2 when no updates - that is not an error
            set output $result
        } else {
            set output $result
        }
    } else {
        if {$sync} {
            # Sync the package DB first (required to detect updates), then query
            console_append "Running: pkexec pacman -Sy\n"
            if {[catch {exec pkexec pacman -Sy 2>@1} sync_out]} {
                console_append "Warning: DB sync failed: $sync_out\n\n"
            } else {
                console_append $sync_out
                console_append "\n"
            }
        }
        console_append "Running: pacman -Qu\n\n"
        if {[catch {exec pacman -Qu} result]} {
            set output $result
            if {$output eq ""} {
                set exit_ok 0
            }
        } else {
            set output $result
        }
    }

    if {!$exit_ok} {
        set all_updates {}
        .nb.updates.top.count configure -text "Error checking updates"
        .nb.updates.top.refresh configure -state normal
        console_append "Error: could not check for updates.\n\n"
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

    if {[llength $all_updates] == 0} {
        .nb.updates.top.count configure -text "No updates available"
        console_append "No updates available.\n\n"
    } else {
        console_append "Found [llength $all_updates] update(s) available.\n\n"
    }

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
        .nb.updates.top.updateall configure -state normal

        after 1000 [list load_updates 0]
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
    .nb.updates.top.updateall configure -state disabled
    .nb.updates.bottom.status configure -text "Updating..."

    if {[catch {open "|setsid -w stdbuf -oL -eL pkexec pacman -Syu --noconfirm --color=never 2>&1" r} update_channel]} {
        console_append "Error starting update: $update_channel\n"
        set update_channel ""
        .nb.updates.bottom.update configure -state normal
        .nb.updates.top.updateall configure -state normal
        .nb.updates.bottom.status configure -text "Update failed!"
        return
    }

    fconfigure $update_channel -blocking 0 -buffering none
    fileevent $update_channel readable read_update_output
}

# ===== FLATPAKS TAB =====
ttk::frame .nb.flatpaks
.nb add .nb.flatpaks -text "Flatpaks"

# Header bar
ttk::frame .nb.flatpaks.top
pack .nb.flatpaks.top -fill x -padx 10 -pady 10

ttk::label .nb.flatpaks.top.label -text "Installed Flatpaks:"
pack .nb.flatpaks.top.label -side left -padx {0 10}

shadow_button .nb.flatpaks.top.refresh -text "Refresh" -command load_flatpaks \
    -bg $::theme(lavender) -fg $::theme(text) \
    -activebackground $::theme(sapphire) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.flatpaks.top.refresh -side left -padx {0 5}

ttk::label .nb.flatpaks.top.count -text ""
pack .nb.flatpaks.top.count -side left -padx {5 0}

# Filter bar
ttk::frame .nb.flatpaks.filter
pack .nb.flatpaks.filter -fill x -padx 10 -pady {0 6}

ttk::label .nb.flatpaks.filter.label -text "Filter:"
pack .nb.flatpaks.filter.label -side left -padx {0 5}

ttk::entry .nb.flatpaks.filter.entry -width 40
pack .nb.flatpaks.filter.entry -side left -fill x -expand 1

# Bottom section: search + results + console — packed FIRST so it's always visible
ttk::frame .nb.flatpaks.bottom
pack .nb.flatpaks.bottom -side bottom -fill x -padx 10 -pady {0 10}

# Search Flathub bar
ttk::frame .nb.flatpaks.bottom.searchbar
pack .nb.flatpaks.bottom.searchbar -fill x -pady {4 0}

label .nb.flatpaks.bottom.searchbar.label -text "Search Flathub:" \
    -bg $::theme(base) -fg $::theme(sapphire) -font {TkDefaultFont 10 bold}
pack .nb.flatpaks.bottom.searchbar.label -side left -padx {0 8}

ttk::entry .nb.flatpaks.bottom.searchbar.entry -width 36
pack .nb.flatpaks.bottom.searchbar.entry -side left -fill x -expand 1 -padx {0 5}

shadow_button .nb.flatpaks.bottom.searchbar.btn -text "Search" \
    -command search_flatpaks \
    -bg $::theme(sapphire) -fg $::theme(text) \
    -activebackground $::theme(teal) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.flatpaks.bottom.searchbar.btn -side left -padx {0 5}

shadow_button .nb.flatpaks.bottom.searchbar.install -text "Install Selected" \
    -command flatpak_install_selected \
    -bg $::theme(green) -fg $::theme(text) \
    -activebackground $::theme(teal) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 12 -pady 6 -cursor hand2
pack .nb.flatpaks.bottom.searchbar.install -side left

# Search results treeview
ttk::frame .nb.flatpaks.bottom.searchresults
pack .nb.flatpaks.bottom.searchresults -fill x -pady {2 4}

ttk::treeview .nb.flatpaks.bottom.searchresults.tree \
    -columns {name appid version description} -show headings \
    -height 5 \
    -yscrollcommand {.nb.flatpaks.bottom.searchresults.scroll set}
ttk::scrollbar .nb.flatpaks.bottom.searchresults.scroll \
    -orient vertical -command {.nb.flatpaks.bottom.searchresults.tree yview}

.nb.flatpaks.bottom.searchresults.tree heading name        -text "Name"
.nb.flatpaks.bottom.searchresults.tree heading appid       -text "App ID"
.nb.flatpaks.bottom.searchresults.tree heading version     -text "Version"
.nb.flatpaks.bottom.searchresults.tree heading description -text "Description"

.nb.flatpaks.bottom.searchresults.tree column name        -width 160
.nb.flatpaks.bottom.searchresults.tree column appid       -width 220
.nb.flatpaks.bottom.searchresults.tree column version     -width 80
.nb.flatpaks.bottom.searchresults.tree column description -width 340

pack .nb.flatpaks.bottom.searchresults.scroll -side right -fill y
pack .nb.flatpaks.bottom.searchresults.tree   -side left  -fill x -expand 1

# Console output
ttk::frame .nb.flatpaks.bottom.console
pack .nb.flatpaks.bottom.console -fill x -pady {0 4}

label .nb.flatpaks.bottom.console.label -text "Output:" \
    -bg $::theme(base) -fg $::theme(peach) -font {TkDefaultFont 11 bold}
pack .nb.flatpaks.bottom.console.label -anchor w

text .nb.flatpaks.bottom.console.text \
    -height 5 -wrap word \
    -yscrollcommand {.nb.flatpaks.bottom.console.scroll set} -state disabled
ttk::scrollbar .nb.flatpaks.bottom.console.scroll \
    -orient vertical -command {.nb.flatpaks.bottom.console.text yview}

pack .nb.flatpaks.bottom.console.scroll -side right -fill y
pack .nb.flatpaks.bottom.console.text   -side left  -fill both -expand 1

# Main content: icon grid (left) + detail panel (right) — expands to fill remaining space
ttk::frame .nb.flatpaks.content
pack .nb.flatpaks.content -fill both -expand 1 -padx 10 -pady {0 6}

# Left: scrollable icon grid
ttk::frame .nb.flatpaks.content.gridframe
pack .nb.flatpaks.content.gridframe -side left -fill both -expand 1 -padx {0 5}

canvas .nb.flatpaks.content.gridframe.canvas \
    -bg $::theme(base) -highlightthickness 0 \
    -yscrollcommand {.nb.flatpaks.content.gridframe.scroll set}
ttk::scrollbar .nb.flatpaks.content.gridframe.scroll \
    -orient vertical -command {.nb.flatpaks.content.gridframe.canvas yview}

pack .nb.flatpaks.content.gridframe.scroll -side right -fill y
pack .nb.flatpaks.content.gridframe.canvas -side left -fill both -expand 1

# Inner frame inside canvas for the grid cards
frame .nb.flatpaks.content.gridframe.canvas.inner -bg $::theme(base)
.nb.flatpaks.content.gridframe.canvas create window 0 0 \
    -anchor nw -window .nb.flatpaks.content.gridframe.canvas.inner \
    -tags inner_window

bind .nb.flatpaks.content.gridframe.canvas.inner <Configure> {
    .nb.flatpaks.content.gridframe.canvas configure \
        -scrollregion [.nb.flatpaks.content.gridframe.canvas bbox all]
}
bind .nb.flatpaks.content.gridframe.canvas <Button-4> {
    .nb.flatpaks.content.gridframe.canvas yview scroll -3 units
}
bind .nb.flatpaks.content.gridframe.canvas <Button-5> {
    .nb.flatpaks.content.gridframe.canvas yview scroll 3 units
}

# Right: detail panel
ttk::frame .nb.flatpaks.content.detail
pack .nb.flatpaks.content.detail -side right -fill y -padx {5 0}

# App icon (large)
label .nb.flatpaks.content.detail.icon \
    -bg $::theme(surface0) -relief flat \
    -width 96 -height 96
pack .nb.flatpaks.content.detail.icon -pady {4 8}

# App name
label .nb.flatpaks.content.detail.name \
    -text "" -bg $::theme(base) -fg $::theme(text) \
    -font {TkDefaultFont 13 bold} -wraplength 220 -justify center
pack .nb.flatpaks.content.detail.name -fill x -padx 4

# App ID
label .nb.flatpaks.content.detail.appid \
    -text "" -bg $::theme(base) -fg $::theme(subtext0) \
    -font {TkDefaultFont 9} -wraplength 220 -justify center
pack .nb.flatpaks.content.detail.appid -fill x -padx 4

# Version
label .nb.flatpaks.content.detail.version \
    -text "" -bg $::theme(base) -fg $::theme(overlay0) \
    -font {TkDefaultFont 9}
pack .nb.flatpaks.content.detail.version -pady {2 10}

# Running status label
label .nb.flatpaks.content.detail.running \
    -text "" -bg $::theme(base) -fg $::theme(green) \
    -font {TkDefaultFont 9 bold}
pack .nb.flatpaks.content.detail.running -pady {0 8}

# Action buttons
shadow_button .nb.flatpaks.content.detail.run -text "Run" \
    -command flatpak_run_selected \
    -bg $::theme(green) -fg $::theme(text) \
    -activebackground $::theme(teal) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 16 -pady 6 -cursor hand2
pack .nb.flatpaks.content.detail.run -fill x -padx 8 -pady 2

shadow_button .nb.flatpaks.content.detail.kill -text "Kill" \
    -command flatpak_kill_selected \
    -bg $::theme(red) -fg $::theme(text) \
    -activebackground $::theme(mauve) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 16 -pady 6 -cursor hand2
# Kill button is packed/unpacked dynamically based on running state

shadow_button .nb.flatpaks.content.detail.uninstall -text "Uninstall" \
    -command flatpak_uninstall_selected \
    -bg $::theme(surface1) -fg $::theme(text) \
    -activebackground $::theme(red) -activeforeground $::theme(text) \
    -relief raised -borderwidth 2 -padx 16 -pady 6 -cursor hand2
pack .nb.flatpaks.content.detail.uninstall -fill x -padx 8 -pady 2

# ===== FLATPAKS STATE =====
set ::all_flatpaks         {}
set ::flatpak_running      {}
set ::selected_flatpak     ""
array set ::flatpak_icons  {}
set ::flatpak_search_timer ""
set ::flatpak_placeholder  ""

# ===== FLATPAK PROCS =====

proc flatpak_console_append {text} {
    .nb.flatpaks.bottom.console.text configure -state normal
    .nb.flatpaks.bottom.console.text insert end $text
    .nb.flatpaks.bottom.console.text see end
    .nb.flatpaks.bottom.console.text configure -state disabled
}

proc flatpak_console_clear {} {
    .nb.flatpaks.bottom.console.text configure -state normal
    .nb.flatpaks.bottom.console.text delete 1.0 end
    .nb.flatpaks.bottom.console.text configure -state disabled
}

# Return a cached photo image for an appid at the given size.
# Falls back to a solid placeholder square.
proc get_flatpak_icon {appid {size 48}} {
    global flatpak_icons flatpak_placeholder

    set key "${appid}_${size}"
    if {[info exists flatpak_icons($key)]} {
        return $flatpak_icons($key)
    }

    set candidates [list \
        "/var/lib/flatpak/appstream/flathub/x86_64/active/icons/128x128/${appid}.png" \
        "/var/lib/flatpak/exports/share/icons/hicolor/128x128/apps/${appid}.png" \
        "/var/lib/flatpak/appstream/flathub/x86_64/active/icons/64x64/${appid}.png" \
        "/var/lib/flatpak/exports/share/icons/hicolor/64x64/apps/${appid}.png" \
    ]

    set icon_path ""
    foreach c $candidates {
        if {[file exists $c]} { set icon_path $c; break }
    }

    if {$icon_path eq ""} {
        if {$flatpak_placeholder eq ""} {
            set flatpak_placeholder [image create photo flatpak_ph \
                -width $size -height $size]
            flatpak_ph put $::theme(surface1) -to 0 0 $size $size
        }
        set flatpak_icons($key) $flatpak_placeholder
        return $flatpak_placeholder
    }

    set orig_name  "fk_orig_[string map {. _ - _} $appid]_${size}"
    set final_name "fk_img_[string map {. _ - _} $appid]_${size}"

    if {[catch {image create photo $orig_name -file $icon_path} err]} {
        set flatpak_icons($key) $flatpak_placeholder
        return $flatpak_placeholder
    }

    set ow [image width  $orig_name]
    set oh [image height $orig_name]
    set sw [expr {max(1, int(ceil(double($ow) / $size)))}]
    set sh [expr {max(1, int(ceil(double($oh) / $size)))}]
    set s  [expr {$sw > $sh ? $sw : $sh}]

    image create photo $final_name
    $final_name copy $orig_name -subsample $s $s
    image delete $orig_name

    set flatpak_icons($key) $final_name
    return $final_name
}

# Build (or rebuild) the icon grid from ::all_flatpaks
proc build_flatpak_grid {} {
    global all_flatpaks flatpak_running selected_flatpak

    set inner .nb.flatpaks.content.gridframe.canvas.inner
    foreach w [winfo children $inner] { destroy $w }

    set card_w  90
    set card_h  90
    set pad      8
    set cols     6

    set i 0
    foreach entry $all_flatpaks {
        set name  [lindex $entry 0]
        set appid [lindex $entry 1]
        set ver   [lindex $entry 2]

        set col [expr {$i % $cols}]
        set row [expr {$i / $cols}]
        set x   [expr {$col * ($card_w + $pad) + $pad}]
        set y   [expr {$row * ($card_h + $pad) + $pad}]

        set is_selected [expr {$appid eq $selected_flatpak}]
        set card_bg [expr {$is_selected ? $::theme(selected_bg) : $::theme(surface0)}]

        set card_id "card_[string map {. _ - _} $appid]"
        set card [frame $inner.$card_id \
            -bg $card_bg -relief flat \
            -width $card_w -height $card_h -cursor hand2]
        place $card -x $x -y $y -width $card_w -height $card_h

        # Icon
        set img [get_flatpak_icon $appid 48]
        set icn [label $card.icon -image $img -bg $card_bg -cursor hand2]
        place $icn -relx 0.5 -y 6 -anchor n

        # Name (truncated)
        set short [expr {[string length $name] > 10 ? "[string range $name 0 9]…" : $name}]
        set lbl [label $card.lbl -text $short \
            -bg $card_bg -fg $::theme(text) \
            -font {TkDefaultFont 8} -cursor hand2 \
            -wraplength [expr {$card_w - 4}]]
        place $lbl -relx 0.5 -rely 1.0 -anchor s -y -4

        # Running dot
        if {[lsearch $flatpak_running $appid] >= 0} {
            label $card.dot -text "●" \
                -bg $card_bg -fg $::theme(green) -font {TkDefaultFont 8}
            place $card.dot -x 2 -y 2
        }

        # Click bindings
        foreach w [list $card $icn $lbl] {
            bind $w <Button-1> [list select_flatpak $appid $name $ver]
        }
        catch {bind $card.dot <Button-1> [list select_flatpak $appid $name $ver]}

        incr i
    }

    # Resize inner to content
    set n [llength $all_flatpaks]
    set rows [expr {max(1, int(ceil(double($n) / $cols)))}]
    $inner configure \
        -width  [expr {$cols * ($card_w + $pad) + $pad}] \
        -height [expr {$rows * ($card_h + $pad) + $pad}]

    update idletasks
    .nb.flatpaks.content.gridframe.canvas configure \
        -scrollregion [.nb.flatpaks.content.gridframe.canvas bbox all]
}

# Select a flatpak: highlight card, populate detail panel
proc select_flatpak {appid name ver} {
    global selected_flatpak flatpak_running

    set selected_flatpak $appid
    build_flatpak_grid

    .nb.flatpaks.content.detail.name    configure -text $name
    .nb.flatpaks.content.detail.appid   configure -text $appid
    .nb.flatpaks.content.detail.version configure -text "Version: $ver"

    set img [get_flatpak_icon $appid 96]
    .nb.flatpaks.content.detail.icon configure -image $img -width 0 -height 0

    set running [expr {[lsearch $flatpak_running $appid] >= 0}]
    if {$running} {
        .nb.flatpaks.content.detail.running configure -text "● Running"
        pack .nb.flatpaks.content.detail.kill \
            -fill x -padx 8 -pady 2 \
            -before .nb.flatpaks.content.detail.uninstall
    } else {
        .nb.flatpaks.content.detail.running configure -text ""
        pack forget .nb.flatpaks.content.detail.kill
    }
}

# Poll running flatpaks every 3s and refresh indicators
proc refresh_flatpak_running {} {
    global flatpak_running selected_flatpak

    if {[catch {exec flatpak ps --columns=application} out]} { set out "" }

    set flatpak_running {}
    foreach line [split $out "\n"] {
        set line [string trim $line]
        if {$line ne ""} { lappend flatpak_running $line }
    }

    build_flatpak_grid

    if {$selected_flatpak ne ""} {
        set running [expr {[lsearch $flatpak_running $selected_flatpak] >= 0}]
        if {$running} {
            .nb.flatpaks.content.detail.running configure -text "● Running"
            catch {
                pack .nb.flatpaks.content.detail.kill \
                    -fill x -padx 8 -pady 2 \
                    -before .nb.flatpaks.content.detail.uninstall
            }
        } else {
            .nb.flatpaks.content.detail.running configure -text ""
            pack forget .nb.flatpaks.content.detail.kill
        }
    }

    after 3000 refresh_flatpak_running
}

# Load installed flatpaks (clears icon cache so reinstalls show fresh icons)
proc load_flatpaks {} {
    global flatpak_icons flatpak_placeholder

    .nb.flatpaks.top.refresh configure -state disabled
    .nb.flatpaks.top.count configure -text "Loading..."

    foreach key [array names flatpak_icons] {
        catch {
            if {$flatpak_icons($key) ne $flatpak_placeholder} {
                image delete $flatpak_icons($key)
            }
        }
    }
    array unset flatpak_icons
    set flatpak_placeholder ""

    update idletasks
    after 50 load_flatpaks_async
}

proc load_flatpaks_async {} {
    global all_flatpaks

    if {[catch {exec flatpak list --app --columns=name,application,version} out]} {
        set out ""
    }

    set all_flatpaks {}
    foreach line [split $out "\n"] {
        if {$line eq ""} continue
        set parts [split $line "\t"]
        if {[llength $parts] >= 2} {
            lappend all_flatpaks [list \
                [lindex $parts 0] \
                [lindex $parts 1] \
                [expr {[llength $parts] >= 3 ? [lindex $parts 2] : ""}]]
        }
    }

    .nb.flatpaks.top.refresh configure -state normal
    .nb.flatpaks.top.count configure -text "[llength $all_flatpaks] installed"

    apply_flatpak_filter
}

# Filter the grid by the filter entry
proc apply_flatpak_filter {} {
    global all_flatpaks

    set query [string tolower [.nb.flatpaks.filter.entry get]]
    if {$query eq ""} {
        build_flatpak_grid
        return
    }

    set saved $::all_flatpaks
    set ::all_flatpaks {}
    foreach entry $saved {
        set n [string tolower [lindex $entry 0]]
        set a [string tolower [lindex $entry 1]]
        if {[string first $query $n] >= 0 || [string first $query $a] >= 0} {
            lappend ::all_flatpaks $entry
        }
    }
    build_flatpak_grid
    set ::all_flatpaks $saved
}

proc trigger_flatpak_filter {} {
    global flatpak_search_timer
    if {$flatpak_search_timer ne ""} { after cancel $flatpak_search_timer }
    set flatpak_search_timer [after 300 apply_flatpak_filter]
}

# Run the selected flatpak
proc flatpak_run_selected {} {
    global selected_flatpak
    if {$selected_flatpak eq ""} return
    flatpak_console_append "Launching: $selected_flatpak\n"
    catch {exec setsid flatpak run $selected_flatpak &}
}

# Kill the selected flatpak
proc flatpak_kill_selected {} {
    global selected_flatpak
    if {$selected_flatpak eq ""} return
    flatpak_console_append "Killing: $selected_flatpak\n"
    if {[catch {exec flatpak kill $selected_flatpak} err]} {
        flatpak_console_append "Error: $err\n"
    } else {
        flatpak_console_append "Killed.\n"
    }
    after 500 refresh_flatpak_running
}

# Uninstall the selected flatpak (async)
set ::flatpak_uninstall_channel ""

proc flatpak_uninstall_selected {} {
    global selected_flatpak flatpak_uninstall_channel
    if {$selected_flatpak eq ""} return
    if {$flatpak_uninstall_channel ne ""} return

    set appid $selected_flatpak
    flatpak_console_clear
    flatpak_console_append "=== Uninstalling $appid ===\n"
    flatpak_console_append "Running: pkexec flatpak uninstall -y --system $appid\n\n"

    .nb.flatpaks.content.detail.uninstall configure -state disabled
    .nb.flatpaks.top.refresh configure -state disabled

    if {[catch {open "|stdbuf -oL -eL pkexec flatpak uninstall -y --system $appid 2>&1" r} flatpak_uninstall_channel]} {
        flatpak_console_append "Error starting uninstall: $flatpak_uninstall_channel\n"
        set flatpak_uninstall_channel ""
        .nb.flatpaks.content.detail.uninstall configure -state normal
        .nb.flatpaks.top.refresh configure -state normal
        return
    }

    fconfigure $flatpak_uninstall_channel -blocking 0 -buffering line
    fileevent $flatpak_uninstall_channel readable \
        [list read_flatpak_uninstall_output $appid]
}

proc read_flatpak_uninstall_output {appid} {
    global flatpak_uninstall_channel

    if {[eof $flatpak_uninstall_channel]} {
        if {[catch {close $flatpak_uninstall_channel} err]} {
            flatpak_console_append "\n=== Uninstall failed: $err ===\n"
        } else {
            flatpak_console_append "\n=== Uninstall complete ===\n"
            set ::selected_flatpak ""
            .nb.flatpaks.content.detail.name    configure -text ""
            .nb.flatpaks.content.detail.appid   configure -text ""
            .nb.flatpaks.content.detail.version configure -text ""
            .nb.flatpaks.content.detail.running configure -text ""
            .nb.flatpaks.content.detail.icon    configure -image "" -width 96 -height 96
            pack forget .nb.flatpaks.content.detail.kill
            after 500 load_flatpaks
        }
        set flatpak_uninstall_channel ""
        .nb.flatpaks.content.detail.uninstall configure -state normal
        .nb.flatpaks.top.refresh configure -state normal
        return
    }

    if {[gets $flatpak_uninstall_channel line] >= 0} {
        flatpak_console_append "$line\n"
    }
}

# Search Flathub
proc search_flatpaks {} {
    set query [.nb.flatpaks.bottom.searchbar.entry get]
    if {$query eq ""} return

    .nb.flatpaks.bottom.searchresults.tree delete [.nb.flatpaks.bottom.searchresults.tree children {}]
    flatpak_console_clear
    flatpak_console_append "Searching Flathub for: $query\n"

    if {[catch {exec flatpak search --columns=name,application,version,description $query} out]} {
        flatpak_console_append "No results.\n"
        return
    }

    set count 0
    foreach line [split $out "\n"] {
        if {$line eq ""} continue
        set parts [split $line "\t"]
        if {[llength $parts] >= 2} {
            .nb.flatpaks.bottom.searchresults.tree insert {} end -values [list \
                [lindex $parts 0] \
                [lindex $parts 1] \
                [expr {[llength $parts] >= 3 ? [lindex $parts 2] : ""}] \
                [expr {[llength $parts] >= 4 ? [lindex $parts 3] : ""}]]
            incr count
        }
    }
    flatpak_console_append "Found $count result(s).\n"
}

# Install the selected search result (async)
set ::flatpak_install_channel ""

proc flatpak_install_selected {} {
    global flatpak_install_channel

    if {$flatpak_install_channel ne ""} return

    set sel [.nb.flatpaks.bottom.searchresults.tree selection]
    if {[llength $sel] == 0} return

    set vals  [.nb.flatpaks.bottom.searchresults.tree item [lindex $sel 0] -values]
    set appid [lindex $vals 1]

    flatpak_console_clear
    flatpak_console_append "=== Installing $appid ===\n"
    flatpak_console_append "Running: flatpak install -y --system flathub $appid\n\n"

    .nb.flatpaks.bottom.searchbar.install configure -state disabled

    if {[catch {open "|stdbuf -oL -eL flatpak install -y --system flathub $appid 2>&1" r} flatpak_install_channel]} {
        flatpak_console_append "Error starting install: $flatpak_install_channel\n"
        set flatpak_install_channel ""
        .nb.flatpaks.bottom.searchbar.install configure -state normal
        return
    }

    fconfigure $flatpak_install_channel -blocking 0 -buffering line
    fileevent $flatpak_install_channel readable \
        [list read_flatpak_install_output $appid]
}

proc read_flatpak_install_output {appid} {
    global flatpak_install_channel

    if {[eof $flatpak_install_channel]} {
        if {[catch {close $flatpak_install_channel} err]} {
            flatpak_console_append "\n=== Install failed: $err ===\n"
        } else {
            flatpak_console_append "\n=== Install complete ===\n"
            after 500 load_flatpaks
        }
        set flatpak_install_channel ""
        .nb.flatpaks.bottom.searchbar.install configure -state normal
        return
    }

    if {[gets $flatpak_install_channel line] >= 0} {
        flatpak_console_append "$line\n"
    }
}

# ===== BINDINGS & INIT =====

bind .nb.flatpaks.bottom.searchbar.entry <Return>    search_flatpaks
bind .nb.flatpaks.filter.entry           <KeyRelease> trigger_flatpak_filter

# Bind Enter key and key release for debounced search
bind .nb.search.top.entry <Return> search_packages
bind .nb.search.top.entry <KeyRelease> trigger_search

# Bind key release for installed packages filter
bind .nb.installed.search.entry <KeyRelease> trigger_installed_search

# Bind key release for updates filter
bind .nb.updates.search.entry <KeyRelease> trigger_updates_search

# Load initial data - skip DB sync on startup to avoid password prompt
load_updates 0
load_installed
load_flatpaks

# Start running state refresh timer
after 3000 refresh_flatpak_running

# Start theme watcher (uses inotify for instant updates)
start_theme_watcher "theme"
