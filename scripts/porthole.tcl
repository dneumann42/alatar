#!/usr/bin/env wish

# Porthole — Wallpaper viewer
#   ← →  / n p / scroll    navigate
#   space                   next
#   c                       copy URL to clipboard
#   r                       refresh from Reddit
#   q / Esc                 quit

package require Tk

# ─── config ─────────────────────────────────────────
set ::cache_dir [file tildeexpand ~/.local/cache/porthole]
file mkdir $::cache_dir

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

canvas .cv -bg #0a0a0a -highlightthickness 0
pack .cv -fill both -expand 1

frame .nav -bg #111111
pack .nav -fill x -side bottom

button .nav.prev -text "\u25C0" -command prev \
    -bg #111111 -fg #cccccc -activebackground #252525 -activeforeground #ffffff \
    -relief flat -bd 0 -font {Helvetica 18} -padx 14 -pady 8
pack .nav.prev -side left

button .nav.next -text "\u25B6" -command next \
    -bg #111111 -fg #cccccc -activebackground #252525 -activeforeground #ffffff \
    -relief flat -bd 0 -font {Helvetica 18} -padx 14 -pady 8
pack .nav.next -side right

label .nav.count -text "" -bg #111111 -fg #eeeeee -font {Helvetica 14}
pack .nav.count -side left -padx 14

label .nav.info -text "" -bg #111111 -fg #555555 -font {Helvetica 10}
pack .nav.info -side left

# ─── core ───────────────────────────────────────────

# Show a message on the canvas (does not touch .nav.info)
proc status {msg} {
    update
    .cv delete all
    .cv create text [expr {[winfo width .cv] / 2}] [expr {[winfo height .cv] / 2}] \
        -text $msg -fill #444444 -font {Helvetica 18}
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
    global urls idx photo info_text

    set n [llength $urls]
    if {$n == 0} return
    set idx [expr {($idx + $n) % $n}]
    set url [lindex $urls $idx]

    .nav.count configure -text "[expr {$idx + 1}] / $n"
    status "Loading..."

    # download
    if {[catch {set src [download $url]} err]} {
        status "Download failed"
        .nav.info configure -text $err
        return
    }

    # native dimensions for info bar
    set dims ""
    catch {set dims [exec magick identify -format "%wx%h" $src]}
    set info_text "$dims   $url"
    .nav.info configure -text $info_text

    # scale to fit canvas
    update
    set cw [winfo width  .cv]
    set ch [winfo height .cv]
    set dst [file join $::cache_dir .scaled.png]
    if {[catch {exec magick $src -resize "${cw}x${ch}" $dst} err]} {
        status "Processing failed"
        .nav.info configure -text $err
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
    if {[llength $::urls] == 0} return
    clipboard clear
    clipboard append [lindex $::urls $::idx]
    .nav.info configure -text "Copied!"
    after 1500 { .nav.info configure -text $::info_text }
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
    bind $w <q>          exit
    bind $w <Escape>     exit
}
bind .cv <Configure> on_resize
bind .cv <Button-1>  { focus .cv }

# ─── go ─────────────────────────────────────────────
focus .cv
update
refresh
