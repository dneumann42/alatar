#!/usr/bin/env tclsh

proc clone_dots {} {
  puts "TODO: call deploy to clone dots"
}

if {![file isdirectory $alatar_dots_home]} {
    clone_dots
}
