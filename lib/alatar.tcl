#!/usr/bin/env tclsh

# Show help if no arguments provided
if {$argc == 0} {
    puts "Alatar - TCL-Based Linux Management System"
    puts ""
    puts "Usage:"
    puts "  alatar install         Install/update system packages and desktop environment"
    puts "  alatar dots            Update dotfiles from repository"
    puts "  alatar help            Show this help message"
    puts ""
    puts "Commands:"
    puts "  install    - Install base packages and desktop environment"
    puts "  dots       - Clone and symlink dotfiles"
    puts "  help       - Display this help message"
    puts ""
    exit 0
}

# Handle commands
set command [lindex $argv 0]
if {$command eq "help" || $command eq "-h" || $command eq "--help"} {
    puts "Alatar - TCL-Based Linux Management System"
    puts ""
    puts "Usage:"
    puts "  alatar install         Install/update system packages and desktop environment"
    puts "  alatar dots            Update dotfiles from repository"
    puts "  alatar help            Show this help message"
    puts ""
    puts "Commands:"
    puts "  install    - Install base packages and desktop environment"
    puts "  dots       - Clone and symlink dotfiles"
    puts "  help       - Display this help message"
    puts ""
    exit 0
}

set alatar_home "$::env(ALATAR_HOME)"
set alatar_dots_home [file join "$alatar_home" "alatar_dots"]
set config_home [file join "$::env(HOME)" ".config" "alatar"]

source "$alatar_home/lib/base.tcl"
source "$alatar_home/lib/config.tcl"
source "$alatar_home/lib/ssh.tcl"
source "$alatar_home/lib/dependencies.tcl"
source "$alatar_home/lib/dots.tcl"
source "$alatar_home/lib/director.tcl"

# Handle different commands
if {$command eq "dots"} {
    puts "Updating dotfiles..."
    clone_dots
    linkDots
    puts "Dotfiles updated successfully!"
    exit 0
}

if {$command eq "install"} {
    puts "Starting Alatar installation..."
    ::alatar::deps::ensure {base}
    ensureZshShell
    source "$alatar_home/lib/desktop.tcl"
    puts "Installation complete!"
    exit 0
}

puts "Unknown command: $command"
puts "Run 'alatar help' for usage information"
exit 1
