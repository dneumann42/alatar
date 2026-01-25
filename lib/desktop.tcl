#!/usr/bin/env tclsh

::alatar::deps::ensure {desktop}

proc ensureSwaySession {} {
    set session_dir "/usr/share/wayland-sessions"
    set session_file "$session_dir/sway.desktop"

    if {[file exists $session_file]} {
        return
    }

    if {![file isdirectory $session_dir]} {
        if {[catch {exec sudo mkdir -p $session_dir 2>@1} result]} {
            error "Failed to create $session_dir: $result"
        }
    }

    set content {[Desktop Entry]
Name=Sway
Comment=An i3-compatible Wayland compositor
Exec=sway --unsupported-gpu
Type=Application
DesktopNames=sway}

    set temp_file "/tmp/sway.desktop"
    dump $temp_file $content

    if {[catch {exec sudo mv $temp_file $session_file 2>@1} result]} {
        error "Failed to install sway session file: $result"
    }

    if {[catch {exec sudo chmod 644 $session_file 2>@1} result]} {
        error "Failed to set permissions on $session_file: $result"
    }

    puts "Created sway session file for ly at $session_file"
}

ensureSwaySession
enableService "ly@tty2.service"
