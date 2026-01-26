#!/usr/bin/env tclsh

package require Tk
source [file join $::env(HOME) .alatar/lib/theme.tcl] 

load_wallust_theme "nomicron"
apply_ttk_theme
configure_root_window

wm title . "nomicron"

set script_dir [file join $::env(HOME) .alatar/scripts]

proc cleanup_and_exit {} {
    exit
}

bind . <Escape> cleanup_and_exit
wm protocol . WM_DELETE_WINDOW cleanup_and_exit

# Load and display tome image
set tome_path [file join $::env(HOME) .alatar res nomicron.png]
if {[file exists $tome_path]} {
    image create photo tome_original -file $tome_path
    set orig_width [image width tome_original]
    set orig_height [image height tome_original]

    # Calculate subsample factor to fit within 128x128
    set target_size 512
    set subsample_w [expr {int(ceil(double($orig_width) / $target_size))}]
    set subsample_h [expr {int(ceil(double($orig_height) / $target_size))}]
    set subsample [expr {$subsample_w > $subsample_h ? $subsample_w : $subsample_h}]

    if {$subsample < 1} {
        set subsample 1
    }

    # Create resized image using subsample
    image create photo tome_image
    tome_image copy tome_original -subsample $subsample $subsample

    frame .image_section -bg $theme(base)
    label .image_section.image -image tome_image -bg $theme(base)
    pack .image_section.image -pady 8
    pack .image_section -side top -fill x
}

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
    exec setsid myrlyn-sudo &
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

proc make_icon_button {parent name icon_text command {tooltip ""} {key ""} {bg_color ""}} {
    global theme
    if {$parent eq "."} {
        set path ".$name"
    } else {
        set path "$parent.$name"
    }

    # Use provided background color or fallback to theme button_bg
    if {$bg_color eq ""} {
        set bg_color $theme(button_bg)
    }

    # Icon color is always white for colored backgrounds
    set icon_color "#ffffff"

    frame $path -bg $bg_color -highlightthickness 1 -highlightbackground $theme(border)
    label $path.icon -text $icon_text -bg $bg_color -fg $icon_color \
        -font {TkDefaultFont 16}

    pack $path.icon -side left -padx {12 0} -pady 8

    # Calculate lighter hover color (add 20 to each RGB component)
    set hover_color [brighten_color $bg_color 20]

    set enter_cmd [list $path configure -bg $hover_color]
    set leave_cmd [list $path configure -bg $bg_color]
    append enter_cmd "; $path.icon configure -bg $hover_color"
    append leave_cmd "; $path.icon configure -bg $bg_color"

    if {$key ne ""} {
        label $path.key -text $key -bg $bg_color -fg $icon_color \
            -font {TkDefaultFont 9}
        pack $path.key -side right -padx {0 8} -pady 8
        append enter_cmd "; $path.key configure -bg $hover_color"
        append leave_cmd "; $path.key configure -bg $bg_color"
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

proc brighten_color {color amount} {
    # Parse hex color
    set color [string trimleft $color "#"]
    scan $color "%2x%2x%2x" r g b

    # Add amount to each component, capping at 255
    set r [expr {min(255, $r + $amount)}]
    set g [expr {min(255, $g + $amount)}]
    set b [expr {min(255, $b + $amount)}]

    return [format "#%02x%02x%02x" $r $g $b]
}

proc make_config_section {parent} {
    global theme
    if {$parent eq "."} {
        set config_path ".config"
    } else {
        set config_path "$parent.config"
    }
    frame $config_path -bg $theme(surface0)

    set audio [make_icon_button $config_path audio "🔊" do_audio "Audio" "a" $theme(lavender)]
    set wallpapers [make_icon_button $config_path wallpapers "🖼" do_wallpapers "Wallpapers" "w" $theme(sapphire)]
    set system [make_icon_button $config_path system "⚙" do_system "System" "s" $theme(teal)]

    pack $audio $wallpapers $system \
	-side left \
	-fill x \
	-expand 1

    return $config_path
}

# Container frame for side-by-side layout
frame .main_container -bg $theme(base)

pack .main_container -side top -fill both -expand 1 -padx 4 -pady 4

# Create card-like styling for group boxes
frame .main_container.left_card -bg $theme(surface0) -relief raised -borderwidth 2
frame .main_container.right_card -bg $theme(surface0) -relief raised -borderwidth 2

# Left group box
labelframe .main_container.left_card.group \
    -text " System " \
    -bg $theme(surface0) \
    -fg $theme(text) \
    -borderwidth 0 \
    -relief flat \
    -padx 8 \
    -pady 8 \
    -font {TkDefaultFont 10 bold}

# Right group box
labelframe .main_container.right_card.group \
    -text " Media " \
    -bg $theme(surface0) \
    -fg $theme(text) \
    -borderwidth 0 \
    -relief flat \
    -padx 8 \
    -pady 8 \
    -width 280 \
    -font {TkDefaultFont 10 bold}

pack .main_container.left_card.group -fill both -expand 1 -padx 6 -pady 6
pack .main_container.right_card.group -fill both -expand 1 -padx 6 -pady 6

pack .main_container.left_card -side left -fill both -expand 1 -padx {4 2} -pady 4
pack .main_container.right_card -side right -fill y -padx {2 4} -pady 4
pack propagate .main_container.right_card.group 0

# Spotify integration
# Track currently downloading album art to prevent duplicate downloads
set ::downloading_art_urls [dict create]

proc get_spotify_metadata {} {
    set metadata {}
    if {[catch {exec playerctl -p spotify metadata --format "{{title}}\n{{artist}}\n{{album}}\n{{mpris:artUrl}}\n{{status}}" 2>@1} result]} {
        # Spotify not running or no track
        return {}
    }
    set lines [split $result "\n"]
    if {[llength $lines] >= 5} {
        dict set metadata title [lindex $lines 0]
        dict set metadata artist [lindex $lines 1]
        dict set metadata album [lindex $lines 2]
        dict set metadata artUrl [lindex $lines 3]
        dict set metadata status [lindex $lines 4]
    }
    return $metadata
}

proc spotify_play_pause {} {
    catch {exec playerctl -p spotify play-pause}
}

proc spotify_next {} {
    catch {exec playerctl -p spotify next}
    after 500 update_spotify_info
}

proc spotify_previous {} {
    catch {exec playerctl -p spotify previous}
    after 500 update_spotify_info
}

proc spotify_focus {} {
    global script_dir
    set cmd [file join $script_dir "focus-spotify.tcl"]
    if {[file exists $cmd]} {
        catch {exec setsid $cmd &}
    }
    exit 0;
}

proc download_album_art {url} {
    # Handle file:// URLs from Spotify
    if {[string match "file://*" $url]} {
        set local_path [string range $url 7 end]
        if {[file exists $local_path]} {
            # Convert to PNG if it's a JPEG
            set png_path [file rootname $local_path].png
            if {![file exists $png_path]} {
                catch {exec convert $local_path $png_path}
            }
            if {[file exists $png_path]} {
                return $png_path
            }
            return $local_path
        }
        return ""
    }

    # Handle HTTP(S) URLs
    set cache_dir "$::env(HOME)/.cache/nomicron"
    file mkdir $cache_dir

    # Extract just the image ID from Spotify URLs
    # Format: https://i.scdn.co/image/ab67616d0000b2732b0c88ad3d7be225c955e08c
    set image_id ""
    if {[regexp {/([a-f0-9]+)$} $url -> image_id]} {
        set cache_file "$cache_dir/$image_id.png"
        set temp_jpg "$cache_dir/$image_id.jpg"
    } else {
        # Fallback: use simple hash
        set hash [expr {abs([string hash $url])}]
        set cache_file "$cache_dir/art_$hash.png"
        set temp_jpg "$cache_dir/art_$hash.jpg"
    }

    # Return cached PNG if it exists
    if {[file exists $cache_file] && [file size $cache_file] > 0} {
        return $cache_file
    }

    # Check if already downloading this URL
    if {[dict exists $::downloading_art_urls $url]} {
        return ""
    }

    # Mark as downloading
    dict set ::downloading_art_urls $url 1

    # Download JPEG
    if {[catch {exec curl -sL -f --max-time 5 -o $temp_jpg $url 2>@1} err]} {
        catch {file delete $temp_jpg}
        dict unset ::downloading_art_urls $url
        return ""
    }

    # Verify the file was downloaded and has content
    if {![file exists $temp_jpg] || [file size $temp_jpg] == 0} {
        catch {file delete $temp_jpg}
        dict unset ::downloading_art_urls $url
        return ""
    }

    # Convert JPEG to PNG (Tk doesn't have built-in JPEG support)
    if {[catch {exec convert $temp_jpg $cache_file 2>@1} err]} {
        catch {file delete $temp_jpg}
        catch {file delete $cache_file}
        dict unset ::downloading_art_urls $url
        return ""
    }

    # Clean up temporary JPEG
    catch {file delete $temp_jpg}

    # Mark download complete
    dict unset ::downloading_art_urls $url

    if {[file exists $cache_file] && [file size $cache_file] > 0} {
        return $cache_file
    }

    return ""
}

proc update_spotify_info {} {
    global spotify_art_label spotify_title_label spotify_artist_label spotify_album_label
    global spotify_play_pause_btn theme

    set metadata [get_spotify_metadata]

    if {[dict size $metadata] == 0} {
        $spotify_title_label configure -text "Spotify not playing"
        $spotify_artist_label configure -text ""
        $spotify_album_label configure -text ""
        $spotify_art_label configure -image ""
        return
    }

    set title [dict get $metadata title]
    set artist [dict get $metadata artist]
    set album [dict get $metadata album]
    set artUrl [dict get $metadata artUrl]
    set status [dict get $metadata status]

    # Update labels
    $spotify_title_label configure -text $title
    $spotify_artist_label configure -text "by $artist"
    $spotify_album_label configure -text "on $album"

    # Update play/pause button icon
    if {$status eq "Playing"} {
        $spotify_play_pause_btn.icon configure -text "⏸"
    } else {
        $spotify_play_pause_btn.icon configure -text "▶"
    }

    # Download and display album art
    if {$artUrl ne ""} {
        set art_file [download_album_art $artUrl]
        if {$art_file ne "" && [file exists $art_file]} {
            if {[catch {
                # Delete old images if they exist
                catch {image delete spotify_art_img}
                catch {image delete spotify_art_display}

                image create photo spotify_art_img -file $art_file
                set w [image width spotify_art_img]
                set h [image height spotify_art_img]

                # Calculate subsample to fit 150x150
                set target 150
                set subsample_w [expr {int(ceil(double($w) / $target))}]
                set subsample_h [expr {int(ceil(double($h) / $target))}]
                set subsample [expr {$subsample_w > $subsample_h ? $subsample_w : $subsample_h}]
                if {$subsample < 1} { set subsample 1 }

                image create photo spotify_art_display
                spotify_art_display copy spotify_art_img -subsample $subsample $subsample

                $spotify_art_label configure -image spotify_art_display -text ""
                image delete spotify_art_img
            } err]} {
                puts "Error loading album art: $err"
            }
        }
    }
}

# Build Spotify UI in right group box
frame .main_container.right_card.group.spotify -bg $theme(surface0)

# Album art container
frame .main_container.right_card.group.spotify.art_frame -bg $theme(surface0) -width 150 -height 150
pack propagate .main_container.right_card.group.spotify.art_frame 0
set spotify_art_label [label .main_container.right_card.group.spotify.art_frame.art -bg $theme(surface0)]
pack $spotify_art_label -fill both -expand 1
pack .main_container.right_card.group.spotify.art_frame -side top -pady {4 8}

# Track info
set spotify_title_label [label .main_container.right_card.group.spotify.title \
    -bg $theme(surface0) -fg $theme(text) -font {TkDefaultFont 11 bold} -wraplength 200]
set spotify_artist_label [label .main_container.right_card.group.spotify.artist \
    -bg $theme(surface0) -fg $theme(tab_text) -font {TkDefaultFont 9}]
set spotify_album_label [label .main_container.right_card.group.spotify.album \
    -bg $theme(surface0) -fg $theme(tab_text) -font {TkDefaultFont 9}]

pack $spotify_title_label -side top -pady 2
pack $spotify_artist_label -side top -pady 1
pack $spotify_album_label -side top -pady 1

# Control buttons
frame .main_container.right_card.group.spotify.controls -bg $theme(surface0)
set spotify_prev_btn [make_icon_button .main_container.right_card.group.spotify.controls prev "⏮" spotify_previous "Previous" "" $theme(mauve)]
set spotify_play_pause_btn [make_icon_button .main_container.right_card.group.spotify.controls play "▶" spotify_play_pause "Play/Pause" "" $theme(mauve)]
set spotify_next_btn [make_icon_button .main_container.right_card.group.spotify.controls next "⏭" spotify_next "Next" "" $theme(mauve)]
set spotify_focus_btn [make_icon_button .main_container.right_card.group.spotify.controls focus "🎵" spotify_focus "Focus Spotify" "" $theme(mauve)]

pack $spotify_prev_btn $spotify_play_pause_btn $spotify_next_btn \
    -side left -fill x -expand 1
pack $spotify_focus_btn -side left -fill x -expand 1

pack .main_container.right_card.group.spotify.controls -side top -fill x -pady 8

pack .main_container.right_card.group.spotify -side top -fill both -expand 1

# Update info initially and every 2 seconds
update_spotify_info
proc spotify_timer {} {
    update_spotify_info
    after 2000 spotify_timer
}
spotify_timer

# Build sections inside left group box
set config_section [make_config_section .main_container.left_card.group]

# Help section with Manuals and Keybindings buttons
frame .main_container.left_card.group.help_section -bg $theme(surface0)
set btn_manuals [make_icon_button .main_container.left_card.group.help_section manuals "📚" do_manuals "Manuals" "m" $theme(green)]
set btn_keybindings [make_icon_button .main_container.left_card.group.help_section keybindings "⌨" do_keybindings "Keybindings" "k" $theme(peach)]

frame .main_container.left_card.group.tool_section -bg $theme(surface0)
set btn_software [make_icon_button .main_container.left_card.group.tool_section software "Software" do_software "Software" "o" $theme(red)]
set btn_pathedit [make_icon_button .main_container.left_card.group.tool_section pathedit "Edit Path" do_pathedit "Edit PATH variable" "e" $theme(red)]

pack $btn_manuals $btn_keybindings \
    -side left \
    -fill x \
    -expand 1 \

frame .main_container.left_card.group.power_section -bg $theme(surface0)
set btn1 [make_button .main_container.left_card.group.power_section shutdown "Shutdown" $theme(accent1) do_shutdown]
set btn2 [make_button .main_container.left_card.group.power_section restart "Restart" $theme(accent2) do_restart]
set btn3 [make_button .main_container.left_card.group.power_section logout "Logout" $theme(accent2) do_logout]

pack $btn1 $btn2 $btn3 \
    -side top \
    -fill x

pack .main_container.left_card.group.power_section -side top -fill x -padx 4 -pady {4 0}
pack $config_section -side top -fill x -padx 4 -pady {4 0}
pack .main_container.left_card.group.help_section -side top -fill x -padx 4 -pady {4 0}

pack $btn_software -side top -fill x -padx 4 -pady {4 0}
pack $btn_pathedit -side top -fill x -padx 4 -pady {0 4}
pack .main_container.left_card.group.tool_section -side bottom -fill x

# Keyboard shortcuts
bind . <a> do_audio
bind . <w> do_wallpapers
bind . <s> do_system
bind . <m> do_manuals
bind . <k> do_keybindings
bind . <o> do_software
bind . <e> do_pathedit
