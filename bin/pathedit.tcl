#!/usr/bin/env tclsh
package require Tk

wm title . "Hello, DEV World"

set path "$::env(HOME)/.zsh_paths.sh"

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

# Build the UI
frame .path_list_frame
pack .path_list_frame \
    -fill both \
    -expand 1 \
    -padx 10 \
    -pady 10

# Path list box with scrollbar
listbox .path_list_frame.lb \
    -height 10 \
    -width 40 \
    -yscrollcommand {.path_list_frame.sb set}

scrollbar .path_list_frame.sb \
    -command {.path_list_frame.lb yview}

pack .path_list_frame.sb -side right -fill y
pack .path_list_frame.lb -side left -fill both -expand 1

# New path entry
frame .input_frame
pack .input_frame -fill x -padx 10 -pady 5

# Entry widget
entry .input_frame.entry -width 30
pack .input_frame.entry -side left -padx 5

button .input_frame.add -text "Add" -command add_item
pack .input_frame.add -side left -padx 5

button .input_frame.del -text "Delete" -command delete_item
pack .input_frame.del -side left -padx 5

button .input_frame.save -text "Save" -command save_paths
pack .input_frame.save -side right -padx 5

proc populate_list_box {items} {
    foreach item $items {
	.path_list_frame.lb insert end $item
    }
}

proc add_item {} {
    set text [.input_frame.entry get]
    if {$text ne ""} {
        .path_list_frame.lb insert end $text
        .input_frame.entry delete 0 end
    }
}

proc delete_item {} {
    set sel [.path_list_frame.lb curselection]
    if {$sel ne ""} {
        .path_list_frame.lb delete $sel
    }
}

proc save_paths {} {
    global path
    set items [.path_list_frame.lb get 0 end]

    if {[catch {open $path w} fp]} {
        tk_messageBox -type ok -icon error -message "Error saving: $fp"
        return
    }

    foreach item $items {
        puts $fp "export PATH=\"${item}:\$PATH\""
    }
    close $fp
    tk_messageBox -type ok -icon info -message "Paths saved successfully!"
}

# Variable to track if we're currently editing
set editing_index -1

proc start_inline_edit {index} {
    global editing_index

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
        -borderwidth 1
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
    global editing_index

    if {$editing_index == -1} {
        return
    }

    if {$save} {
        set new_text [.path_list_frame.edit_entry get]
        if {$new_text ne ""} {
            .path_list_frame.lb delete $editing_index
            .path_list_frame.lb insert $editing_index $new_text
            .path_list_frame.lb selection clear 0 end
            .path_list_frame.lb selection set $editing_index
        }
    }

    destroy .path_list_frame.edit_entry
    set editing_index -1
    focus .path_list_frame.lb
}

# Bind double-click to start inline editing
bind .path_list_frame.lb <Double-Button-1> {
    set index [.path_list_frame.lb nearest %y]
    if {$index ne ""} {
        start_inline_edit $index
    }
}

# Bind Enter key in the bottom entry to add item
bind .input_frame.entry <Return> add_item

set paths [parse_paths $path]
populate_list_box $paths
puts $paths 

