# Layout - Main UI layout construction

proc build_tome_image {} {
    global theme
    set tome_path [file join $::env(HOME) .alatar res nomicron.png]
    if {[file exists $tome_path]} {
        image create photo tome_original -file $tome_path
        set orig_width [image width tome_original]
        set orig_height [image height tome_original]

        # Calculate subsample factor to fit within 512x512
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
    set system [make_icon_button $config_path system "⚙" do_system "System" "s" $theme(teal)]

    pack $audio $system \
        -side left \
        -fill x \
        -expand 1

    return $config_path
}

proc make_wallpaper_section {parent} {
    global theme
    if {$parent eq "."} {
        set wallpaper_path ".wallpaper"
    } else {
        set wallpaper_path "$parent.wallpaper"
    }
    frame $wallpaper_path -bg $theme(surface0)

    set wallpapers [make_icon_button $wallpaper_path wallpapers "🖼" do_wallpapers "Wallpapers" "w" $theme(sapphire)]
    set porthole [make_icon_button $wallpaper_path porthole "Porthole" do_porthole "Porthole Wallpaper Downloader" "" $theme(sapphire)]

    pack $wallpapers $porthole \
        -side left \
        -fill x \
        -expand 1

    return $wallpaper_path
}

proc build_main_layout {} {
    global theme
    global spotify_art_label spotify_title_label spotify_artist_label spotify_album_label
    global spotify_play_pause_btn spotify_prev_btn spotify_next_btn spotify_focus_btn

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
        -width 260 \
        -font {TkDefaultFont 10 bold}

    pack .main_container.left_card.group -fill both -expand 1 -padx 6 -pady 6
    pack .main_container.right_card.group -fill both -expand 1 -padx 6 -pady 6

    pack .main_container.left_card -side left -fill both -expand 1 -padx {4 2} -pady 4
    pack .main_container.right_card -side right -fill y -padx {2 4} -pady 4
    pack propagate .main_container.right_card.group 0

    # Build Media UI (right panel)
    build_media_panel

    # Build System UI (left panel)
    build_system_panel
}

proc build_media_panel {} {
    global theme
    global spotify_art_label spotify_title_label spotify_artist_label spotify_album_label
    global spotify_play_pause_btn spotify_prev_btn spotify_next_btn spotify_focus_btn

    frame .main_container.right_card.group.spotify -bg $theme(surface0)

    # Album art container
    frame .main_container.right_card.group.spotify.art_frame -bg $theme(surface0) -width 225 -height 225
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
}

proc build_system_panel {} {
    global theme script_dir

    # Build sections inside left group box
    set config_section [make_config_section .main_container.left_card.group]
    set wallpaper_section [make_wallpaper_section .main_container.left_card.group]

    # Help section with Manuals and Keybindings buttons
    frame .main_container.left_card.group.help_section -bg $theme(surface0)
    set btn_manuals [make_icon_button .main_container.left_card.group.help_section manuals "📚" do_manuals "Manuals" "m" $theme(green)]
    set btn_keybindings [make_icon_button .main_container.left_card.group.help_section keybindings "⌨" do_keybindings "Keybindings" "k" $theme(peach)]

    frame .main_container.left_card.group.tool_section -bg $theme(surface0)
    set btn_software [make_icon_button .main_container.left_card.group.tool_section software "Software" do_software "Software" "o" $theme(red)]
    set btn_pathedit [make_icon_button .main_container.left_card.group.tool_section pathedit "Edit Path" do_pathedit "Edit PATH variable" "e" $theme(red)]
    set btn_projects [make_icon_button .main_container.left_card.group.tool_section projects "Projects" do_projects "Manage projects" "p" $theme(red)]

    pack $btn_manuals $btn_keybindings \
        -side left \
        -fill x \
        -expand 1

    frame .main_container.left_card.group.power_section -bg $theme(surface0)
    set btn1 [make_button .main_container.left_card.group.power_section shutdown "Shutdown" $theme(accent1) do_shutdown]
    set btn2 [make_button .main_container.left_card.group.power_section restart "Restart" $theme(accent2) do_restart]
    set btn3 [make_button .main_container.left_card.group.power_section logout "Logout" $theme(accent2) do_logout]

    pack $btn1 $btn2 $btn3 \
        -side top \
        -fill x

    pack .main_container.left_card.group.power_section -side top -fill x -padx 4 -pady {4 0}
    pack $config_section -side top -fill x -padx 4 -pady {4 0}
    pack $wallpaper_section -side top -fill x -padx 4 -pady {4 0}
    pack .main_container.left_card.group.help_section -side top -fill x -padx 4 -pady {4 0}

    pack $btn_software -side top -fill x -padx 4 -pady {4 0}
    pack $btn_pathedit -side top -fill x -padx 4 -pady 0
    pack $btn_projects -side top -fill x -padx 4 -pady {0 4}
    pack .main_container.left_card.group.tool_section -side bottom -fill x
}

proc setup_keybindings {} {
    bind . <a> do_audio
    bind . <w> do_wallpapers
    bind . <s> do_system
    bind . <m> do_manuals
    bind . <k> do_keybindings
    bind . <o> do_software
    bind . <e> do_pathedit
    bind . <p> do_projects
}
