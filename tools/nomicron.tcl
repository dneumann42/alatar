#!/usr/bin/env tclsh
package require Tk

set tools_dir [file normalize [info script]]
set script_dir [file dirname $tools_dir]
source [file join $script_dir theme.tcl]

ensure_single_instance "nomicron"

load_wallust_theme "nomicron"
apply_ttk_theme
configure_root_window

wm title . "nomicron"

proc cleanup_and_exit {} {
    exit
}

bind . <Escape> cleanup_and_exit
wm protocol . WM_DELETE_WINDOW cleanup_and_exit

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

proc do_shutdown {} {
    global theme
    set bg [string range $theme(base) 1 end]
    set fg [string range $theme(text) 1 end]
    set border [string range $theme(border) 1 end]
    set btn_bg [string range $theme(button_bg) 1 end]
    set btn_fg [string range $theme(button_text) 1 end]
    set cmd "swaynag --background $bg --text $fg --border $border --button-background $btn_bg --button-text $btn_fg -m 'Shutdown?' -B 'Yes' 'systemctl poweroff'"
    exec setsid sh -c $cmd &
    exit
}

proc do_restart {} {
    global theme
    set bg [string range $theme(base) 1 end]
    set fg [string range $theme(text) 1 end]
    set border [string range $theme(border) 1 end]
    set btn_bg [string range $theme(button_bg) 1 end]
    set btn_fg [string range $theme(button_text) 1 end]
    set cmd "swaynag --background $bg --text $fg --border $border --button-background $btn_bg --button-text $btn_fg -m 'Restart?' -B 'Yes' 'systemctl reboot'"
    exec setsid sh -c $cmd &
    exit
}

proc do_logout {} {
    global theme
    set bg [string range $theme(base) 1 end]
    set fg [string range $theme(text) 1 end]
    set border [string range $theme(border) 1 end]
    set btn_bg [string range $theme(button_bg) 1 end]
    set btn_fg [string range $theme(button_text) 1 end]
    set cmd "swaynag --background $bg --text $fg --border $border --button-background $btn_bg --button-text $btn_fg -m 'Logout of session?' -B 'Yes' 'swaymsg exit'"
    exec setsid sh -c $cmd &
    exit
}

proc do_software {} {
    exec setsid myrlyn &
    exit
}

proc do_manuals {} {
    global script_dir
    set cmd [file join $script_dir "help.tcl"]
    exec setsid $cmd manuals &
    exit
}

proc do_keybindings {} {
    global script_dir
    set cmd [file join $script_dir "help.tcl"]
    exec setsid $cmd keybindings &
    exit
}

proc do_audio {} {
    exec setsid pavucontrol &
    exit
}
proc do_wallpapers {} {
    exec setsid sh -c "$::env(HOME)/.alatar/scripts/pape.sh pick" &
    exit
}
proc do_system {} {
    exec setsid xdg-open "http://localhost:9090" &
    exit
}

# Create custom button with colored square on far left
proc make_button {parent name text color command} {
    global theme
    if {$parent eq "."} {
        set path ".$name"
    } else {
        set path "$parent.$name"
    }

    frame $path -bg $theme(button_bg) -highlightthickness 1 -highlightbackground $theme(border)
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

proc make_icon_button {parent name icon_text command {tooltip ""} {key ""}} {
    global theme
    if {$parent eq "."} {
        set path ".$name"
    } else {
        set path "$parent.$name"
    }

    frame $path -bg $theme(button_bg) -highlightthickness 1 -highlightbackground $theme(border)
    label $path.icon -text $icon_text -bg $theme(button_bg) -fg $theme(button_text) \
        -font {TkDefaultFont 16}

    pack $path.icon -side left -padx {12 0} -pady 8

    set enter_cmd [list $path configure -bg $theme(heading_active)]
    set leave_cmd [list $path configure -bg $theme(button_bg)]
    append enter_cmd "; $path.icon configure -bg $theme(heading_active)"
    append leave_cmd "; $path.icon configure -bg $theme(button_bg)"

    if {$key ne ""} {
        label $path.key -text $key -bg $theme(button_bg) -fg $theme(text) \
            -font {TkDefaultFont 9}
        pack $path.key -side right -padx {0 8} -pady 8
        append enter_cmd "; $path.key configure -bg $theme(heading_active)"
        append leave_cmd "; $path.key configure -bg $theme(button_bg)"
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

proc make_config_section {parent} {
    global theme
    if {$parent eq "."} {
        set config_path ".config"
    } else {
        set config_path "$parent.config"
    }
    frame $config_path -bg $theme(base)

    set audio [make_icon_button $config_path audio "🔊" do_audio "Audio" "a"]
    set wallpapers [make_icon_button $config_path wallpapers "🖼" do_wallpapers "Wallpapers" "w"]
    set system [make_icon_button $config_path system "⚙" do_system "System" "s"]

    pack $audio $wallpapers $system \
	-side left \
	-fill x \
	-expand 1 \
	-padx 4 \
	-pady 8

    return $config_path
}

set btn1 [make_button . shutdown "Shutdown" $theme(accent1) do_shutdown]
set btn2 [make_button . restart "Restart" $theme(accent2) do_restart]
set btn5 [make_button . logout "Logout" $theme(accent2) do_logout]
set btn3 [make_button . software "Software" $theme(accent3) do_software]

set config_section [make_config_section .]

# Help section with Manuals and Keybindings buttons
frame .help_section -bg $theme(base)
set btn_manuals [make_icon_button .help_section manuals "📚" do_manuals "Manuals" "m"]
set btn_keybindings [make_icon_button .help_section keybindings "⌨" do_keybindings "Keybindings" "k"]
pack $btn_manuals $btn_keybindings \
    -side left \
    -fill x \
    -expand 1 \
    -padx 4 \
    -pady 8

pack $btn1 $btn2 $btn5 $btn3 \
    -side top \
    -fill x

pack $config_section -side top -fill x -pady {8 0}
pack .help_section -side top -fill x

# Keyboard shortcuts
bind . <a> do_audio
bind . <w> do_wallpapers
bind . <s> do_system
bind . <m> do_manuals
bind . <k> do_keybindings

