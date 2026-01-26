#!/usr/bin/env tclsh

::alatar::deps::ensure {desktop}

proc runCmd {cmd} {
    set result {}
    set status [catch {exec {*}$cmd} result]
    if {$status != 0} {
        puts "$result"
        exit 1
    }
    return $result
}

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

    puts "Generating abstract wallpaper..."

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

proc ensureFonts {} {
    set fonts_dir "$::env(HOME)/.local/share/fonts"
    set res_dir "$::env(ALATAR_HOME)/res"

    if {![file isdirectory $fonts_dir]} {
        file mkdir $fonts_dir
    }

    # Copy all font files from res directory
    if {[file isdirectory $res_dir]} {
        set font_patterns {*.ttf *.otf *.TTF *.OTF}
        set copied 0

        foreach pattern $font_patterns {
            set font_files [glob -nocomplain -directory $res_dir $pattern]
            foreach font_file $font_files {
                set font_name [file tail $font_file]
                set dest "$fonts_dir/$font_name"

                if {![file exists $dest] || [file mtime $font_file] > [file mtime $dest]} {
                    file copy -force $font_file $dest
                    puts "Installed font: $font_name"
                    incr copied
                }
            }
        }

        if {$copied > 0} {
            # Refresh font cache
            if {![catch {exec fc-cache -f 2>@1}]} {
                puts "Font cache refreshed"
            }
        }
    }
}

proc ensureMakoService {} {
    set service_dir "$::env(HOME)/.config/systemd/user"
    set service_file "$service_dir/mako.service"

    if {![file exists $service_file]} {
        if {![file isdirectory $service_dir]} {
            file mkdir $service_dir
        }

        set content {[Unit]
Description=Mako notification daemon
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/mako

[Install]
WantedBy=sway-session.target}

        dump $service_file $content
        puts "Created mako systemd user service at $service_file"
    }

    enableService -user mako.service
}

proc ensureFlatpakWaylandPermissions {} {
    set apps {com.spotify.Client}

    foreach app $apps {
        if {[catch {exec flatpak info $app 2>@1}]} {
            continue
        }

        if {[catch {exec flatpak override --user $app --socket=wayland --socket=fallback-x11 --share=ipc 2>@1} result]} {
            puts "WARNING: Failed to set permissions for $app: $result"
        }
    }
}

proc ensureOctopi {} {
    set aur_dir "$::env(HOME)/.cache/aur"

    if {![file isdirectory "$aur_dir/octopi"]} {
	runCmd "mkdir -p $aur_dir"
	runCmd "git clone https://aur.archlinux.org/octopi.git $aur_dir/octopi"
    }

    if {![commandExists "octopi"]} {
	puts "Starting octopi installation "
	cd "$aur_dir/octopi"
	runCmd "makepkg -si --noconfirm"
	cd ..
	runCmd "rm -rf octopi"
	puts "Installed octopi."
    }
}

ensureSwaySession
ensureWallpaper
ensureFonts
enableService ly@tty2.service
ensureMakoService
ensureFlatpakWaylandPermissions
ensureOctopi
