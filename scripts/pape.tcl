#!/usr/bin/env tclsh

set wallpaper "$::env(HOME)/.config/wallpaper.png"
set wallpapers_dir "$::env(HOME)/Media/pictures/wallpapers"

catch {exec mkdir -p $wallpapers_dir}

proc generate_default_wallpaper {} {
    global wallpaper

    catch {exec notify-send "Generating default wallpaper, please wait..."}

    set seed [expr {int(rand() * 1000000)}]
    set cmd [list magick -seed $seed -size 2560x1080 plasma:fractal \
        -blur 0x6 \
        -auto-level -gamma 0.85 \
        -modulate 100,135,195 \
        ( +clone -colorspace gray -blur 0x20 -contrast-stretch 0x3% ) \
        -compose displace -set option:compose:args 22x10 -composite \
        ( -size 2560x1080 xc:black -attenuate 0.15 +noise Uniform -blur 0x0.9 ) \
        -compose softlight -composite \
        ( -size 2560x1080 radial-gradient:white-black -blur 0x30 ) \
        -compose multiply -composite \
        -resize 2560x1080 $wallpaper]

    if {[catch {exec {*}$cmd 2>@1} result]} {
        puts "ERROR: Failed to generate wallpaper: $result"
        return 0
    }

    catch {exec notify-send "Default wallpaper was generated."}
    return 1
}

proc apply_wallust {} {
    global wallpaper

    set wallust_bin ""
    if {![catch {exec which wallust}]} {
        set wallust_bin "wallust"
    } elseif {[file executable "$::env(HOME)/.cargo/bin/wallust"]} {
        set wallust_bin "$::env(HOME)/.cargo/bin/wallust"
    }

    if {$wallust_bin ne ""} {
        catch {exec mkdir -p "$::env(HOME)/.config/qt6ct/colors"}
        catch {exec $wallust_bin run --config-dir "$::env(HOME)/.config/wallust" --overwrite-cache $wallpaper 2>@1}

        # Update SDDM theme if it's installed
        if {[file isdirectory /usr/share/sddm/themes/alatar]} {
            set theme_conf "$::env(HOME)/.alatar/alatar_dots/sddm/alatar-theme/theme.conf"
            if {[file exists $theme_conf]} {
                catch {exec sudo cp $theme_conf /usr/share/sddm/themes/alatar/theme.conf 2>@1}
            }
        }
    }
}

proc set_wallpaper {image_path} {
    global wallpaper

    catch {exec notify-send "Setting wallpaper"}

    set ext [file extension $image_path]
    if {$ext ne ".png"} {
        catch {exec notify-send "Converting to png... (convert your images to 'PNG' to avoid this delay)"}
        if {[catch {exec magick $image_path $wallpaper 2>@1} result]} {
            puts "ERROR: Failed to convert image: $result"
            return 0
        }
    } else {
        if {[catch {exec cp $image_path $wallpaper 2>@1} result]} {
            puts "ERROR: Failed to copy image: $result"
            return 0
        }
    }

    apply_wallust
    catch {exec swaymsg reload}
    return 1
}

proc pick_wallpaper {{dir ""}} {
    global wallpapers_dir

    if {$dir eq ""} {
        set dir $wallpapers_dir
    }

    set cfg [exec mktemp]

    set fd [open $cfg w]
    puts $fd {[keys.gallery]
Return      = exec sh -c 'echo "$1"' _ "%"; exit
Space       = exec sh -c 'echo "$1"' _ "%"; exit
MouseDouble = exec sh -c 'echo "$1"' _ "%"; exit
h = step_left
l = step_right
j = step_down
k = step_up
Ctrl+d = page_down
Ctrl+u = page_up
g = first_file
G = last_file
q = exit}
    close $fd

    set selection ""
    if {![catch {exec swayimg --gallery --recursive --order=alpha --config-file=$cfg $dir} result]} {
        set selection [string trim $result]
    }

    catch {file delete $cfg}
    return $selection
}

# Main logic
set subcmd [lindex $argv 0]

if {![file exists $wallpaper]} {
    generate_default_wallpaper
    catch {exec swaymsg reload}
}

switch -exact -- $subcmd {
    "set" {
        if {[llength $argv] < 2} {
            puts "ERROR: 'set' requires an image path"
            exit 1
        }
        set image [lindex $argv 1]
        if {![set_wallpaper $image]} {
            exit 1
        }
    }
    "gen" {
        if {![generate_default_wallpaper]} {
            exit 1
        }
        apply_wallust
        catch {exec swaymsg reload}
    }
    "pick" {
        set pape [pick_wallpaper]
        if {$pape ne "" && [file exists $pape]} {
            set_wallpaper $pape
        }
        if {$pape ne ""} {
            puts $pape
        }
    }
    default {
        puts "Invalid parameter, expected 'gen', 'set' or 'pick'"
        exit 1
    }
}

