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

proc apply_ttk_theme {} {
    global theme
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
