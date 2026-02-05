#!/usr/bin/env wish

# Porthole — Wallpaper viewer
#   ← →  / n p / scroll    navigate
#   space                   next
#   c                       copy URL to clipboard
#   s                       save wallpaper
#   r                       refresh from Reddit
#   q / Esc                 quit

package require Tk
source [file join $env(HOME) .alatar/lib/theme.tcl]
load_wallust_theme "porthole"
apply_ttk_theme
configure_root_window

proc brighten_color {color amount} {
    set color [string trimleft $color "#"]
    scan $color "%2x%2x%2x" r g b
    set r [expr {min(255, $r + $amount)}]
    set g [expr {min(255, $g + $amount)}]
    set b [expr {min(255, $b + $amount)}]
    return [format "#%02x%02x%02x" $r $g $b]
}

# ─── config ─────────────────────────────────────────
set ::cache_dir [file tildeexpand ~/.local/cache/porthole]
file mkdir $::cache_dir
set ::save_dir  [file join $env(HOME) Media pictures wallpapers]
file mkdir $::save_dir

# ─── state ──────────────────────────────────────────
set ::urls         {}
set ::idx          0
set ::photo        {}
set ::resize_timer {}
set ::info_text    {}

# ─── check deps ─────────────────────────────────────
if {[catch {exec which magick}]} {
    tk_messageBox -title Porthole -type ok -icon error \
        -message "ImageMagick is required.\n\nsudo pacman -S imagemagick"
    exit 1
}

# ─── window ─────────────────────────────────────────
wm title . Porthole
wm geometry . 1200x800
wm minsize . 320 240

canvas .cv -bg $theme(base) -highlightthickness 0
pack .cv -fill both -expand 1

frame .nav -bg $theme(surface0) -highlightthickness 1 -highlightbackground $theme(border)
pack .nav -fill x -side bottom

# prev — lavender
button .nav.prev -text "\u25C0" -command prev \
    -bg $theme(lavender) -fg #ffffff \
    -activebackground [brighten_color $theme(lavender) 25] -activeforeground #ffffff \
    -relief flat -bd 0 -font {Helvetica 18} -padx 14 -pady 8
pack .nav.prev -side left -padx {4 0} -pady 4

# next — sapphire
button .nav.next -text "\u25B6" -command next \
    -bg $theme(sapphire) -fg #ffffff \
    -activebackground [brighten_color $theme(sapphire) 25] -activeforeground #ffffff \
    -relief flat -bd 0 -font {Helvetica 18} -padx 14 -pady 8
pack .nav.next -side right -padx {0 4} -pady 4

# counter — peach
label .nav.count -text "" -bg $theme(surface0) -fg $theme(peach) -font {Helvetica 14 bold}
pack .nav.count -side left -padx 12

# save — green
button .nav.save -text "Save" -command save \
    -bg $theme(green) -fg #000000 \
    -activebackground [brighten_color $theme(green) 25] -activeforeground #000000 \
    -relief flat -bd 0 -font {Helvetica 11 bold} -padx 12 -pady 8
pack .nav.save -side left -padx {0 12} -pady 4

# copy — mauve
button .nav.copy -text "Copy" -command copy_url \
    -bg $theme(mauve) -fg #000000 \
    -activebackground [brighten_color $theme(mauve) 25] -activeforeground #000000 \
    -relief flat -bd 0 -font {Helvetica 11 bold} -padx 12 -pady 8
pack .nav.copy -side left -pady 4

# info — subtext
label .nav.info -text "" -bg $theme(surface0) -fg $theme(subtext0) -font {Helvetica 10}
pack .nav.info -side left -padx 12

# ─── core ───────────────────────────────────────────

# Show a message on the canvas (does not touch .nav.info)
proc status {msg} {
    global theme
    update
    .cv delete all
    .cv create text [expr {[winfo width .cv] / 2}] [expr {[winfo height .cv] / 2}] \
        -text $msg -fill $theme(subtext0) -font {Helvetica 18}
}

# Fetch image URLs from r/wallpaper into ::urls
proc fetch {} {
    global urls
    status "Fetching..."
    if {[catch {
        set raw [exec sh -c {
            curl -sSLf \
                -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
                -H "Accept: application/json" \
                "https://old.reddit.com/r/wallpaper/top.json?t=week&limit=25" \
            | jq -r '.data.children[] | select(.data.post_hint == "image") | .data.url_overridden_by_dest'
        }]
        set urls {}
        foreach u [split [string trim $raw] "\n"] {
            if {$u ne ""} { lappend urls $u }
        }
    } err]} {
        status "Fetch failed — press r to retry"
        return 0
    }
    if {[llength $urls] == 0} {
        status "No wallpapers found — press r to retry"
        return 0
    }
    return 1
}

# Download url to cache, skip if already present and non-empty.
# Returns the local path.
proc download {url} {
    set name [file tail [lindex [split $url ?] 0]]
    set path [file join $::cache_dir $name]
    if {![file exists $path] || [file size $path] < 64} {
        catch {file delete $path}
        exec curl -sSLf -H "User-Agent: Mozilla/5.0" -o $path $url
    }
    return $path
}

# Render the image at ::idx
proc show {} {
    global urls idx photo info_text theme

    set n [llength $urls]
    if {$n == 0} return
    set idx [expr {($idx + $n) % $n}]
    set url [lindex $urls $idx]

    .nav.count configure -text "[expr {$idx + 1}] / $n"
    status "Loading..."

    # download
    if {[catch {set src [download $url]} err]} {
        status "Download failed"
        .nav.info configure -text $err -fg $theme(red)
        return
    }

    # native dimensions for info bar
    set dims ""
    catch {set dims [exec magick identify -format "%wx%h" $src]}
    set info_text "$dims   $url"
    .nav.info configure -text $info_text -fg $theme(subtext0)

    # scale to fit canvas
    update
    set cw [winfo width  .cv]
    set ch [winfo height .cv]
    set dst [file join $::cache_dir .scaled.png]
    if {[catch {exec magick $src -resize "${cw}x${ch}" $dst} err]} {
        status "Processing failed"
        .nav.info configure -text $err -fg $theme(red)
        return
    }

    # paint
    if {$photo ne "" && [lsearch [image names] $photo] >= 0} { image delete $photo }
    set photo [image create photo -file $dst]
    .cv delete all
    .cv create image [expr {$cw / 2}] [expr {$ch / 2}] -image $photo -anchor center

    wm title . "Porthole — [expr {$idx + 1}] / $n"

    # kick off a background download of the next image
    after 300 prefetch
}

# Start a background curl for the next image so it is warm in cache
proc prefetch {} {
    set n [llength $::urls]
    if {$n == 0} return
    set url [lindex $::urls [expr {($::idx + 1) % $n}]]
    set name [file tail [lindex [split $url ?] 0]]
    set path [file join $::cache_dir $name]
    if {![file exists $path]} {
        catch { exec curl -sSLf -H "User-Agent: Mozilla/5.0" -o $path $url & }
    }
}

proc next    {} { incr ::idx;    show }
proc prev    {} { incr ::idx -1; show }
proc refresh {} { set ::idx 0; if {[fetch]} show }

proc copy_url {} {
    global theme
    if {[llength $::urls] == 0} return
    clipboard clear
    clipboard append [lindex $::urls $::idx]
    .nav.info configure -text "Copied!" -fg $theme(green)
    after 1500 { .nav.info configure -text $::info_text -fg $::theme(subtext0) }
}

proc save {} {
    global theme
    if {[llength $::urls] == 0} return
    set url  [lindex $::urls $::idx]
    set name [file tail [lindex [split $url ?] 0]]
    set src  [file join $::cache_dir $name]
    if {[string tolower [file extension $name]] ne ".png"} {
        set name [file rootname $name].png
        set dst  [file join $::save_dir $name]
        if {[catch {exec magick $src $dst} err]} {
            .nav.info configure -text "Save failed: $err" -fg $theme(red)
            after 2000 { .nav.info configure -text $::info_text -fg $::theme(subtext0) }
            return
        }
    } else {
        set dst [file join $::save_dir $name]
        if {[catch {file copy -force $src $dst} err]} {
            .nav.info configure -text "Save failed: $err" -fg $theme(red)
            after 2000 { .nav.info configure -text $::info_text -fg $::theme(subtext0) }
            return
        }
    }
    .nav.info configure -text "Saved $name" -fg $theme(green)
    after 2000 { .nav.info configure -text $::info_text -fg $::theme(subtext0) }
}

# Debounced resize — re-scale current image after the window stops moving
proc on_resize {} {
    if {$::resize_timer ne ""} { after cancel $::resize_timer }
    set ::resize_timer [after 200 {
        set ::resize_timer {}
        if {[llength $::urls] > 0} show
    }]
}

# ─── bindings ───────────────────────────────────────
foreach w {. .cv} {
    bind $w <Right>      next
    bind $w <Left>       prev
    bind $w <n>          next
    bind $w <p>          prev
    bind $w <space>      next
    bind $w <Button-4>   prev
    bind $w <Button-5>   next
    bind $w <r>          refresh
    bind $w <c>          copy_url
    bind $w <s>          save
    bind $w <q>          exit
    bind $w <Escape>     exit
}
bind .cv <Configure> on_resize
bind .cv <Button-1>  { focus .cv }

# ─── go ─────────────────────────────────────────────
focus .cv
update
refresh
