#!/usr/bin/env tclsh

namespace eval ::alatar::config {
    variable data [dict create]
    variable config_file [file join "$config_home" "config.tcl"]
    variable loaded 0

    proc load {} {
	variable data
	variable config_file
	variable loaded
	global config_home 
	
	if {$loaded} return

	if {![file isdirectory $config_home]} {
	    file mkdir $config_home
	}

	if {![file exists $config_file]} {
	    set dots [readLine "Dotfiles repo: "]
	    set data [dict create \
			  dotfiles "$dots" \
			  alatar "$::env(HOME)/.alatar"]
	    save
	} else {
	    set content [slurp $config_file]
	    set config [dict create]
	    eval $content
	    set data $config
	}
	
	set loaded 1
    }

    proc save {} {
	variable data
	variable config_file
	set fp [open $config_file w]
	puts $fp "set config \{"
	dict for {key value} $data {
	    puts $fp "    $key\t\"$value\""
	}
	puts $fp "\}"
	close $fp
	file attributes $config_file -permissions 0600
    }

    proc get {key} {
	variable data
	variable loaded
	load
	if {[dict exists $data $key]} {
	    return [dict get $data $key]
	}
	return ""
    }
}
