#!/usr/bin/env tclsh

lappend auto_path [file dirname [info script]]
package require tools
package provide packages 1.0

proc package-nim-install {} {
    puts "DEMO"
}

set pkg_list {
    nim          {!package-nim-install|Nim programming language}
    git          {git| Git version control}
    prelude      {bat ripgrep curl jq lsd| Modern and important utilities}
}

proc print-pkg-table {} {
    global pkg_list
    set rows {}
    set maxName 0
    set maxPkgs 0

    dict for {name spec} $pkg_list {
        lassign [split $spec |] pkgs desc
        set pkgs [string trim $pkgs]
        set desc [string trim $desc]

        lappend rows [list $name $pkgs $desc]

        set maxName [expr {max($maxName, [string length $name])}]
        set maxPkgs [expr {max($maxPkgs, [string length $pkgs])}]
    }

    set fmt "%-${maxName}s  %-${maxPkgs}s  %s"
    puts [format $fmt "NAME" "PACKAGES" "DESCRIPTION"]
    puts [string repeat "-" 80 ]

    foreach row $rows {
        lassign $row name pkgs desc
        puts -nonewline [format "$fmt\n" $name $pkgs $desc]
    }
}

proc build-install-command {} {
    
}

proc build-update-command {} {
    
}

proc build-upgrade-command {} {
    
}

proc do-list-command {x} {
    print-pkg-table
}
proc build-list-command {} {
    Command new "l" "list" do-list-command
}

proc create-packages-module {} {
    set m [Module new "p" "package"]
    $m add-arg [build-list-command]
    return $m
}
