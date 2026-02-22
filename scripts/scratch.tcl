#!/usr/bin/env wish

package require Tk

set script_dir [file join $::env(HOME) .alatar/scripts]

source [file join $::env(HOME) .alatar/lib/theme.tcl]
source [file join $script_dir nomicron/ui.tcl]

load_wallust_theme "nomicron"
apply_ttk_theme
configure_root_window

# Returns a list of app IDs for all windows currently in the Sway scratchpad.
# Each element is the app_id (Wayland) or WM_CLASS (X11) of a scratchpad window.
proc get_scratch_apps {} {
    set jq_filter {[.. | objects | select(.name? == "__i3_scratch") | .floating_nodes[] | (.app_id // .window_properties.class // "unknown")] | .[]}
    if {[catch {exec sh -c "swaymsg -t get_tree | jq -r '$jq_filter'"} output]} {
        return {}
    }
    if {$output eq ""} {
        return {}
    }
    return [split $output "\n"]
}

# Returns a list of {con_id title} pairs for each window in the scratchpad.
# con_id uniquely identifies the container and works directly with swaymsg criteria.
proc get_scratch_details {} {
    set jq_filter {[.. | objects | select(.name? == "__i3_scratch") | .floating_nodes[] | [(.id | tostring), (.name // "")]] | .[] | @tsv}
    if {[catch {exec sh -c "swaymsg -t get_tree | jq -r '$jq_filter'"} output]} {
        return {}
    }
    if {$output eq ""} {
        return {}
    }
    set result {}
    foreach line [split $output "\n"] {
        if {$line ne ""} {
            lappend result [split $line "\t"]
        }
    }
    return $result
}

proc reveal_app {con_id} {
    catch {exec sh -c "swaymsg '\[con_id=$con_id\] scratchpad show'"}
    destroy .
}

# --- GUI ---

set apps [get_scratch_details]

if {[llength $apps] == 0} {
    wm withdraw .
    tk_messageBox -title "Scratchpad" -message "No apps in the scratchpad." -type ok
    exit
}

wm title . "Scratchpad"
wm resizable . 0 0
tk appname "com.alatar.scratch"

# Nomicron-style bordered container
frame .c -bg $theme(border) -relief raised -borderwidth 3
pack .c -fill both -expand 1 -padx 8 -pady 8

frame .c.inner -bg $theme(base)
pack .c.inner -fill both -expand 1 -padx 2 -pady 2

label .c.inner.title -text "Scratchpad" \
    -bg $theme(base) -fg $theme(text) \
    -font $::theme_font_heading -pady 10
pack .c.inner.title -fill x

frame .c.inner.sep -bg $theme(border) -height 1
pack .c.inner.sep -fill x -padx 8

frame .c.inner.btns -bg $theme(base)
pack .c.inner.btns -fill both -expand 1 -pady 6

# Accent colors cycled per button
set accent_keys {lavender sapphire teal peach red green mauve accent1 accent2 accent3 accent4}

set i 0
foreach app $apps {
    lassign $app con_id title
    set num [expr {$i + 1}]
    set label [expr {$title ne "" ? "$num  $title" : "$num  con:$con_id"}]
    set color_key [lindex $accent_keys [expr {$i % [llength $accent_keys]}]]
    set color $theme($color_key)
    set btn [make_button .c.inner.btns btn$i $label $color \
        [list reveal_app $con_id]]
    pack $btn -fill x -padx 8 -pady 3

    # Bind digit key (1-9) to this button's action
    if {$num <= 9} {
        bind . <Key-$num> [list reveal_app $con_id]
    }

    incr i
}

bind . <Escape> {destroy .}
