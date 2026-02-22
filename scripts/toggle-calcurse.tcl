#!/usr/bin/env tclsh

set baseDir [file dirname [file dirname [file normalize [info script]]]]
source "$baseDir/lib/base.tcl"

toggleScratchpadWindow "calcurse" "ghostty --title=calcurse -e calcurse"
