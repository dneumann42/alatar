#!/usr/bin/env tclsh
package require Tk

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir theme.tcl]
load_wallust_theme "pathedit"

ensure_single_instance "pathedit"

wm title . "Path Editor"
wm geometry . "800x600"

set path "$::env(HOME)/.zsh_paths.sh"
set all_paths {}
set search_var ""

proc parse_paths {path} {
    set paths {}
    if {[catch {open $path r} fp]} {
	puts "Error opening file: $fp"
    } else {
	set contents [read $fp]
	set lines [split $contents "\n"]
	foreach line $lines {
	    if {[string first "export PATH" $line] != 0} {
		continue
	    }
	    set pathItem [string range [lindex [split $line "="] 1] 1 end-7]
	    lappend paths $pathItem
	}
	close $fp
    }

    return $paths
}

proc populate_list_box {items} {
    .path_list_frame.lb delete 0 end
    foreach item $items {
	.path_list_frame.lb insert end $item
    }
}

proc apply_filter {args} {
    global search_var all_paths
    set query [string tolower [string trim $search_var]]
    if {$query eq ""} {
        populate_list_box $all_paths
        return
    }
    set filtered {}
    foreach path $all_paths {
        if {[string first $query [string tolower $path]] != -1} {
            lappend filtered $path
        }
    }
    populate_list_box $filtered
}

proc add_item {} {
    global all_paths
    set text [.input_frame.entry get]
    if {$text ne ""} {
        lappend all_paths $text
        .input_frame.entry delete 0 end
        apply_filter
    }
}

proc delete_item {} {
    global all_paths
    set sel [.path_list_frame.lb curselection]
    if {$sel ne ""} {
        set item [.path_list_frame.lb get $sel]
        set idx [lsearch -exact $all_paths $item]
        if {$idx != -1} {
            set all_paths [lreplace $all_paths $idx $idx]
        }
        apply_filter
    }
}

proc save_paths {} {
    global path all_paths

    if {[catch {open $path w} fp]} {
        tk_messageBox -type ok -icon error -message "Error saving: $fp"
        return
    }

    foreach item $all_paths {
        puts $fp "export PATH=\"${item}:\$PATH\""
    }
    close $fp
    tk_messageBox -type ok -icon info -message "Paths saved successfully!"
}

# Variable to track if we're currently editing
set editing_index -1

proc start_inline_edit {index} {
    global editing_index theme

    # Don't allow multiple edits at once
    if {$editing_index != -1} {
        return
    }

    set editing_index $index
    set text [.path_list_frame.lb get $index]

    # Get the bbox (bounding box) of the item
    set bbox [.path_list_frame.lb bbox $index]
    if {$bbox eq ""} {
        set editing_index -1
        return
    }

    lassign $bbox x y width height

    # Create an entry widget positioned over the listbox item
    entry .path_list_frame.edit_entry \
        -relief solid \
        -borderwidth 1 \
        -background $theme(base) \
        -foreground $theme(text) \
        -insertbackground $theme(text) \
        -selectbackground $theme(selected_bg) \
        -selectforeground $theme(selected_text)
    .path_list_frame.edit_entry insert 0 $text
    .path_list_frame.edit_entry selection range 0 end

    # Position the entry over the listbox item
    place .path_list_frame.edit_entry \
        -in .path_list_frame.lb \
        -x $x -y $y \
        -width [expr {[winfo width .path_list_frame.lb] - 20}] \
        -height $height

    focus .path_list_frame.edit_entry

    # Bind keys for saving/canceling
    bind .path_list_frame.edit_entry <Return> {finish_inline_edit 1}
    bind .path_list_frame.edit_entry <Escape> {finish_inline_edit 0}
    bind .path_list_frame.edit_entry <FocusOut> {finish_inline_edit 0}
}

proc finish_inline_edit {save} {
    global editing_index all_paths

    if {$editing_index == -1} {
        return
    }

    if {$save} {
        set new_text [.path_list_frame.edit_entry get]
        if {$new_text ne ""} {
            set old_text [.path_list_frame.lb get $editing_index]
            set idx [lsearch -exact $all_paths $old_text]
            if {$idx != -1} {
                set all_paths [lreplace $all_paths $idx $idx $new_text]
            }
            apply_filter
        }
    }

    destroy .path_list_frame.edit_entry
    set editing_index -1
    focus .path_list_frame.lb
}

proc cleanup_and_exit {} {
    exit
}

# Apply ttk theme
apply_ttk_theme
configure_root_window

# Create larger font for listbox
array set base_font [font actual TkDefaultFont]
set listbox_font [font create -family $base_font(-family) -size [expr {$base_font(-size) + 3}]]

# Create smaller button font
set button_font [font create -family $base_font(-family) -size [expr {$base_font(-size) - 1}]]
ttk::style configure Small.TButton -padding {2 1} -font $button_font

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

# Build the UI
ttk::frame .path_list_frame -padding 6
grid .path_list_frame -row 0 -column 0 -sticky nsew

grid columnconfigure .path_list_frame 0 -weight 1
grid rowconfigure .path_list_frame 1 -weight 1

# Search row
ttk::frame .path_list_frame.search_row
grid .path_list_frame.search_row -row 0 -column 0 -columnspan 2 -sticky ew -pady {0 4}

ttk::label .path_list_frame.search_row.label -text "Search:"
grid .path_list_frame.search_row.label -row 0 -column 0 -sticky w

ttk::entry .path_list_frame.search_row.entry -textvariable search_var
grid .path_list_frame.search_row.entry -row 0 -column 1 -sticky ew -padx {6 0}

grid columnconfigure .path_list_frame.search_row 1 -weight 1

# Path list box with scrollbar
listbox .path_list_frame.lb \
    -height 20 \
    -font $listbox_font \
    -background $theme(base) \
    -foreground $theme(text) \
    -selectbackground $theme(selected_bg) \
    -selectforeground $theme(selected_text) \
    -highlightbackground $theme(border) \
    -highlightcolor $theme(border_active) \
    -yscrollcommand {.path_list_frame.sb set}

ttk::scrollbar .path_list_frame.sb \
    -command {.path_list_frame.lb yview}

grid .path_list_frame.lb -row 1 -column 0 -sticky nsew
grid .path_list_frame.sb -row 1 -column 1 -sticky ns

# New path entry
ttk::frame .input_frame -padding {6 4}
grid .input_frame -row 1 -column 0 -sticky ew

grid columnconfigure .input_frame 0 -weight 1

# Entry widget
ttk::entry .input_frame.entry
grid .input_frame.entry -row 0 -column 0 -sticky ew -padx {0 4}

ttk::button .input_frame.add -text "Add" -command add_item -style Small.TButton
grid .input_frame.add -row 0 -column 1 -padx 2

ttk::button .input_frame.del -text "Delete" -command delete_item -style Small.TButton
grid .input_frame.del -row 0 -column 2 -padx 2

ttk::button .input_frame.save -text "Save" -command save_paths -style Small.TButton
grid .input_frame.save -row 0 -column 3 -padx 2

ttk::button .input_frame.quit -text "Quit" -command cleanup_and_exit -style Small.TButton
grid .input_frame.quit -row 0 -column 4 -padx {2 0}

# Bind double-click to start inline editing
bind .path_list_frame.lb <Double-Button-1> {
    set index [.path_list_frame.lb nearest %y]
    if {$index ne ""} {
        start_inline_edit $index
    }
}

# Bind Delete key to delete selected item
bind .path_list_frame.lb <Delete> delete_item
bind .path_list_frame.lb <BackSpace> delete_item

# Bind Enter key in the bottom entry to add item
bind .input_frame.entry <Return> add_item

# Bind Escape to exit
bind . <Escape> cleanup_and_exit
wm protocol . WM_DELETE_WINDOW cleanup_and_exit

# Load paths and set up search filter
set all_paths [parse_paths $path]
trace add variable search_var write apply_filter
populate_list_box $all_paths
