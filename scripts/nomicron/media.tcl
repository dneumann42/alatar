# Media Integration - Spotify/Spotube controls and metadata

# Track currently downloading album art to prevent duplicate downloads
set ::downloading_art_urls [dict create]

proc get_spotify_metadata {} {
    set metadata {}
    if {[catch {exec playerctl -p spotube,spotify metadata --format "{{title}}\n{{artist}}\n{{album}}\n{{mpris:artUrl}}\n{{status}}" 2>@1} result]} {
        # Spotube/Spotify not running or no track
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
    catch {exec playerctl -p spotube,spotify play-pause}
}

proc spotify_next {} {
    catch {exec playerctl -p spotube,spotify next}
    after 500 update_spotify_info
}

proc spotify_previous {} {
    catch {exec playerctl -p spotube,spotify previous}
    after 500 update_spotify_info
}

proc spotify_focus {} {
    global script_dir
    set cmd [file join $script_dir "focus-spotube.tcl"]
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
        # Fallback: create a simple hash from the URL
        set hash 0
        foreach char [split $url ""] {
            scan $char %c ascii
            set hash [expr {($hash * 31 + $ascii) & 0x7FFFFFFF}]
        }
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
        $spotify_title_label configure -text "Media not playing"
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

                # Calculate subsample to fit 225x225
                set target 225
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

proc start_spotify_timer {} {
    update_spotify_info
    proc spotify_timer {} {
        update_spotify_info
        after 2000 spotify_timer
    }
    spotify_timer
}
