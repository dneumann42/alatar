# Action Procedures - System and application actions

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
    global script_dir
    set cmd [file join $script_dir "clyde.tcl"]
    exec setsid $cmd &
    exit
}

proc do_manuals {} {
    global script_dir
    set cmd [file join $script_dir "help.tcl"]
    exec setsid $cmd manuals &
    exit
}

proc do_pathedit {} {
    global script_dir
    set cmd [file join $script_dir "pathedit.tcl"]
    exec setsid $cmd manuals &
    exit
}

proc do_projects {} {
    global script_dir
    set cmd [file join $script_dir "projects.tcl"]
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
    exec setsid sh -c "$::env(HOME)/.alatar/scripts/pape.tcl pick" &
    exit
}

proc do_porthole {} {
    global script_dir
    set cmd [file join $script_dir "porthole.tcl"]
    exec setsid $cmd &
    exit
}

proc do_system {} {
    exec setsid xdg-open "http://localhost:9090" &
    exit
}
