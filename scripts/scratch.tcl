#!/usr/bin/env wish

package require Tk

set script_dir [file join $::env(HOME) .alatar/scripts]

source [file join $::env(HOME) .alatar/lib/theme.tcl]
source [file join $script_dir nomicron/ui.tcl]

load_wallust_theme "nomicron"
apply_ttk_theme
configure_root_window

# Temp files created for SVG→PNG conversion; cleaned up on exit
set ::icon_tmp_files {}

# Returns a list of app IDs for all windows currently in the Sway scratchpad.
# Each element is the app_id (Wayland) or WM_CLASS (X11) of a scratchpad window.
proc get_scratch_apps {} {
    set jq_filter {[.. | objects | select(.name? == "__i3_scratch") | .floating_nodes[] | (.app_id // .window_properties.class // "unknown")] | .[]}
    if {[catch {exec sh -c "swaymsg -t get_tree | jq -r '$jq_filter'"} output]} {
        return {}
    }
    if {$output eq ""} {
        return {}
    }
    return [split $output "\n"]
}

# Returns a list of {con_id title app_id} triples for each window in the scratchpad.
proc get_scratch_details {} {
    set jq_filter {[.. | objects | select(.name? == "__i3_scratch") | .floating_nodes[] | [(.id | tostring), (.name // ""), (.app_id // .window_properties.class // "")]] | .[] | @tsv}
    if {[catch {exec sh -c "swaymsg -t get_tree | jq -r '$jq_filter'"} output]} {
        return {}
    }
    if {$output eq ""} {
        return {}
    }
    set result {}
    foreach line [split $output "\n"] {
        if {$line ne ""} {
            lappend result [split $line "\t"]
        }
    }
    return $result
}

# Find an icon file for the given app_id.
# Checks desktop files for the Icon= name, then searches XDG icon dirs.
# SVG icons are rasterised to a temp PNG via rsvg-convert.
# Returns a filesystem path to a usable image file, or "".
proc find_app_icon {app_id} {
    if {$app_id eq ""} { return "" }

    set home $::env(HOME)

    # .desktop search dirs (including flatpak exports)
    set desktop_dirs [list \
        /usr/share/applications \
        $home/.local/share/applications \
        /var/lib/flatpak/exports/share/applications \
        $home/.local/share/flatpak/exports/share/applications \
    ]

    # Resolve Icon= name from desktop file
    set icon_name $app_id
    foreach dir $desktop_dirs {
        set f [file join $dir ${app_id}.desktop]
        if {[file exists $f]} {
            catch {
                set fh [open $f r]
                foreach line [split [read $fh] "\n"] {
                    if {[regexp {^Icon=(.+)$} $line -> val]} {
                        set icon_name [string trim $val]
                        break
                    }
                }
                close $fh
            }
            break
        }
    }

    # Absolute path in Icon= field
    if {[string match "/*" $icon_name] && [file exists $icon_name]} {
        return $icon_name
    }

    # Base icon directories to search (system + flatpak + user)
    set hicolor_bases [list \
        /usr/share/icons/hicolor \
        /usr/share/icons/Papirus \
        /usr/share/icons/Adwaita \
        /usr/share/icons/breeze \
        $home/.local/share/icons/hicolor \
        /var/lib/flatpak/exports/share/icons/hicolor \
        $home/.local/share/flatpak/exports/share/icons/hicolor \
    ]

    # Search PNG at common sizes (prefer smaller for button display)
    foreach size {32x32 48x48 24x24 64x64 128x128 256x256} {
        foreach base $hicolor_bases {
            set path [file join $base $size apps ${icon_name}.png]
            if {[file exists $path]} { return $path }
        }
    }

    # Pixmaps fallback
    foreach ext {png xpm} {
        set path /usr/share/pixmaps/${icon_name}.${ext}
        if {[file exists $path]} { return $path }
    }

    # SVG → PNG via rsvg-convert
    if {![catch {exec which rsvg-convert}]} {
        foreach base $hicolor_bases {
            set svg [file join $base scalable apps ${icon_name}.svg]
            if {[file exists $svg]} {
                set tmp [exec mktemp /tmp/alatar_icon_XXXXXX.png]
                if {![catch {exec rsvg-convert -w 32 -h 32 -o $tmp $svg}] \
                        && [file size $tmp] > 0} {
                    lappend ::icon_tmp_files $tmp
                    return $tmp
                }
            }
        }
    }

    return ""
}

# Load an icon image from path, scaling down to ~target_px if larger.
# Returns a Tk photo image name, or "".
proc load_icon_image {path {target_px 24}} {
    if {$path eq ""} { return "" }
    if {[catch {set img [image create photo -file $path]} err]} { return "" }
    set w [image width $img]
    if {$w > $target_px} {
        set factor [expr {int($w / $target_px)}]
        if {$factor < 1} { set factor 1 }
        set small [image create photo]
        $small copy $img -subsample $factor $factor
        image delete $img
        set img $small
    }
    return $img
}

# Like make_button from nomicron/ui.tcl but accepts an optional Tk image.
# Shows the image on the left; falls back to the colour square if image is "".
proc make_app_button {parent name text color icon_img command} {
    global theme
    set path "$parent.$name"

    frame $path -bg $theme(button_bg) -relief raised -borderwidth 2 -cursor hand2

    if {$icon_img ne ""} {
        label $path.icon -image $icon_img -bg $theme(button_bg) -bd 0
        pack $path.icon -side left -padx {8 4} -pady 6
    } else {
        frame $path.square -bg $color -width 12 -height 12
        pack $path.square -side left -padx {8 0} -pady 8
    }

    set font [font actual TkDefaultFont]
    set tw [font measure $font $text]
    set th [font metrics $font -linespace]

    canvas $path.tc -bg $theme(button_bg) -highlightthickness 0 \
        -width [expr {$tw + 4}] -height [expr {$th + 2}]
    $path.tc create text [expr {$tw/2 + 1}] [expr {$th/2 + 1}] \
        -text $text -font $font -fill "#1a1a1a" -tags shadow
    $path.tc create text [expr {$tw/2}] [expr {$th/2}] \
        -text $text -font $font -fill $theme(button_text) -tags maintext

    pack $path.tc -side left -fill x -expand 1 -pady 8 -padx {4 8}

    set bg  $theme(button_bg)
    set hov $theme(heading_active)

    set enter_cmd "$path configure -bg $hov; $path.tc configure -bg $hov"
    set leave_cmd "$path configure -bg $bg;  $path.tc configure -bg $bg"
    if {$icon_img ne ""} {
        append enter_cmd "; $path.icon configure -bg $hov"
        append leave_cmd "; $path.icon configure -bg $bg"
    }

    foreach w [list $path $path.tc] {
        bind $w <Enter>    $enter_cmd
        bind $w <Leave>    $leave_cmd
        bind $w <Button-1> $command
    }
    if {$icon_img ne ""} {
        bind $path.icon <Enter>    $enter_cmd
        bind $path.icon <Leave>    $leave_cmd
        bind $path.icon <Button-1> $command
    } elseif {[winfo exists $path.square]} {
        bind $path.square <Enter>    $enter_cmd
        bind $path.square <Leave>    $leave_cmd
        bind $path.square <Button-1> $command
    }

    return $path
}

proc reveal_app {con_id} {
    catch {exec sh -c "swaymsg '\[con_id=$con_id\] scratchpad show'"}
    destroy .
}

proc cleanup_tmp_icons {} {
    foreach f $::icon_tmp_files { catch {file delete $f} }
}

# --- GUI ---

set apps [get_scratch_details]

if {[llength $apps] == 0} {
    wm withdraw .
    tk_messageBox -title "Scratchpad" -message "No apps in the scratchpad." -type ok
    exit
}

wm title . "Scratchpad"
wm resizable . 0 0
tk appname "com.alatar.scratch"

bind . <Destroy> { cleanup_tmp_icons }

# Nomicron-style bordered container
frame .c -bg $theme(border) -relief raised -borderwidth 3
pack .c -fill both -expand 1 -padx 8 -pady 8

frame .c.inner -bg $theme(base)
pack .c.inner -fill both -expand 1 -padx 2 -pady 2

label .c.inner.title -text "Scratchpad" \
    -bg $theme(base) -fg $theme(text) \
    -font $::theme_font_heading -pady 10
pack .c.inner.title -fill x

frame .c.inner.sep -bg $theme(border) -height 1
pack .c.inner.sep -fill x -padx 8

frame .c.inner.btns -bg $theme(base)
pack .c.inner.btns -fill both -expand 1 -pady 6

set accent_keys {lavender sapphire teal peach red green mauve accent1 accent2 accent3 accent4}

set i 0
foreach app $apps {
    lassign $app con_id title app_id
    set num   [expr {$i + 1}]
    set label [expr {$title ne "" ? "$num  $title" : "$num  con:$con_id"}]
    set color_key [lindex $accent_keys [expr {$i % [llength $accent_keys]}]]
    set color $theme($color_key)

    set icon_path [find_app_icon $app_id]
    set icon_img  [load_icon_image $icon_path]

    set btn [make_app_button .c.inner.btns btn$i $label $color $icon_img \
        [list reveal_app $con_id]]
    pack $btn -fill x -padx 8 -pady 3

    if {$num <= 9} {
        bind . <Key-$num> [list reveal_app $con_id]
    }

    incr i
}

bind . <Escape> {destroy .}
