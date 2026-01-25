#!/usr/bin/env tclsh

lappend auto_path [file dirname [info script]]
package require tools
package require packages
package require dots
package require sddm

oo::class create Alatar {
    mixin Stringable ArgumentManager
    constructor {} {
    }
}

set alatar [Alatar new]
$alatar add-arg [create-packages-module]
$alatar add-arg [create-dots-module]
$alatar add-arg [create-sddm-module]

# If no arguments passed, print full help screen
if {[llength $argv] == 0 || [lindex $argv 0] eq ""} {
    puts "Alatar - Command Line Tool"
    puts ""
    puts "Usage: ./alatar.tcl <module> <module-command>"
    puts ""
    $alatar print-help
    exit 0
}

set firstArg [lindex $argv 0]
set mod [$alatar find $firstArg]

if {$mod eq "" && [string length $firstArg] == 2} {
    set moduleShort [string index $firstArg 0]
    set commandShort [string index $firstArg 1]
    set mod [$alatar find $moduleShort]

    if {$mod ne ""} {
        # Found module by short name, pass command short as argument
        set args [linsert [lrange $argv 1 end] 0 $commandShort]
        $mod invoke $args
        exit 0
    }
}

if {$mod ne ""} {
    set args [lrange $argv 1 end]
    $mod invoke $args
} else {
    puts "Error: Unknown module '$firstArg'"
    puts "Please check the help screen for available modules:"
    puts ""
    $alatar print-help
    exit 1
}

