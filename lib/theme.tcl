#!/usr/bin/env tclsh

array set theme {
    base #000000
    mantle #000000
    crust #000000
    text #e6e6e6
    subtext0 #b0b0b0
    overlay0 #808080
    surface0 #0f0f0f
    surface1 #1a1a1a
    surface2 #2a2a2a
    heading #1a1a1a
    heading_active #2a2a2a
    selected_bg #2a2a2a
    active_bg #151515
    button_bg #1a1a1a
    button_text #e6e6e6
    selected_text #ffffff
    tab_bg #0a0a0a
    tab_active_bg #1a1a1a
    tab_selected_bg #2a2a2a
    tab_text #cfcfcf
    tab_selected_text #ffffff
    entry_bg #1a1a1a
    entry_text #e6e6e6
    border #2a2a2a
    border_active #4a4a4a
    scrollbar_trough #0a0a0a
    scrollbar_thumb #2a2a2a
    scrollbar_thumb_active #3a3a3a
    scrollbar_arrow #cfcfcf
    lavender #b4befe
    sapphire #74c7ec
    teal #94e2d5
    peach #fab387
    red #f38ba8
    green #a6e3a1
    mauve #cba6f7
    accent1 #cc6666
    accent2 #b5bd68
    accent3 #f0c674
    accent4 #81a2be
}

proc load_wallust_theme {{config_name ""}} {
    global theme
    if {$config_name eq ""} {
        set config_name "theme"
    }
    set theme_file [file normalize "~/.config/wallust/${config_name}.tcl"]
    if {[file exists $theme_file]} {
        catch {source $theme_file}
    }
}

proc setup_theme_fonts {} {
    global theme

    # Create theme fonts that all apps can use
    set ::theme_font_heading [font create -family "Ancient" -size 24]
    set ::theme_font_subheading [font create -family "Ancient" -size 18]
    set ::theme_font_body [font actual TkDefaultFont]
}

proc apply_ttk_theme {} {
    global theme
    setup_theme_fonts
    ttk::style theme use clam
    ttk::style configure TFrame -background $theme(base) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style configure TLabel -background $theme(base) -foreground $theme(text)
    ttk::style configure TButton -background $theme(button_bg) -foreground $theme(button_text) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style map TButton \
        -background [list active $theme(heading_active) pressed $theme(selected_bg)] \
        -foreground [list active $theme(button_text) pressed $theme(button_text)]
    # IconButton style - image on far left, text centered
    ttk::style layout IconButton.TButton {
        Button.border -sticky nswe -children {
            Button.focus -sticky nswe -children {
                Button.padding -sticky nswe -children {
                    Button.image -side left -sticky w
                    Button.label -sticky we -expand 1
                }
            }
        }
    }
    ttk::style configure IconButton.TButton -background $theme(button_bg) -foreground $theme(button_text) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border) \
        -padding {6 4}
    ttk::style map IconButton.TButton \
        -background [list active $theme(heading_active) pressed $theme(selected_bg)] \
        -foreground [list active $theme(button_text) pressed $theme(button_text)]
    ttk::style configure TEntry -fieldbackground $theme(entry_bg) -foreground $theme(entry_text) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style map TEntry \
        -fieldbackground [list readonly $theme(entry_bg) disabled $theme(entry_bg)] \
        -bordercolor [list focus $theme(border_active)]
    ttk::style configure TNotebook -background $theme(base) -borderwidth 0 \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style configure TNotebook.Tab -background $theme(tab_bg) -foreground $theme(lavender) -padding {12 6} \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style map TNotebook.Tab \
        -background [list selected $theme(tab_selected_bg) active $theme(tab_active_bg)] \
        -foreground [list selected $theme(peach) active $theme(sapphire)]
    ttk::style configure TScrollbar -troughcolor $theme(scrollbar_trough) -background $theme(scrollbar_thumb) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border) \
        -arrowcolor $theme(scrollbar_arrow)
    ttk::style map TScrollbar -background [list active $theme(scrollbar_thumb_active)] \
        -arrowcolor [list active $theme(text)]
}

proc configure_root_window {} {
    global theme
    . configure -background $theme(base)
}

# Create a button with text shadow effect (matching calisto's text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.7))
# Returns the button widget path
proc create_shadow_button {parent text command args} {
    global theme

    # Parse additional options
    array set opts {
        -bg ""
        -fg ""
        -activebackground ""
        -activeforeground ""
        -font ""
        -width 0
        -height 0
        -padx 12
        -pady 6
        -relief raised
        -borderwidth 2
        -cursor hand2
    }

    foreach {key val} $args {
        set opts($key) $val
    }

    # Set defaults from theme if not specified
    if {$opts(-bg) eq ""} { set opts(-bg) $theme(button_bg) }
    if {$opts(-fg) eq ""} { set opts(-fg) $theme(button_text) }
    if {$opts(-activebackground) eq ""} { set opts(-activebackground) $theme(heading_active) }
    if {$opts(-activeforeground) eq ""} { set opts(-activeforeground) $theme(button_text) }

    # Create a canvas for the button
    set btn [canvas $parent -bg $opts(-bg) -highlightthickness 0 \
        -relief $opts(-relief) -borderwidth $opts(-borderwidth) -cursor $opts(-cursor)]

    # Calculate button size
    if {$opts(-font) ne ""} {
        set font $opts(-font)
    } else {
        set font [font actual TkDefaultFont]
    }

    # Measure text size
    set text_width [font measure $font $text]
    set text_height [font metrics $font -linespace]

    # Add padding
    set canvas_width [expr {$text_width + $opts(-padx) * 2}]
    set canvas_height [expr {$text_height + $opts(-pady) * 2}]

    if {$opts(-width) > 0} {
        set canvas_width $opts(-width)
    }
    if {$opts(-height) > 0} {
        set canvas_height $opts(-height)
    }

    $btn configure -width $canvas_width -height $canvas_height

    # Center position
    set center_x [expr {$canvas_width / 2}]
    set center_y [expr {$canvas_height / 2}]

    # Create shadow text (1px 1px offset with semi-transparent black)
    # Since Tk doesn't support rgba, we'll use a dark gray (#2a2a2a with ~0.7 opacity looks like rgba(0,0,0,0.7))
    set shadow [$btn create text [expr {$center_x + 1}] [expr {$center_y + 1}] \
        -text $text -font $font -fill "#1a1a1a" -tags shadow]

    # Create main text
    set main_text [$btn create text $center_x $center_y \
        -text $text -font $font -fill $opts(-fg) -tags maintext]

    # Store references in global array
    global shadow_button_state
    set shadow_button_state($btn,shadow) $shadow
    set shadow_button_state($btn,maintext) $main_text
    set shadow_button_state($btn,normal_bg) $opts(-bg)
    set shadow_button_state($btn,normal_fg) $opts(-fg)
    set shadow_button_state($btn,active_bg) $opts(-activebackground)
    set shadow_button_state($btn,active_fg) $opts(-activeforeground)

    # Bind events
    bind $btn <ButtonPress-1> [list invoke_shadow_button $btn $command]
    bind $btn <Enter> [list shadow_button_enter $btn]
    bind $btn <Leave> [list shadow_button_leave $btn]

    return $btn
}

proc shadow_button_enter {btn} {
    global shadow_button_state
    set active_bg $shadow_button_state($btn,active_bg)
    set active_fg $shadow_button_state($btn,active_fg)
    $btn configure -bg $active_bg
    $btn itemconfigure maintext -fill $active_fg
}

proc shadow_button_leave {btn} {
    global shadow_button_state
    set normal_bg $shadow_button_state($btn,normal_bg)
    set normal_fg $shadow_button_state($btn,normal_fg)
    $btn configure -bg $normal_bg
    $btn itemconfigure maintext -fill $normal_fg
}

proc invoke_shadow_button {btn command} {
    # Visual feedback - slightly move text down
    $btn move shadow 0 1
    $btn move maintext 0 1
    after 100 [list $btn move shadow 0 -1]
    after 100 [list $btn move maintext 0 -1]

    # Execute command
    if {$command ne ""} {
        uplevel #0 $command
    }
}

# Simple wrapper for creating buttons with text shadow (compatible with standard button syntax)
# Usage: shadow_button .path -text "Label" -command do_something [other options...]
proc shadow_button {path args} {
    global theme

    # Parse args to extract text and command
    array set opts {
        -text ""
        -command ""
        -bg ""
        -fg ""
        -activebackground ""
        -activeforeground ""
        -font ""
        -padx 12
        -pady 6
        -relief raised
        -borderwidth 2
        -cursor hand2
        -width 0
        -height 0
    }

    foreach {key val} $args {
        if {[info exists opts($key)]} {
            set opts($key) $val
        }
    }

    # Use theme defaults if not specified
    if {$opts(-bg) eq ""} { set opts(-bg) $theme(button_bg) }
    if {$opts(-fg) eq ""} { set opts(-fg) $theme(button_text) }
    if {$opts(-activebackground) eq ""} { set opts(-activebackground) $theme(heading_active) }
    if {$opts(-activeforeground) eq ""} { set opts(-activeforeground) $theme(button_text) }

    # Font
    if {$opts(-font) eq ""} {
        set font [font actual TkDefaultFont]
    } else {
        set font $opts(-font)
    }

    # Measure text to get proper size
    set text_width [font measure $font $opts(-text)]
    set text_height [font metrics $font -linespace]

    # Create canvas for the button
    canvas $path -bg $opts(-bg) -relief $opts(-relief) -borderwidth $opts(-borderwidth) \
        -cursor $opts(-cursor) -highlightthickness 0

    # Calculate canvas size including padding
    set canvas_width [expr {$text_width + $opts(-padx) * 2 + 2}]
    set canvas_height [expr {$text_height + $opts(-pady) * 2 + 2}]

    $path configure -width $canvas_width -height $canvas_height

    # Center position for text
    set center_x [expr {$canvas_width / 2}]
    set center_y [expr {$canvas_height / 2}]

    # Create shadow text (1px 1px offset, dark color matching calisto's rgba(0, 0, 0, 0.7))
    set shadow [$path create text [expr {$center_x + 1}] [expr {$center_y + 1}] \
        -text $opts(-text) -font $font -fill "#1a1a1a" -tags shadow]

    # Create main text
    set maintext [$path create text $center_x $center_y \
        -text $opts(-text) -font $font -fill $opts(-fg) -tags maintext]

    # Store button state in global array
    global shadow_button_state
    set shadow_button_state($path,normal_bg) $opts(-bg)
    set shadow_button_state($path,normal_fg) $opts(-fg)
    set shadow_button_state($path,active_bg) $opts(-activebackground)
    set shadow_button_state($path,active_fg) $opts(-activeforeground)
    set shadow_button_state($path,command) $opts(-command)

    # Bind events
    bind $path <Enter> [list shadow_button_enter $path]
    bind $path <Leave> [list shadow_button_leave $path]
    bind $path <Button-1> [list shadow_button_invoke $path]

    return $path
}

proc shadow_button_invoke {path} {
    global shadow_button_state
    set command $shadow_button_state($path,command)
    if {$command ne ""} {
        uplevel #0 $command
    }
}

# Reload theme and reapply to all widgets
proc reload_theme {{config_name ""}} {
    global theme theme_old

    # Save old theme for color mapping
    array set theme_old [array get theme]

    # Reload theme file
    load_wallust_theme $config_name

    # Reapply TTK theme
    apply_ttk_theme

    # Update root window
    configure_root_window

    # Recursively update all widgets
    update_widget_colors .
}

# Map old color to new color
proc map_theme_color {old_color} {
    global theme theme_old

    # Return as-is if not a hex color
    if {![string match "#*" $old_color]} {
        return $old_color
    }

    # Try to find which theme color this was
    foreach {key value} [array get theme_old] {
        if {$value eq $old_color} {
            # Found a match, return the new value for this key
            if {[info exists theme($key)]} {
                return $theme($key)
            }
        }
    }

    # No match found, return original
    return $old_color
}

# Recursively update widget colors
proc update_widget_colors {widget} {
    global theme

    # Update this widget based on its type and configuration
    set widget_class [winfo class $widget]

    catch {
        switch -glob $widget_class {
            "Frame" {
                set current_bg [$widget cget -bg]
                if {[string match "#*" $current_bg]} {
                    set new_bg [map_theme_color $current_bg]
                    if {$new_bg ne $current_bg} {
                        $widget configure -bg $new_bg
                    }
                }

                # Handle highlightbackground for borders
                if {[catch {$widget cget -highlightbackground} current_border] == 0} {
                    if {[string match "#*" $current_border]} {
                        set new_border [map_theme_color $current_border]
                        if {$new_border ne $current_border} {
                            $widget configure -highlightbackground $new_border
                        }
                    }
                }
            }
            "Label" {
                set current_bg [$widget cget -bg]
                set current_fg [$widget cget -fg]

                if {[string match "#*" $current_bg]} {
                    set new_bg [map_theme_color $current_bg]
                    if {$new_bg ne $current_bg} {
                        $widget configure -bg $new_bg
                    }
                }

                if {[string match "#*" $current_fg]} {
                    set new_fg [map_theme_color $current_fg]
                    if {$new_fg ne $current_fg} {
                        $widget configure -fg $new_fg
                    }
                }
            }
            "Toplevel" {
                set current_bg [$widget cget -bg]
                if {[string match "#*" $current_bg]} {
                    set new_bg [map_theme_color $current_bg]
                    if {$new_bg ne $current_bg} {
                        $widget configure -bg $new_bg
                    }
                }
            }
            "Labelframe" {
                set current_bg [$widget cget -bg]
                set current_fg [$widget cget -fg]

                if {[string match "#*" $current_bg]} {
                    set new_bg [map_theme_color $current_bg]
                    if {$new_bg ne $current_bg} {
                        $widget configure -bg $new_bg
                    }
                }

                if {[string match "#*" $current_fg]} {
                    set new_fg [map_theme_color $current_fg]
                    if {$new_fg ne $current_fg} {
                        $widget configure -fg $new_fg
                    }
                }
            }
        }
    }

    # Recursively update children
    foreach child [winfo children $widget] {
        update_widget_colors $child
    }
}

# Start watching theme file for changes using inotify
proc start_theme_watcher {{config_name ""} {interval 2000}} {
    global theme_watcher_channel theme_watcher_config

    if {$config_name eq ""} {
        set config_name "theme"
    }

    set theme_watcher_config $config_name
    set theme_file [file normalize "~/.config/wallust/${config_name}.tcl"]

    # Check if inotifywait is available
    if {[catch {exec which inotifywait} inotify_path]} {
        # inotifywait not available, fall back to polling
        start_theme_watcher_polling $config_name $interval
        return
    }

    # Start inotifywait to monitor the theme file
    # -m = monitor continuously
    # -e close_write = watch for close after write (most reliable for file updates)
    # -q = quiet mode, only output events
    if {[catch {open "|inotifywait -m -q -e close_write -e modify $theme_file 2>/dev/null" r} theme_watcher_channel]} {
        # Failed to start inotifywait, fall back to polling
        start_theme_watcher_polling $config_name $interval
        return
    }

    # Configure channel as non-blocking with line buffering
    fconfigure $theme_watcher_channel -blocking 0 -buffering line

    # Set up file event to read notifications
    fileevent $theme_watcher_channel readable [list handle_theme_change $config_name $interval]
}

# Handle inotify notification
proc handle_theme_change {config_name interval} {
    global theme_watcher_channel

    if {[eof $theme_watcher_channel]} {
        catch {close $theme_watcher_channel}
        # inotifywait died, restart it
        after 1000 [list start_theme_watcher $config_name $interval]
        return
    }

    if {[gets $theme_watcher_channel line] >= 0} {
        # Theme file was modified, reload it immediately
        reload_theme $config_name
    }
}

# Fallback: polling-based theme watcher
proc start_theme_watcher_polling {config_name interval} {
    global theme_watcher_mtime

    set theme_file [file normalize "~/.config/wallust/${config_name}.tcl"]

    # Store initial modification time
    if {[file exists $theme_file]} {
        set theme_watcher_mtime [file mtime $theme_file]
    } else {
        set theme_watcher_mtime 0
    }

    # Start the polling loop
    check_theme_file $config_name $interval
}

# Polling check for theme file changes
proc check_theme_file {config_name interval} {
    global theme_watcher_mtime

    set theme_file [file normalize "~/.config/wallust/${config_name}.tcl"]

    if {[file exists $theme_file]} {
        set current_mtime [file mtime $theme_file]

        if {$current_mtime > $theme_watcher_mtime} {
            # Theme file has been modified, reload it
            set theme_watcher_mtime $current_mtime
            reload_theme $config_name
        }
    }

    # Schedule next check
    after $interval [list check_theme_file $config_name $interval]
}
