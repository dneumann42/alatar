#!/usr/bin/env tclsh

set baseDir [file dirname [file dirname [file normalize [info script]]]]
source "$baseDir/lib/base.tcl"

# Use a unique mark instead of title to avoid matching other windows
toggleScratchpadWindow "nomicron-scratchpad" "$baseDir/scripts/nomicron.tcl"
