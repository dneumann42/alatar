#!/usr/bin/env tclsh

set alatar_home "$::env(ALATAR_HOME)"
set alatar_dots_home [file join "$alatar_home" "alatar_dots"]
set config_home [file join "$::env(HOME)" ".config" "alatar"]

source "$alatar_home/lib/base.tcl"
source "$alatar_home/lib/config.tcl"
source "$alatar_home/lib/ssh.tcl"
source "$alatar_home/lib/dependencies.tcl"
source "$alatar_home/lib/dots.tcl"
source "$alatar_home/lib/director.tcl"

::alatar::deps::ensure {base}

ensureZshShell

source "$alatar_home/lib/desktop.tcl"
