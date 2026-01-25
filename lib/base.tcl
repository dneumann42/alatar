#!/usr/bin/env tclsh

proc slurp {path} {
    set fp [open "$path" r]
    set contents [read $fp]
    close $fp
    return [string trim $contents]
}

proc dump {path content} {
    set fp [open $path w]
    puts -nonewline $fp $content
    close $fp
}
