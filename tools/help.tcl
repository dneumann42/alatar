#!/usr/bin/env tclsh
package require Tk

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir theme.tcl]
load_wallust_theme "help"

ensure_single_instance "help"

proc read_lines {path} {
    set f [open $path r]
    set content [read $f]
    close $f
    return [split $content "\n"]
}

proc shlex_split {s} {
    set tokens {}
    set token ""
    set len [string length $s]
    set i 0
    set state "normal"
    while {$i < $len} {
        set ch [string index $s $i]
        if {$state eq "normal"} {
            if {[string is space -strict $ch]} {
                if {$token ne ""} {
                    lappend tokens $token
                    set token ""
                }
            } elseif {$ch eq "'"} {
                set state "single"
            } elseif {$ch eq "\""} {
                set state "double"
            } elseif {$ch eq "\\"} {
                incr i
                if {$i < $len} {
                    append token [string index $s $i]
                }
            } else {
                append token $ch
            }
        } elseif {$state eq "single"} {
            if {$ch eq "'"} {
                set state "normal"
            } else {
                append token $ch
            }
        } elseif {$state eq "double"} {
            if {$ch eq "\""} {
                set state "normal"
            } elseif {$ch eq "\\"} {
                incr i
                if {$i < $len} {
                    append token [string index $s $i]
                }
            } else {
                append token $ch
            }
        }
        incr i
    }
    if {$token ne ""} {
        lappend tokens $token
    }
    return $tokens
}

proc read_mod_binding {path} {
    if {![file exists $path]} {
        return "unknown"
    }
    set f [open $path r]
    while {[gets $f line] >= 0} {
        set stripped [string trim $line]
        if {[string first "set \$mod " $stripped] == 0} {
            set parts [shlex_split $stripped]
            if {[llength $parts] >= 3} {
                close $f
                return [lindex $parts 2]
            }
        }
    }
    close $f
    return "unknown"
}

proc friendly_mod_name {mod} {
    array set names {
        Mod4 Super
        Mod1 Alt
        Mod3 Mod3
        Mod2 Mod2
        Control Ctrl
        Shift Shift
    }
    if {[info exists names($mod)]} {
        return $names($mod)
    }
    return $mod
}

proc strip_arrow {text} {
    if {[string match "* ↑" $text] || [string match "* ↓" $text]} {
        return [string range $text 0 end-2]
    }
    return $text
}

proc sort_tree {tree columns column} {
    set data {}
    foreach item [$tree children {}] {
        set value [$tree set $item $column]
        lappend data [list [string tolower $value] $item]
    }
    set heading [$tree heading $column -text]
    set descending [string match "* ↓" $heading]
    if {$descending} {
        set sorted [lsort -dictionary -decreasing -index 0 $data]
    } else {
        set sorted [lsort -dictionary -index 0 $data]
    }
    set index 0
    foreach pair $sorted {
        set item [lindex $pair 1]
        $tree move $item {} $index
        incr index
    }
    foreach col $columns {
        set text [$tree heading $col -text]
        $tree heading $col -text [strip_arrow $text]
    }
    set base [strip_arrow [$tree heading $column -text]]
    set suffix [expr {$descending ? " ↑" : " ↓"}]
    $tree heading $column -text "${base}${suffix}"
}

proc populate_tree {rows} {
    global tree
    foreach item [$tree children {}] {
        $tree delete $item
    }
    set row_index 0
    foreach row $rows {
        set tag [expr {$row_index % 2 == 0 ? "row_even" : "row_odd"}]
        $tree insert {} end -values $row -tags $tag
        incr row_index
    }
}

proc apply_filter {args} {
    global search_var all_rows
    set query [string tolower [string trim $search_var]]
    if {$query eq ""} {
        populate_tree $all_rows
        return
    }
    set filtered {}
    foreach row $all_rows {
        set desc [string tolower [lindex $row 0]]
        set bind [string tolower [lindex $row 1]]
        set cmd [string tolower [lindex $row 2]]
        if {[string first $query $desc] != -1 || [string first $query $bind] != -1 || [string first $query $cmd] != -1} {
            lappend filtered $row
        }
    }
    populate_tree $filtered
}

set config_path [file normalize "~/.config/sway/config"]
set mod_binding [read_mod_binding $config_path]
set mod_friendly [friendly_mod_name $mod_binding]
set keybindings_path [file normalize "~/.config/sway/keybindings.conf"]
set lines [read_lines $keybindings_path]

proc cleanup_and_exit {} {
    exit
}

set bindings {}
set line_index 0
set line_count [llength $lines]
proc is_blank {line} {
    return [expr {[string trim $line] eq ""}]
}

while {$line_index < $line_count} {
    set line [lindex $lines $line_index]
    incr line_index
    if {![string match "#*" $line]} {
        continue
    }
    while {$line_index < $line_count && [is_blank [lindex $lines $line_index]]} {
        incr line_index
    }
    if {$line_index >= $line_count} {
        break
    }
    set next_line [string trimleft [lindex $lines $line_index]]
    if {[string first "bindsym" $next_line] != 0} {
        continue
    }
    while {$line_index < $line_count} {
        set current [lindex $lines $line_index]
        if {[is_blank $current]} {
            break
        }
        if {[string match "#*" [string trimleft $current]]} {
            break
        }
        set raw_line [string trim $current]
        incr line_index
        if {$raw_line eq ""} {
            continue
        }
        set tokens [shlex_split $raw_line]
        if {[llength $tokens] == 0} {
            continue
        }
        if {[lindex $tokens 0] ne "bindsym"} {
            continue
        }
        set idx 1
        while {$idx < [llength $tokens] && [string match "--*" [lindex $tokens $idx]]} {
            incr idx
        }
        if {$idx >= [llength $tokens]} {
            continue
        }
        set key [lindex $tokens $idx]
        set command_tokens [lrange $tokens [expr {$idx + 1}] end]
        set command [join $command_tokens " "]
        lappend bindings [list [string trim [string range $line 1 end]] $key $command]
    }
}

wm title . " DEV "
wm geometry . "1280x720"
bind . <Escape> cleanup_and_exit
wm protocol . WM_DELETE_WINDOW cleanup_and_exit

array set base_font [font actual TkDefaultFont]
set manual_search_button_font [font create -family $base_font(-family) \
    -size [expr {$base_font(-size) > 9 ? $base_font(-size) - 1 : $base_font(-size)}]]
ttk::style configure ManualSearch.TButton -padding {4 1} -font $manual_search_button_font

set keybindings_body_font [font create -family $base_font(-family) \
    -size [expr {$base_font(-size) + 1}]]
set keybindings_heading_font [font create -family $base_font(-family) \
    -size [expr {$base_font(-size) + 2}] -weight bold]

apply_ttk_theme
ttk::style configure Treeview -background $theme(base) -fieldbackground $theme(base) -foreground $theme(text) \
    -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border) \
    -font $keybindings_body_font -rowheight [expr {[font metrics $keybindings_body_font -linespace] + 8}]
ttk::style configure Treeview.Heading -background $theme(heading) -foreground $theme(text) \
    -borderwidth 0 -font $keybindings_heading_font -padding {6 4}
ttk::style map Treeview -background [list selected $theme(selected_bg) active $theme(active_bg)] -foreground [list selected $theme(selected_text) active $theme(text)]
ttk::style map Treeview.Heading -background [list active $theme(heading_active)] -foreground [list active $theme(text)]
configure_root_window

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

proc build_keybindings_tab {notebook mod_friendly mod_binding} {
    global bindings tree search_var all_rows theme
    set keybindings_tab [ttk::frame $notebook.keybindings]
    $notebook add $keybindings_tab -text "Keybindings"

    set frm [ttk::frame $keybindings_tab.frm -padding 10]
    grid $frm -row 0 -column 0 -sticky nsew
    grid columnconfigure $keybindings_tab 0 -weight 1
    grid rowconfigure $keybindings_tab 0 -weight 1

    set mod_label [ttk::label $frm.mod_label -text "\$mod = $mod_friendly ($mod_binding)"]
    grid $mod_label -row 0 -column 0 -sticky w -pady {0 6}

    set search_var ""
    set search_row [ttk::frame $frm.search_row]
    grid $search_row -row 1 -column 0 -columnspan 2 -sticky ew -pady {0 6}
    set search_label [ttk::label $search_row.search_label -text "Search"]
    grid $search_label -row 0 -column 0 -sticky w
    set search_entry [ttk::entry $search_row.search_entry -textvariable search_var -width 40]
    grid $search_entry -row 0 -column 1 -sticky ew -padx {8 0}
    grid columnconfigure $search_row 1 -weight 1

    set columns {description binding command}
    set tree [ttk::treeview $frm.tree -columns $columns -show headings]
    $tree tag configure row_even -background $theme(heading)
    $tree tag configure row_odd -background $theme(base)

    $tree heading description -text "Description" -command [list sort_tree $tree $columns description]
    $tree heading binding -text "Binding" -command [list sort_tree $tree $columns binding]
    $tree heading command -text "Executes" -command [list sort_tree $tree $columns command]
    $tree column description -width 280 -anchor w
    $tree column binding -width 160 -anchor w
    $tree column command -width 520 -anchor w

    set scroll_y [ttk::scrollbar $frm.scroll_y -orient vertical -command [list $tree yview]]
    set scroll_x [ttk::scrollbar $frm.scroll_x -orient horizontal -command [list $tree xview]]
    $tree configure -yscrollcommand [list $scroll_y set] -xscrollcommand [list $scroll_x set]

    grid $tree -row 2 -column 0 -sticky nsew
    grid $scroll_y -row 2 -column 1 -sticky ns
    grid $scroll_x -row 3 -column 0 -sticky ew

    grid columnconfigure $frm 0 -weight 1
    grid rowconfigure $frm 2 -weight 1

    set all_rows $bindings
    trace add variable search_var write apply_filter
    populate_tree $all_rows

    set btn_row [ttk::frame $frm.btn_row]
    grid $btn_row -row 4 -column 0 -columnspan 2 -pady {8 0} -sticky e
    ttk::button $btn_row.quit -text "Quit" -command cleanup_and_exit
    grid $btn_row.quit -row 0 -column 0

    return $keybindings_tab
}

proc list_man_files {} {
    set manpaths {}
    if {[catch {exec manpath} out] == 0} {
        set manpaths [split [string trim $out] ":"]
    } elseif {[info exists ::env(MANPATH)]} {
        set manpaths [split $::env(MANPATH) ":"]
    } else {
        set manpaths {~/.local/share/man /usr/local/share/man /usr/share/man}
    }

    set results {}
    foreach base $manpaths {
        if {$base eq ""} {
            continue
        }
        set base [file normalize $base]
        if {![file isdirectory $base]} {
            continue
        }
        foreach subdir [glob -nocomplain -types d -directory $base man*] {
            foreach path [glob -nocomplain -types f -directory $subdir {*.[0-9]*}] {
                lappend results $path
            }
        }
    }
    return [lsort -unique $results]
}

proc format_man_display_name {path} {
    set name [file tail $path]
    if {[string match "*.gz" $name]} {
        return [string range $name 0 end-3]
    }
    return $name
}

proc populate_manuals_list {items} {
    global manuals_list manuals_filtered
    set manuals_filtered $items
    $manuals_list delete 0 end
    foreach item $items {
        $manuals_list insert end [lindex $item 0]
    }
}

proc apply_manuals_filter {args} {
    global manuals_search_var manuals_items
    set query [string tolower [string trim $manuals_search_var]]
    if {$query eq ""} {
        populate_manuals_list $manuals_items
        return
    }
    set filtered {}
    foreach item $manuals_items {
        set name [string tolower [lindex $item 0]]
        if {[string first $query $name] != -1} {
            lappend filtered $item
        }
    }
    populate_manuals_list $filtered
}

proc man_page_name_from_path {path} {
    set name [file tail $path]
    if {[string match "*.gz" $name]} {
        set name [string range $name 0 end-3]
    }
    set parts [split $name "."]
    return [lindex $parts 0]
}

proc man_ref_from_path {path} {
    set name [file tail $path]
    if {[string match "*.gz" $name]} {
        set name [string range $name 0 end-3]
    }
    set parts [split $name "."]
    if {[llength $parts] < 2} {
        return [list "" ""]
    }
    set section [lindex $parts end]
    set page [join [lrange $parts 0 end-1] "."]
    return [list $page $section]
}

proc ensure_manual_fonts {} {
    global man_bold_font man_underline_font
    if {![info exists man_bold_font]} {
        array set base [font actual TkFixedFont]
        set man_bold_font [font create -family $base(-family) -size $base(-size) -weight bold]
        set man_underline_font [font create -family $base(-family) -size $base(-size) -underline 1]
    }
}

proc decode_man_overstrike {content} {
    set out ""
    set bold_ranges {}
    set underline_ranges {}
    set i 0
    set out_idx 0
    set len [string length $content]
    while {$i < $len} {
        set ch [string index $content $i]
        if {$i + 2 < $len && [string index $content [expr {$i + 1}]] eq "\b"} {
            set c1 $ch
            set c2 [string index $content [expr {$i + 2}]]
            set out_ch $c2
            set style ""
            if {$c1 eq $c2} {
                set style "bold"
            } elseif {$c1 eq "_"} {
                set style "underline"
            } elseif {$c2 eq "_"} {
                set style "underline"
                set out_ch $c1
            } else {
                set style "bold"
            }
            append out $out_ch
            if {$style eq "bold"} {
                lappend bold_ranges [list $out_idx [expr {$out_idx + 1}]]
            } elseif {$style eq "underline"} {
                lappend underline_ranges [list $out_idx [expr {$out_idx + 1}]]
            }
            incr out_idx
            incr i 3
            continue
        }
        append out $ch
        incr out_idx
        incr i
    }
    return [list $out $bold_ranges $underline_ranges]
}

proc apply_manual_highlighting {text_widget} {
    global theme
    ensure_manual_fonts
    global man_bold_font man_underline_font
    $text_widget tag configure man_header -foreground $theme(selected_text) -background $theme(heading) -font $man_bold_font
    $text_widget tag configure man_option -foreground $theme(border_active) -font $man_bold_font
    $text_widget tag configure man_code -foreground $theme(text) -background $theme(heading_active)
    $text_widget tag configure man_bold -font $man_bold_font -foreground $theme(text)
    $text_widget tag configure man_underline -font $man_underline_font -foreground $theme(text)
    $text_widget tag remove man_header 1.0 end
    $text_widget tag remove man_option 1.0 end
    $text_widget tag remove man_code 1.0 end
    $text_widget tag remove man_name 1.0 end

    set content [$text_widget get 1.0 end-1c]
    set lines [split $content "\n"]
    set line_no 1
    set section ""
    set code_sections {SYNOPSIS EXAMPLES EXAMPLE USAGE COMMANDS COMMAND}
    set option_sections {OPTIONS OPTION FLAGS FLAG}
    foreach line $lines {
        set trimmed [string trim $line]
        if {$trimmed ne "" && [regexp {^[A-Z0-9][A-Z0-9 ]+$} $trimmed]} {
            set section $trimmed
            $text_widget tag add man_header "${line_no}.0" "${line_no}.end"
            incr line_no
            continue
        }

        if {$section eq "NAME"} {
            set dash_index [string first " - " $line]
            if {$dash_index != -1} {
                $text_widget tag add man_bold "${line_no}.0" "${line_no}.${dash_index}"
            }
        }

        if {$trimmed ne "" && [lsearch -exact $code_sections $section] != -1} {
            $text_widget tag add man_code "${line_no}.0" "${line_no}.end"
        }

        set has_option_section [expr {[lsearch -exact $option_sections $section] != -1}]
        set has_option_tokens [expr {[regexp -- {(^|[[:space:]])-[A-Za-z0-9]} $line] == 1}]
        if {$has_option_section || $has_option_tokens} {
            set matches [regexp -all -inline -indices -- {--?[A-Za-z0-9][A-Za-z0-9_-]*((\[[^]]+\])|([=][^[:space:],;:)]+))?} $line]
            foreach match $matches {
                set start [lindex $match 0]
                set end [lindex $match 1]
                $text_widget tag add man_option "${line_no}.${start}" "${line_no}.[expr {$end + 1}]"
            }
        }
        incr line_no
    }
}

proc manual_link_tag_name {page section} {
    set raw [string tolower "${page}|${section}"]
    set hex [binary encode hex $raw]
    return "man_link_${hex}"
}

proc open_manual_by_ref {page section} {
    global manuals_index
    if {![info exists manuals_index]} {
        return
    }
    set key [string tolower "${page}|${section}"]
    if {![dict exists $manuals_index $key]} {
        return
    }
    set path [dict get $manuals_index $key]
    show_manual_by_path $path
}

proc open_manual_by_page {page} {
    global manuals_page_index
    if {![info exists manuals_page_index]} {
        return
    }
    set key [string tolower $page]
    if {![dict exists $manuals_page_index $key]} {
        return
    }
    set path [dict get $manuals_page_index $key]
    show_manual_by_path $path
}

proc apply_manual_links {text_widget} {
    global manuals_index manuals_page_index theme
    if {![info exists manuals_index] || ![info exists manuals_page_index]} {
        return
    }
    if {[info exists ::manual_link_tags($text_widget)]} {
        foreach tag $::manual_link_tags($text_widget) {
            $text_widget tag remove $tag 1.0 end
            $text_widget tag delete $tag
        }
    }
    set ::manual_link_tags($text_widget) {}
    set content [$text_widget get 1.0 end-1c]
    set start 0
    while {[regexp -indices -start $start -- {([A-Za-z0-9_+.-]+)\(([0-9][A-Za-z0-9]*)\)} $content match name section]} {
        set match_start [lindex $match 0]
        set match_end [lindex $match 1]
        set page [string range $content [lindex $name 0] [lindex $name 1]]
        set sect [string range $content [lindex $section 0] [lindex $section 1]]
        set key [string tolower "${page}|${sect}"]
        if {[dict exists $manuals_index $key]} {
            set tag [manual_link_tag_name $page $sect]
            if {[lsearch -exact $::manual_link_tags($text_widget) $tag] == -1} {
                $text_widget tag configure $tag -underline 1
                $text_widget tag bind $tag <Enter> [list $text_widget configure -cursor hand2]
                $text_widget tag bind $tag <Leave> [list $text_widget configure -cursor xterm]
                $text_widget tag bind $tag <Button-1> [list open_manual_by_ref $page $sect]
                lappend ::manual_link_tags($text_widget) $tag
            }
            $text_widget tag add $tag "1.0 + $match_start chars" "1.0 + [expr {$match_end + 1}] chars"
        }
        set start [expr {$match_end + 1}]
    }

    set start 0
    while {[regexp -indices -start $start -- {(<)?([A-Za-z0-9_+.-]+\.h)(>)?} $content match prefix header suffix]} {
        set match_start [lindex $match 0]
        set match_end [lindex $match 1]
        set page [string range $content [lindex $header 0] [lindex $header 1]]
        set key [string tolower $page]
        if {[dict exists $manuals_page_index $key]} {
            set tag [manual_link_tag_name $page ""]
            if {[lsearch -exact $::manual_link_tags($text_widget) $tag] == -1} {
                $text_widget tag configure $tag -underline 1
                $text_widget tag bind $tag <Enter> [list $text_widget configure -cursor hand2]
                $text_widget tag bind $tag <Leave> [list $text_widget configure -cursor xterm]
                $text_widget tag bind $tag <Button-1> [list open_manual_by_page $page]
                lappend ::manual_link_tags($text_widget) $tag
            }
            $text_widget tag add $tag "1.0 + $match_start chars" "1.0 + [expr {$match_end + 1}] chars"
        }
        set start [expr {$match_end + 1}]
    }
}

proc man_section_rank {section} {
    if {$section eq "0p"} {
        return 0
    }
    if {[regexp {^3} $section]} {
        return 1
    }
    if {[regexp {^2} $section]} {
        return 2
    }
    if {[regexp {^1} $section]} {
        return 3
    }
    if {[regexp {^0} $section]} {
        return 4
    }
    if {[regexp {^5} $section]} {
        return 5
    }
    if {[regexp {^7} $section]} {
        return 6
    }
    if {[regexp {^8} $section]} {
        return 7
    }
    return 99
}

proc highlight_text_matches {text_widget pattern tag} {
    $text_widget tag remove $tag 1.0 end
    if {$pattern eq ""} {
        return ""
    }
    set idx 1.0
    set first ""
    while {1} {
        set pos [$text_widget search -nocase -count count -- $pattern $idx end]
        if {$pos eq ""} {
            break
        }
        set endpos [$text_widget index "$pos + $count chars"]
        $text_widget tag add $tag $pos $endpos
        if {$first eq ""} {
            set first $pos
        }
        set idx $endpos
    }
    return $first
}

proc apply_manual_content_search {args} {
    global manuals_text manuals_tldr_text manuals_content_search_var theme
    set pattern [string trim $manuals_content_search_var]
    foreach widget_name {manuals_text manuals_tldr_text} {
        if {![info exists $widget_name]} {
            continue
        }
        set widget [set $widget_name]
        if {$widget eq ""} {
            continue
        }
        $widget tag configure manual_search_hit -background $theme(selected_bg) -foreground $theme(selected_text)
        $widget tag configure manual_search_current -background $theme(heading_active) -foreground $theme(text)
        set prev_state [$widget cget -state]
        $widget configure -state normal
        set first_match [highlight_text_matches $widget $pattern manual_search_hit]
        $widget tag remove manual_search_current 1.0 end
        $widget tag raise manual_search_hit
        if {$first_match ne ""} {
            $widget see $first_match
            set match_len [string length $pattern]
            $widget tag add manual_search_current $first_match "$first_match + $match_len chars"
        }
        $widget configure -state $prev_state
        if {$first_match ne ""} {
            set ::manual_search_last($widget) $first_match
        } else {
            set ::manual_search_last($widget) ""
        }
    }
}

proc manual_search_get_widgets {} {
    global manuals_text manuals_tldr_text
    set widgets {}
    if {[info exists manuals_text]} {
        lappend widgets $manuals_text
    }
    if {[info exists manuals_tldr_text]} {
        lappend widgets $manuals_tldr_text
    }
    return $widgets
}

proc manual_search_pick_widgets {} {
    set focus_widget [focus]
    set widgets [manual_search_get_widgets]
    if {[lsearch -exact $widgets $focus_widget] != -1} {
        set ordered [list $focus_widget]
        foreach widget $widgets {
            if {$widget ne $focus_widget} {
                lappend ordered $widget
            }
        }
        return $ordered
    }
    return $widgets
}

proc manual_search_jump {direction} {
    global manuals_content_search_var theme
    set pattern [string trim $manuals_content_search_var]
    if {$pattern eq ""} {
        return
    }
    foreach widget [manual_search_pick_widgets] {
        if {$widget eq ""} {
            continue
        }
        set prev_state [$widget cget -state]
        $widget configure -state normal
        $widget tag configure manual_search_current -background $theme(heading_active) -foreground $theme(text)
        if {[llength [$widget tag ranges manual_search_hit]] == 0} {
            set first_match [highlight_text_matches $widget $pattern manual_search_hit]
            if {$first_match ne ""} {
                set ::manual_search_last($widget) $first_match
            }
        }
        set last ""
        if {[info exists ::manual_search_last($widget)]} {
            set last $::manual_search_last($widget)
        }
        if {$direction eq "prev"} {
            if {$last eq ""} {
                set start end
            } else {
                set start $last
            }
            set pos [$widget search -nocase -backwards -count count -- $pattern $start 1.0]
            if {$pos eq ""} {
                set pos [$widget search -nocase -backwards -count count -- $pattern end 1.0]
            }
        } else {
            if {$last eq ""} {
                set start 1.0
            } else {
                set start "$last + 1 chars"
            }
            set pos [$widget search -nocase -count count -- $pattern $start end]
            if {$pos eq ""} {
                set pos [$widget search -nocase -count count -- $pattern 1.0 end]
            }
        }
        if {$pos ne ""} {
            set ::manual_search_last($widget) $pos
            $widget tag remove manual_search_current 1.0 end
            $widget tag add manual_search_current $pos "$pos + $count chars"
            $widget tag raise manual_search_current
            $widget see $pos
            $widget configure -state $prev_state
            return
        }
        $widget configure -state $prev_state
    }
}

proc ansi_256_color {idx} {
    set base {
        "#000000" "#ff5555" "#50fa7b" "#f1fa8c" "#bd93f9" "#ff79c6" "#8be9fd" "#f8f8f2"
        "#6272a4" "#ff6e6e" "#69ff94" "#ffffa5" "#d6acff" "#ff92df" "#a4ffff" "#ffffff"
    }
    if {$idx < 16} {
        return [lindex $base $idx]
    }
    if {$idx >= 16 && $idx <= 231} {
        set n [expr {$idx - 16}]
        set r [expr {$n / 36}]
        set g [expr {($n % 36) / 6}]
        set b [expr {$n % 6}]
        set steps {0 95 135 175 215 255}
        return [format "#%02x%02x%02x" [lindex $steps $r] [lindex $steps $g] [lindex $steps $b]]
    }
    if {$idx >= 232 && $idx <= 255} {
        set v [expr {8 + 10 * ($idx - 232)}]
        return [format "#%02x%02x%02x" $v $v $v]
    }
    return ""
}

proc ansi_tag_name {fg bg bold} {
    set fg_id [expr {$fg eq "" ? "none" : [string map {# {}} $fg]}]
    set bg_id [expr {$bg eq "" ? "none" : [string map {# {}} $bg]}]
    return "ansi_fg_${fg_id}_bg_${bg_id}_b${bold}"
}

proc parse_ansi_segments {text} {
    set segments {}
    set plain ""
    set i 0
    set out_idx 0
    set len [string length $text]
    set current_fg ""
    set current_bg ""
    set bold 0
    set run_start 0
    set run_fg ""
    set run_bg ""
    set run_bold 0

    while {$i < $len} {
        set ch [string index $text $i]
        if {[string equal $ch "\x1b"] && $i + 1 < $len && [string equal [string index $text [expr {$i + 1}]] {[}]} {
            set m [string first "m" $text $i]
            if {$m == -1} {
                break
            }
            set seq [string range $text [expr {$i + 2}] [expr {$m - 1}]]
            if {$seq eq ""} {
                set seq "0"
            }
            set codes [split $seq ";"]
            set idx 0
            while {$idx < [llength $codes]} {
                set code [lindex $codes $idx]
                if {$code eq ""} {
                    incr idx
                    continue
                }
                if {$code eq "0"} {
                    set current_fg ""
                    set current_bg ""
                    set bold 0
                } elseif {$code eq "39"} {
                    set current_fg ""
                } elseif {$code eq "49"} {
                    set current_bg ""
                } elseif {$code eq "1"} {
                    set bold 1
                } elseif {$code eq "22"} {
                    set bold 0
                } elseif {$code eq "38" || $code eq "48"} {
                    set is_fg [expr {$code eq "38"}]
                    set mode [lindex $codes [expr {$idx + 1}]]
                    if {$mode eq "5"} {
                        set color_idx [lindex $codes [expr {$idx + 2}]]
                        if {$color_idx ne ""} {
                            if {$is_fg} {
                                set current_fg [ansi_256_color $color_idx]
                            } else {
                                set current_bg [ansi_256_color $color_idx]
                            }
                        }
                        incr idx 2
                    } elseif {$mode eq "2"} {
                        set r [lindex $codes [expr {$idx + 2}]]
                        set g [lindex $codes [expr {$idx + 3}]]
                        set b [lindex $codes [expr {$idx + 4}]]
                        if {$r ne "" && $g ne "" && $b ne ""} {
                            set color [format "#%02x%02x%02x" $r $g $b]
                            if {$is_fg} {
                                set current_fg $color
                            } else {
                                set current_bg $color
                            }
                        }
                        incr idx 4
                    }
                } elseif {[regexp {^3[0-7]$} $code]} {
                    set base [expr {$code - 30}]
                    set current_fg [ansi_256_color $base]
                } elseif {[regexp {^9[0-7]$} $code]} {
                    set base [expr {$code - 90 + 8}]
                    set current_fg [ansi_256_color $base]
                } elseif {[regexp {^4[0-7]$} $code]} {
                    set base [expr {$code - 40}]
                    set current_bg [ansi_256_color $base]
                } elseif {[regexp {^10[0-7]$} $code]} {
                    set base [expr {$code - 100 + 8}]
                    set current_bg [ansi_256_color $base]
                }
                incr idx
            }
            set i [expr {$m + 1}]
            continue
        }

        append plain $ch

        if {$out_idx == $run_start} {
            set run_fg $current_fg
            set run_bg $current_bg
            set run_bold $bold
        } elseif {$current_fg ne $run_fg || $current_bg ne $run_bg || $bold != $run_bold} {
            if {$run_fg ne "" || $run_bg ne "" || $run_bold} {
                lappend segments [list $run_start $out_idx [ansi_tag_name $run_fg $run_bg $run_bold]]
            }
            set run_start $out_idx
            set run_fg $current_fg
            set run_bg $current_bg
            set run_bold $bold
        }

        incr out_idx
        incr i
    }

    if {$run_fg ne "" || $run_bg ne "" || $run_bold} {
        lappend segments [list $run_start $out_idx [ansi_tag_name $run_fg $run_bg $run_bold]]
    }

    return [list $plain $segments]
}

proc man_ansi_output {path} {
    set output ""
    if {[catch {exec sh -c {BAT_THEME="Monokai Extended" BAT_PAGER=never MANROFFOPT=-c man -P cat -l "$1" | col -bx | bat -l man -p --color=always} sh $path} output] == 0 && [string first "\x1b" $output] != -1} {
        return $output
    }
    return ""
}

proc apply_ansi_segments {text_widget plain segments} {
    ensure_manual_fonts
    global man_bold_font
    $text_widget delete 1.0 end
    $text_widget insert end $plain
    foreach seg $segments {
        set start [lindex $seg 0]
        set end [lindex $seg 1]
        set tag [lindex $seg 2]
        set tag_key "${text_widget}|${tag}"
        if {![info exists ::ansi_tag_configured($tag_key)]} {
            set fg ""
            set bg ""
            set bold 0
            if {[regexp {^ansi_fg_([0-9A-Fa-f]+|none)_bg_([0-9A-Fa-f]+|none)_b([01])$} $tag -> fg_id bg_id bold]} {
                if {$fg_id ne "none"} {
                    set fg "#$fg_id"
                }
                if {$bg_id ne "none"} {
                    set bg "#$bg_id"
                }
                set opts {}
                if {$fg ne ""} {
                    lappend opts -foreground $fg
                }
                if {$bg ne ""} {
                    lappend opts -background $bg
                }
                if {$bold} {
                    lappend opts -font $man_bold_font
                }
                if {[llength $opts] > 0} {
                    $text_widget tag configure $tag {*}$opts
                }
            }
            set ::ansi_tag_configured($tag_key) 1
        }
        $text_widget tag add $tag "1.0 + $start chars" "1.0 + $end chars"
    }
}

proc show_manual_by_path {path} {
    global manuals_text manuals_tldr_text
    if {$path eq ""} {
        return
    }
    set output ""
    set output [man_ansi_output $path]
    if {$output eq "" && [catch {exec man -P cat -l $path} output] != 0} {
        set output "Failed to open manual: $path\n\n$output"
    }
    $manuals_text configure -state normal
    if {[string first "\x1b" $output] != -1} {
        set parsed [parse_ansi_segments $output]
        set plain [lindex $parsed 0]
        set segments [lindex $parsed 1]
        apply_ansi_segments $manuals_text $plain $segments
    } else {
        set decoded [decode_man_overstrike $output]
        set plain [lindex $decoded 0]
        $manuals_text delete 1.0 end
        $manuals_text insert end $plain
    }
    apply_manual_highlighting $manuals_text
    apply_manual_links $manuals_text
    $manuals_text configure -state disabled

    set page [man_page_name_from_path $path]
    set tldr_output ""
    if {$page ne ""} {
        if {[catch {exec tldr --color=always $page} tldr_output] != 0} {
            set tldr_output "No tldr entry for: $page\n\n$tldr_output"
        }
    }
    $manuals_tldr_text configure -state normal
    if {[string first "\x1b" $tldr_output] != -1} {
        set parsed [parse_ansi_segments $tldr_output]
        set plain [lindex $parsed 0]
        set segments [lindex $parsed 1]
        apply_ansi_segments $manuals_tldr_text $plain $segments
    } else {
        $manuals_tldr_text delete 1.0 end
        $manuals_tldr_text insert end $tldr_output
    }
    $manuals_tldr_text configure -state disabled
    apply_manual_content_search
}

proc show_manual {args} {
    global manuals_list manuals_filtered
    set selection [$manuals_list curselection]
    if {[llength $selection] == 0} {
        return
    }
    set index [lindex $selection 0]
    set path [lindex [lindex $manuals_filtered $index] 1]
    show_manual_by_path $path
}

proc build_manuals_tab {notebook} {
    global manuals_list manuals_text manuals_tldr_text manuals_items manuals_filtered manuals_search_var manuals_content_search_var theme manuals_index manuals_page_index
    set manuals_tab [ttk::frame $notebook.manuals]
    $notebook add $manuals_tab -text "Manuals"

    set manuals_frame [ttk::frame $manuals_tab.frame -padding 10]
    grid $manuals_frame -row 0 -column 0 -sticky nsew
    
    grid columnconfigure $manuals_tab 0 -weight 1
    grid rowconfigure $manuals_tab 0 -weight 1
    
    set manuals_label [ttk::label $manuals_frame.label -text "Manuals List"]
    grid $manuals_label -row 0 -column 0 -sticky w

    set manuals_search_var ""
    set manuals_search_row [ttk::frame $manuals_frame.search_row]
    grid $manuals_search_row -row 1 -column 0 -columnspan 2 -sticky ew -pady {6 0}
    set manuals_search_label [ttk::label $manuals_search_row.search_label -text "Search"]
    grid $manuals_search_label -row 0 -column 0 -sticky w
    set manuals_search_entry [ttk::entry $manuals_search_row.search_entry -textvariable manuals_search_var -width 28]
    grid $manuals_search_entry -row 0 -column 1 -sticky ew -padx {8 0}
    grid columnconfigure $manuals_search_row 1 -weight 1

    set manuals_list [listbox $manuals_frame.list -height 20 -exportselection 0 \
        -background $theme(base) -foreground $theme(text) \
        -selectbackground $theme(selected_bg) -selectforeground $theme(selected_text) \
        -highlightbackground $theme(border) -highlightcolor $theme(border_active)]
    set manuals_scroll [ttk::scrollbar $manuals_frame.scroll -orient vertical -command [list $manuals_list yview]]
    $manuals_list configure -yscrollcommand [list $manuals_scroll set]
    grid $manuals_list -row 2 -column 0 -sticky nsew -pady {6 0}
    grid $manuals_scroll -row 2 -column 1 -sticky ns -pady {6 0}
    grid columnconfigure $manuals_frame 0 -weight 1
    grid rowconfigure $manuals_frame 2 -weight 1

    set manuals_items {}
    set manuals_index [dict create]
    set manuals_page_index [dict create]
    set manuals_page_rank [dict create]
    foreach path [list_man_files] {
        lappend manuals_items [list [format_man_display_name $path] $path]
        set ref [man_ref_from_path $path]
        set page [lindex $ref 0]
        set section [lindex $ref 1]
        if {$page ne "" && $section ne ""} {
            dict set manuals_index [string tolower "${page}|${section}"] $path
            set page_key [string tolower $page]
            set rank [man_section_rank $section]
            if {![dict exists $manuals_page_rank $page_key] || $rank < [dict get $manuals_page_rank $page_key]} {
                dict set manuals_page_rank $page_key $rank
                dict set manuals_page_index $page_key $path
            }
        }
    }
    populate_manuals_list $manuals_items
    bind $manuals_list <<ListboxSelect>> show_manual
    trace add variable manuals_search_var write apply_manuals_filter

    ttk::label $manuals_frame.label2 -text "Manuals contents"
    grid $manuals_frame.label2 -row 0 -column 2 -sticky w

    set manuals_content_search_var ""
    set manuals_content_search_row [ttk::frame $manuals_frame.content_search_row]
    grid $manuals_content_search_row -row 1 -column 2 -columnspan 2 -sticky ew -pady {6 0}
    set manuals_content_search_label [ttk::label $manuals_content_search_row.search_label -text "Find in page"]
    grid $manuals_content_search_label -row 0 -column 0 -sticky w
    set manuals_content_search_entry [ttk::entry $manuals_content_search_row.search_entry -textvariable manuals_content_search_var -width 28]
    grid $manuals_content_search_entry -row 0 -column 1 -sticky ew -padx {8 0}
    set manuals_content_search_prev [ttk::button $manuals_content_search_row.search_prev -text "<" -width 2 \
        -style ManualSearch.TButton -command [list manual_search_jump prev]]
    grid $manuals_content_search_prev -row 0 -column 2 -sticky w -padx {8 0}
    set manuals_content_search_next [ttk::button $manuals_content_search_row.search_next -text ">" -width 2 \
        -style ManualSearch.TButton -command [list manual_search_jump next]]
    grid $manuals_content_search_next -row 0 -column 3 -sticky w -padx {6 0}
    grid columnconfigure $manuals_content_search_row 1 -weight 1
    trace add variable manuals_content_search_var write apply_manual_content_search

    set manuals_pane [ttk::panedwindow $manuals_frame.pane -orient vertical]
    grid $manuals_pane -row 2 -column 2 -columnspan 2 -sticky nsew -padx {12 0} -pady {6 0}

    set manuals_man_pane [ttk::frame $manuals_frame.man_pane]
    set manuals_tldr_pane [ttk::frame $manuals_frame.tldr_pane]
    $manuals_pane add $manuals_man_pane -weight 3
    $manuals_pane add $manuals_tldr_pane -weight 2

    set manuals_text [text $manuals_man_pane.text -wrap word -height 12 -font TkFixedFont \
        -background $theme(base) -foreground $theme(text) \
        -selectbackground $theme(selected_bg) -selectforeground $theme(selected_text) \
        -highlightbackground $theme(border) -highlightcolor $theme(border_active) \
        -insertbackground $theme(text)]
    set manuals_text_scroll [ttk::scrollbar $manuals_man_pane.text_scroll -orient vertical -command [list $manuals_text yview]]
    $manuals_text configure -yscrollcommand [list $manuals_text_scroll set] -state disabled
    grid $manuals_text -row 0 -column 0 -sticky nsew
    grid $manuals_text_scroll -row 0 -column 1 -sticky ns
    grid columnconfigure $manuals_man_pane 0 -weight 1
    grid rowconfigure $manuals_man_pane 0 -weight 1

    ttk::label $manuals_tldr_pane.label -text "TLDR"
    grid $manuals_tldr_pane.label -row 0 -column 0 -sticky w -pady {0 4}
    set manuals_tldr_text [text $manuals_tldr_pane.text -wrap word -height 8 -font TkFixedFont \
        -background $theme(base) -foreground $theme(text) \
        -selectbackground $theme(selected_bg) -selectforeground $theme(selected_text) \
        -highlightbackground $theme(border) -highlightcolor $theme(border_active) \
        -insertbackground $theme(text)]
    set manuals_tldr_text_scroll [ttk::scrollbar $manuals_tldr_pane.text_scroll -orient vertical -command [list $manuals_tldr_text yview]]
    $manuals_tldr_text configure -yscrollcommand [list $manuals_tldr_text_scroll set] -state disabled
    grid $manuals_tldr_text -row 1 -column 0 -sticky nsew
    grid $manuals_tldr_text_scroll -row 1 -column 1 -sticky ns
    grid columnconfigure $manuals_tldr_pane 0 -weight 1
    grid rowconfigure $manuals_tldr_pane 1 -weight 1

    grid columnconfigure $manuals_frame 1 -weight 0
    grid columnconfigure $manuals_frame 2 -weight 1
    grid columnconfigure $manuals_frame 3 -weight 0

    return $manuals_tab
}

set notebook [ttk::notebook .notebook]
grid $notebook -row 0 -column 0 -sticky nsew
set keybindings_tab [build_keybindings_tab $notebook $mod_friendly $mod_binding]
set manuals_tab [build_manuals_tab $notebook]

# Select tab based on command line argument
if {[llength $argv] > 0} {
    set tab_arg [string tolower [lindex $argv 0]]
    if {$tab_arg eq "manuals"} {
        $notebook select $manuals_tab
    } elseif {$tab_arg eq "keybindings"} {
        $notebook select $keybindings_tab
    }
}
