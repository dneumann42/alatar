#!/usr/bin/env tclsh

lappend auto_path [file dirname [info script]]
package require tools
package provide packages 1.0

set pkg_list {
    nim          {!package-nim-install|Nim programming language}
    git          {git| Git version control}
    prelude      {bat ripgrep curl jq lsd| Modern and important utilities}
}

proc package-nim-install {} {
    if {[auto_execok "nim"] ne ""} {
	return
    }
    set cacheDir [file join $::env(HOME) .cache]
    set script [file join $cacheDir install-grabnim.sh]
    set url "https://codeberg.org/janAkali/grabnim/raw/branch/master/misc/install.sh"
    file mkdir $cacheDir
    puts "Downloading grabnim installer..."
    exec curl -fsSL $url -o $script
    file attributes $script -permissions u+x
    puts "Running installer..."
    exec sh $script
    puts "Running grabnim..."
    exec grabnim
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

proc zypper-install {packages} {
    if {[llength $packages] == 0} return
    exec sudo zypper install -y {*}$packages
}

proc handle-package-command {pkg} {
    set def [lindex [split $pkg |] 0]

    if {[string index $def 0] eq "!"} {
	eval [string range $def 1 end]
	return;
    }
    
    zypper-install $pkg
}


proc do-install-command {args} {
    global pkg_list
    
    set splits [split [lindex $args 0] " "]

    if {$splits eq ""} {
	puts "Error: Package install expects list of packages to install."
	puts "Example: ./alatar.tcl package install nim tcl"
	return
    }

    foreach item $splits {
	if {![dict exists $pkg_list $item]} {
	    puts "Undefined package: $item"
	    continue
	}
	set value [lindex [split [dict get $pkg_list $item] |] 0]
	set pkgs [split $value " "]
	foreach pkg $pkgs {
	    handle-package-command $pkg
	}
    }
}

proc build-install-command {} {
    Command new "i" "install" do-install-command "Install packages from the package list"
}

proc build-update-command {} {
    
}

proc build-upgrade-command {} {
    
}

proc do-list-command {x} { print-pkg-table }
proc build-list-command {} {
    Command new "l" "list" do-list-command "List all available packages"
}

proc create-packages-module {} {
    set m [Module new "p" "package" "Manage system packages"]
    $m add-arg [build-list-command]
    $m add-arg [build-install-command]
    return $m
}
