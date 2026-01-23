#!/usr/bin/env tclsh

lappend auto_path [file dirname [info script]]
package require tools
package require packages
package require dots

oo::class create Alatar {
    mixin Stringable ArgumentManager
    constructor {} {
    }
}

set alatar [Alatar new]
$alatar add-arg [create-packages-module]
$alatar add-arg [create-dots-module]

set mod [$alatar find-by-name [lindex $argv 0]]
if {$mod ne ""} {
    $mod invoke [lrange $argv 1 end]
}

