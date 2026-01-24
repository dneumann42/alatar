# Shared theme library for alatar GUI tools
package require Tclx

proc lock_path {id} { return "/tmp/$id.lock" }

proc read_lock_pid {lockfile} {
    set f [open $lockfile r]
    set line ""
    gets $f line
    close $f
    return [string trim $line]
}

proc pid_alive {pid} {
    if {$pid eq "" || ![string is integer -strict $pid]} { return 0 }
    # kill -0 checks existence/permission without sending a signal
    return [expr {![catch {kill -0 $pid}]}]
}

proc proc_cmdline {pid} {
    set path "/proc/$pid/cmdline"
    if {![file exists $path]} { return "" }
    set f [open $path r]
    fconfigure $f -translation binary
    set data [read $f]
    close $f
    # cmdline is NUL-separated
    return [string map [list "\x00" " "] $data]
}

proc looks_like_our_app {pid id} {
    # Weak but practical: ensure cmdline contains id (or adjust to your script name)
    set cmd [proc_cmdline $pid]
    if {$cmd eq ""} { return 0 }
    return [expr {[string first $id $cmd] >= 0}]
}

proc remove_lock {id} {
    set lf [lock_path $id]
    catch {file delete -force $lf}
}

proc terminate_pid {pid {timeout_ms 1200}} {
    catch {exec kill -9 $pid}

    set step 50
    set waited 0
    while {$waited < $timeout_ms} {
        if {![pid_alive $pid]} { return 1 }
        after $step
        incr waited $step
    }
    catch {exec kill -KILL $pid}
    set waited 0
    while {$waited < 500} {
        if {![pid_alive $pid]} { return 1 }
        after 50
        incr waited 50
    }
    return 0
}

proc kill_if_alive {{id "my_app"}} {
    set lf [lock_path $id]

    if {[file exists $lf]} {
        set old_pid [read_lock_pid $lf]

        if {[pid_alive $old_pid]} {
            puts "Toggling OFF: stopping PID $old_pid"
            if {[terminate_pid $old_pid]} {
                remove_lock $id
                exit 0
            } else {
                puts "Failed to stop PID $old_pid"
                exit 3
            }
        } else {
            # stale lock
            remove_lock $id
        }
    }
}

proc create_application_lock_file {{id "my_app"}} {
    kill_if_alive $id

    set lf [lock_path $id]
    set f [open $lf w]
    puts $f [pid]
    close $f

    # cleanup lock on normal exit
    if {[info commands ::tk::Exit] ne ""} {
        # ignore if missing
        catch {rename ::tk::Exit ::tk::Exit_real}
        proc ::tk::Exit {args} [format {
            catch {file delete -force %s}
            uplevel 1 [list ::tk::Exit_real {*}$args]
        } [list $lf]]
    }

}

proc ensure_single_instance {{id "my_app" }} {
    create_application_lock_file $id
}

array set theme {
    base #000000
    surface0 #0f0f0f
    text #e6e6e6
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
    ttk::style configure TNotebook.Tab -background $theme(tab_bg) -foreground $theme(tab_text) -padding {12 6} \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style map TNotebook.Tab \
        -background [list selected $theme(tab_selected_bg) active $theme(tab_active_bg)] \
        -foreground [list selected $theme(tab_selected_text) active $theme(text)]
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
