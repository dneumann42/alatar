#!/usr/bin/env tclsh

array set theme {
    base #000000
    surface0 #0f0f0f
    text #e6e6e6
    heading #1a1a1a
    heading_active #2a2a2a
    selected_bg #2a2a2a
    active_bg #151515
    button_bg #1a1a1a
    button_text #e6e6e6
    selected_text #ffffff
    tab_bg #0a0a0a
    tab_active_bg #1a1a1a
    tab_selected_bg #2a2a2a
    tab_text #cfcfcf
    tab_selected_text #ffffff
    entry_bg #1a1a1a
    entry_text #e6e6e6
    border #2a2a2a
    border_active #4a4a4a
    scrollbar_trough #0a0a0a
    scrollbar_thumb #2a2a2a
    scrollbar_thumb_active #3a3a3a
    scrollbar_arrow #cfcfcf
    accent1 #cc6666
    accent2 #b5bd68
    accent3 #f0c674
    accent4 #81a2be
}

proc load_wallust_theme {{config_name ""}} {
    global theme
    if {$config_name eq ""} {
        set config_name "theme"
    }
    set theme_file [file normalize "~/.config/wallust/${config_name}.tcl"]
    if {[file exists $theme_file]} {
        catch {source $theme_file}
    }
}

proc apply_ttk_theme {} {
    global theme
    ttk::style theme use clam
    ttk::style configure TFrame -background $theme(base) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style configure TLabel -background $theme(base) -foreground $theme(text)
    ttk::style configure TButton -background $theme(button_bg) -foreground $theme(button_text) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style map TButton \
        -background [list active $theme(heading_active) pressed $theme(selected_bg)] \
        -foreground [list active $theme(button_text) pressed $theme(button_text)]
    # IconButton style - image on far left, text centered
    ttk::style layout IconButton.TButton {
        Button.border -sticky nswe -children {
            Button.focus -sticky nswe -children {
                Button.padding -sticky nswe -children {
                    Button.image -side left -sticky w
                    Button.label -sticky we -expand 1
                }
            }
        }
    }
    ttk::style configure IconButton.TButton -background $theme(button_bg) -foreground $theme(button_text) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border) \
        -padding {6 4}
    ttk::style map IconButton.TButton \
        -background [list active $theme(heading_active) pressed $theme(selected_bg)] \
        -foreground [list active $theme(button_text) pressed $theme(button_text)]
    ttk::style configure TEntry -fieldbackground $theme(entry_bg) -foreground $theme(entry_text) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style map TEntry \
        -fieldbackground [list readonly $theme(entry_bg) disabled $theme(entry_bg)] \
        -bordercolor [list focus $theme(border_active)]
    ttk::style configure TNotebook -background $theme(base) -borderwidth 0 \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style configure TNotebook.Tab -background $theme(tab_bg) -foreground $theme(tab_text) -padding {12 6} \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border)
    ttk::style map TNotebook.Tab \
        -background [list selected $theme(tab_selected_bg) active $theme(tab_active_bg)] \
        -foreground [list selected $theme(tab_selected_text) active $theme(text)]
    ttk::style configure TScrollbar -troughcolor $theme(scrollbar_trough) -background $theme(scrollbar_thumb) \
        -bordercolor $theme(border) -lightcolor $theme(border) -darkcolor $theme(border) \
        -arrowcolor $theme(scrollbar_arrow)
    ttk::style map TScrollbar -background [list active $theme(scrollbar_thumb_active)] \
        -arrowcolor [list active $theme(text)]
}

proc configure_root_window {} {
    global theme
    . configure -background $theme(base)
}
