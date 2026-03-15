# Action Procedures - System and application actions

proc do_shutdown {} {
    set confirm [file join $::env(HOME) .alatar/scripts/confirm.tcl]
    exec setsid $confirm "Shutdown?" "systemctl poweroff" &
    exit
}

proc do_restart {} {
    set confirm [file join $::env(HOME) .alatar/scripts/confirm.tcl]
    exec setsid $confirm "Restart?" "systemctl reboot" &
    exit
}

proc do_logout {} {
    set confirm [file join $::env(HOME) .alatar/scripts/confirm.tcl]
    exec setsid $confirm "Logout of session?" "swaymsg exit" &
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
