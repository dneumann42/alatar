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

    # Measure text for canvas sizing
    set font [font actual TkDefaultFont]
    set text_width [font measure $font $text]
    set text_height [font metrics $font -linespace]

    # Create canvas for text with shadow
    canvas $path.text_canvas -bg $theme(button_bg) -highlightthickness 0 \
        -width [expr {$text_width + 4}] -height [expr {$text_height + 2}]

    # Shadow text (1px 1px offset)
    $path.text_canvas create text [expr {$text_width / 2 + 1}] [expr {$text_height / 2 + 1}] \
        -text $text -font $font -fill "#1a1a1a" -tags shadow

    # Main text
    $path.text_canvas create text [expr {$text_width / 2}] [expr {$text_height / 2}] \
        -text $text -font $font -fill $theme(button_text) -tags maintext

    pack $path.square -side left -padx {8 0} -pady 8
    pack $path.text_canvas -side left -fill x -expand 1 -pady 8 -padx {8 8}

    # Button behavior
    set enter_cmd [list $path configure -bg $theme(heading_active)]
    set leave_cmd [list $path configure -bg $theme(button_bg)]
    append enter_cmd "; $path.text_canvas configure -bg $theme(heading_active)"
    append enter_cmd "; $path.text_canvas itemconfigure maintext -fill $theme(button_text)"
    append leave_cmd "; $path.text_canvas configure -bg $theme(button_bg)"
    append leave_cmd "; $path.text_canvas itemconfigure maintext -fill $theme(button_text)"

    bind $path <Enter> $enter_cmd
    bind $path <Leave> $leave_cmd
    bind $path <Button-1> $command
    bind $path.square <Enter> $enter_cmd
    bind $path.square <Leave> $leave_cmd
    bind $path.square <Button-1> $command
    bind $path.text_canvas <Enter> $enter_cmd
    bind $path.text_canvas <Leave> $leave_cmd
    bind $path.text_canvas <Button-1> $command

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

    # Measure icon for canvas sizing
    set icon_font [font create -family [font actual TkDefaultFont -family] -size 16]
    set icon_width [font measure $icon_font $icon_text]
    set icon_height [font metrics $icon_font -linespace]

    # Create canvas for icon with shadow
    canvas $path.icon_canvas -bg $bg_color -highlightthickness 0 \
        -width [expr {$icon_width + 4}] -height [expr {$icon_height + 2}]

    # Shadow icon (1px 1px offset)
    $path.icon_canvas create text [expr {$icon_width / 2 + 1}] [expr {$icon_height / 2 + 1}] \
        -text $icon_text -font $icon_font -fill "#1a1a1a" -tags shadow

    # Main icon
    $path.icon_canvas create text [expr {$icon_width / 2}] [expr {$icon_height / 2}] \
        -text $icon_text -font $icon_font -fill $icon_color -tags mainicon

    pack $path.icon_canvas -side left -padx {12 0} -pady 8

    # Calculate lighter hover color
    set hover_color [brighten_color $bg_color 20]

    set enter_cmd [list $path configure -bg $hover_color]
    set leave_cmd [list $path configure -bg $bg_color]
    append enter_cmd "; $path.icon_canvas configure -bg $hover_color"
    append leave_cmd "; $path.icon_canvas configure -bg $bg_color"

    if {$key ne ""} {
        # Measure key for canvas sizing
        set key_font [font create -family [font actual TkDefaultFont -family] -size 9]
        set key_width [font measure $key_font $key]
        set key_height [font metrics $key_font -linespace]

        # Create canvas for key with shadow
        canvas $path.key_canvas -bg $bg_color -highlightthickness 0 \
            -width [expr {$key_width + 4}] -height [expr {$key_height + 2}]

        # Shadow key
        $path.key_canvas create text [expr {$key_width / 2 + 1}] [expr {$key_height / 2 + 1}] \
            -text $key -font $key_font -fill "#1a1a1a" -tags shadow

        # Main key
        $path.key_canvas create text [expr {$key_width / 2}] [expr {$key_height / 2}] \
            -text $key -font $key_font -fill $icon_color -tags mainkey

        pack $path.key_canvas -side right -padx {0 8} -pady 8
        append enter_cmd "; $path.key_canvas configure -bg $hover_color"
        append leave_cmd "; $path.key_canvas configure -bg $bg_color"
        bind $path.key_canvas <Enter> $enter_cmd
        bind $path.key_canvas <Leave> $leave_cmd
        bind $path.key_canvas <Button-1> $command
    }

    bind $path <Enter> $enter_cmd
    bind $path <Leave> $leave_cmd
    bind $path <Button-1> $command
    bind $path.icon_canvas <Enter> $enter_cmd
    bind $path.icon_canvas <Leave> $leave_cmd
    bind $path.icon_canvas <Button-1> $command

    if {$tooltip ne ""} {
        tooltip_bind $path $tooltip
        tooltip_bind $path.icon_canvas $tooltip
        if {$key ne ""} {
            tooltip_bind $path.key_canvas $tooltip
        }
    }

    return $path
}
