# UI Components - Buttons, Tooltips, and UI Utilities

# Tooltip system
proc tooltip_show {widget text} {
    global theme
    if {[winfo exists .tooltip]} {
        destroy .tooltip
    }
    set x [expr {[winfo rootx $widget] + [winfo width $widget] / 2}]
    set y [expr {[winfo rooty $widget] + [winfo height $widget] + 4}]
    toplevel .tooltip -bg $theme(border)
    wm overrideredirect .tooltip 1
    wm attributes .tooltip -topmost 1
    label .tooltip.label -text $text -bg $theme(heading) -fg $theme(text) -padx 6 -pady 2
    pack .tooltip.label
    wm geometry .tooltip +$x+$y
}

proc tooltip_hide {} {
    if {[winfo exists .tooltip]} {
        destroy .tooltip
    }
}

proc tooltip_bind {widget text} {
    bind $widget <Enter> +[list after 500 [list tooltip_show $widget $text]]
    bind $widget <Leave> +[list after cancel [list tooltip_show $widget $text]]
    bind $widget <Leave> +tooltip_hide
}

# Color utility
proc brighten_color {color amount} {
    # Parse hex color
    set color [string trimleft $color "#"]
    scan $color "%2x%2x%2x" r g b

    # Add amount to each component, capping at 255
    set r [expr {min(255, $r + $amount)}]
    set g [expr {min(255, $g + $amount)}]
    set b [expr {min(255, $b + $amount)}]

    return [format "#%02x%02x%02x" $r $g $b]
}

# Create custom button with colored square on far left
proc make_button {parent name text color command} {
    global theme
    if {$parent eq "."} {
        set path ".$name"
    } else {
        set path "$parent.$name"
    }

    frame $path -bg $theme(button_bg) -relief raised -borderwidth 2 -cursor hand2
    frame $path.square -bg $color -width 12 -height 12
    label $path.label -text $text -bg $theme(button_bg) -fg $theme(button_text)

    pack $path.square -side left -padx {8 0} -pady 8
    pack $path.label -side left -fill x -expand 1

    # Button behavior
    set enter_cmd [list $path configure -bg $theme(heading_active)]
    set leave_cmd [list $path configure -bg $theme(button_bg)]
    append enter_cmd "; $path.label configure -bg $theme(heading_active)"
    append leave_cmd "; $path.label configure -bg $theme(button_bg)"

    bind $path <Enter> $enter_cmd
    bind $path <Leave> $leave_cmd
    bind $path <Button-1> $command
    bind $path.square <Enter> $enter_cmd
    bind $path.square <Leave> $leave_cmd
    bind $path.square <Button-1> $command
    bind $path.label <Enter> $enter_cmd
    bind $path.label <Leave> $leave_cmd
    bind $path.label <Button-1> $command

    return $path
}

# Create icon button
proc make_icon_button {parent name icon_text command {tooltip ""} {key ""} {bg_color ""}} {
    global theme
    if {$parent eq "."} {
        set path ".$name"
    } else {
        set path "$parent.$name"
    }

    # Use provided background color or fallback to theme button_bg
    if {$bg_color eq ""} {
        set bg_color $theme(button_bg)
    }

    # Icon color is always white for colored backgrounds
    set icon_color "#ffffff"

    frame $path -bg $bg_color -relief raised -borderwidth 2 -cursor hand2
    label $path.icon -text $icon_text -bg $bg_color -fg $icon_color \
        -font {TkDefaultFont 16}

    pack $path.icon -side left -padx {12 0} -pady 8

    # Calculate lighter hover color (add 20 to each RGB component)
    set hover_color [brighten_color $bg_color 20]

    set enter_cmd [list $path configure -bg $hover_color]
    set leave_cmd [list $path configure -bg $bg_color]
    append enter_cmd "; $path.icon configure -bg $hover_color"
    append leave_cmd "; $path.icon configure -bg $bg_color"

    if {$key ne ""} {
        label $path.key -text $key -bg $bg_color -fg $icon_color \
            -font {TkDefaultFont 9}
        pack $path.key -side right -padx {0 8} -pady 8
        append enter_cmd "; $path.key configure -bg $hover_color"
        append leave_cmd "; $path.key configure -bg $bg_color"
        bind $path.key <Enter> $enter_cmd
        bind $path.key <Leave> $leave_cmd
        bind $path.key <Button-1> $command
    }

    bind $path <Enter> $enter_cmd
    bind $path <Leave> $leave_cmd
    bind $path <Button-1> $command
    bind $path.icon <Enter> $enter_cmd
    bind $path.icon <Leave> $leave_cmd
    bind $path.icon <Button-1> $command

    if {$tooltip ne ""} {
        tooltip_bind $path $tooltip
        tooltip_bind $path.icon $tooltip
        if {$key ne ""} {
            tooltip_bind $path.key $tooltip
        }
    }

    return $path
}
