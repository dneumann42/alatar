#!/usr/bin/env tclsh

lappend auto_path [file dirname [info script]]
package require tools
package provide dots 1.0

proc create-dots-module {} {
    set m [Module new "d" "dots"]
    return $m
}
