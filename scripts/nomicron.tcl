#!/usr/bin/env tclsh
# Nomicron launcher - calls into nomicron/nomicron.tcl

set script_dir [file dirname [file normalize [info script]]]
set nomicron_main [file join $script_dir nomicron nomicron.tcl]

source $nomicron_main
