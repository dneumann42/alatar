#!/usr/bin/env tclsh
package require Tk

array set theme {
    base #1e1e1e
    text #e6e6e6
    heading #2a2a2a
    heading_active #333333
    selected_bg #3a3a3a
    active_bg #252525
    button_bg #2a2a2a
    button_text #e6e6e6
    selected_text #ffffff
}

set theme_file [file normalize "~/.config/wallust/help.tcl"]
if {[file exists $theme_file]} {
    catch {source $theme_file}
}

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
wm geometry . "900x600"
bind . <Escape> cleanup_and_exit
wm protocol . WM_DELETE_WINDOW cleanup_and_exit

ttk::style theme use clam
ttk::style configure TFrame -background $theme(base)
ttk::style configure TLabel -background $theme(base) -foreground $theme(text)
ttk::style configure Treeview -background $theme(base) -fieldbackground $theme(base) -foreground $theme(text)
ttk::style configure Treeview.Heading -background $theme(heading) -foreground $theme(text)
ttk::style map Treeview -background [list selected $theme(selected_bg) active $theme(active_bg)] -foreground [list selected $theme(selected_text) active $theme(text)]
ttk::style map Treeview.Heading -background [list active $theme(heading_active)] -foreground [list active $theme(text)]
ttk::style configure TButton -background $theme(button_bg) -foreground $theme(button_text)

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

set notebook [ttk::notebook .notebook]
grid $notebook -row 0 -column 0 -sticky nsew

set keybindings_tab [ttk::frame $notebook.keybindings]
set manuals_tab [ttk::frame $notebook.manuals]
$notebook add $keybindings_tab -text "Keybindings"
$notebook add $manuals_tab -text "Manuals"

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

proc populate_tree {rows} {
    global tree
    foreach item [$tree children {}] {
        $tree delete $item
    }
    foreach row $rows {
        $tree insert {} end -values $row
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

trace add variable search_var write apply_filter
populate_tree $all_rows

set btn_row [ttk::frame $frm.btn_row]
grid $btn_row -row 4 -column 0 -columnspan 2 -pady {8 0} -sticky e
ttk::button $btn_row.quit -text "Quit" -command cleanup_and_exit
grid $btn_row.quit -row 0 -column 0

set manuals_frame [ttk::frame $manuals_tab.frame -padding 10]
grid $manuals_frame -row 0 -column 0 -sticky nsew
grid columnconfigure $manuals_tab 0 -weight 1
grid rowconfigure $manuals_tab 0 -weight 1
ttk::label $manuals_frame.label -text "Manuals"
grid $manuals_frame.label -row 0 -column 0 -sticky w
