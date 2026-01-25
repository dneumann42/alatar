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

proc ensureWallpaper {} {
    set wallpaper "$::env(HOME)/.config/wallpaper.png"

    if {[file exists $wallpaper]} {
        return
    }

    puts "Generating death metal abstract wallpaper..."

    # Get screen resolution, default to 1920x1080 if can't detect
    set width 1920
    set height 1080

    if {![catch {exec xrandr --current 2>@1 | grep -oP '\d+x\d+' | head -1} resolution]} {
        if {[regexp {(\d+)x(\d+)} $resolution _ w h]} {
            set width $w
            set height $h
        }
    }

    # Generate abstract death metal wallpaper using ImageMagick
    # Dark, chaotic plasma with red/black death metal aesthetic
    set cmd [list convert -size ${width}x${height} \
        plasma:fractal \
        -blur 0x2 \
        \( +clone -colorspace gray -negate -blur 0x8 \) \
        -compose overlay -composite \
        -modulate 70,150,0 \
        -level 20%,60% \
        -fill "#8B0000" -colorize 30% \
        -noise 3 \
        -sharpen 0x1 \
        -gamma 0.8 \
        $wallpaper]

    if {[catch {exec {*}$cmd 2>@1} result]} {
        puts "WARNING: Failed to generate wallpaper: $result"
        return
    }

    puts "Generated wallpaper at $wallpaper"

    # Reload sway if running
    if {![catch {exec pgrep -x sway}]} {
        puts "Reloading sway configuration..."
        if {[catch {exec swaymsg reload 2>@1}]} {
            puts "WARNING: Could not reload sway"
        }
    }
}

ensureSwaySession
ensureWallpaper
enableService "ly@tty2.service"
