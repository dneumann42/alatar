#!/usr/bin/env tclsh

set dots [::alatar::config::get dotfiles]
set dots_out [file join [::alatar::config::get alatar] "alatar_dots"]

proc update_dots {} {
    global dots dots_out

    # Check if repo already exists
    if {[file isdirectory $dots_out]} {
        log "Dotfiles repository already exists, checking for updates..."

        # Check if it's a git repository
        if {![file isdirectory [file join $dots_out ".git"]]} {
            error "Directory $dots_out exists but is not a git repository"
        }

        # Check git status
        if {[catch {exec git -C $dots_out status --porcelain 2>@1} status_output]} {
            error "Failed to check git status: $status_output"
        }

        # If working directory is not clean, warn user
        if {[string trim $status_output] ne ""} {
            log "Warning: Working directory has uncommitted changes:"
            puts $status_output
            log "Skipping git pull. Please commit or stash changes first."
            return
        }

        # Pull latest changes
        log "Pulling latest changes..."
        if {[catch {exec git -C $dots_out pull 2>@1} result]} {
            error "Failed to pull changes: $result"
        }
        log "Dotfiles updated successfully!"
    } else {
        # Clone the repository
        log "Cloning dotfiles from $dots..."
        if {[catch {exec git clone --depth 1 $dots $dots_out 2>@1} result]} {
            error "Failed to clone dotfiles from $dots: $result"
        }
        log "Successfully cloned dotfiles to $dots_out"
    }
}

proc clone_dots {} {
    update_dots
}

proc createSymlink {source target} {
    if {[file exists $target]} {
        if {[file type $target] eq "link"} {
            set current_target [file readlink $target]
            if {$current_target eq $source} {
                return
            }
            log "Removing existing symlink: $target -> $current_target"
            file delete $target
        } else {
            return
        }
    }

    set target_dir [file dirname $target]
    if {![file isdirectory $target_dir]} {
        if {[catch {exec mkdir -p $target_dir 2>@1} result]} {
            error "Failed to create directory $target_dir: $result"
        }
    }

    if {[catch {file link -symbolic $target $source} err]} {
        error "Failed to create symlink $target -> $source: $err"
    }
    log "Created symlink: $target -> $source"
}

proc linkDots {} {
    global dots_out
    set config_home "$::env(HOME)/.config"
    set home "$::env(HOME)"

    if {![file isdirectory $dots_out]} {
        log "Dotfiles directory not found at $dots_out, skipping linking"
        return
    }

    foreach dir [glob -nocomplain -directory $dots_out -type d *] {
        set dirname [file tail $dir]

        # Skip hidden directories like .git
        if {[string range $dirname 0 0] eq "."} {
            continue
        }

        switch $dirname {
            "zsh" {
                # Symlink each file in zsh directory to home
                foreach file [glob -nocomplain -directory $dir -type f *] {
                    set filename [file tail $file]
                    set target [file join $home ".$filename"]
                    createSymlink $file $target
                }
            }
            "applications" {
                # Symlink desktop files to ~/.local/share/applications
                set apps_dir [file join $home ".local" "share" "applications"]
                foreach file [glob -nocomplain -directory $dir -type f *.desktop] {
                    set filename [file tail $file]
                    set target [file join $apps_dir $filename]
                    createSymlink $file $target
                }
            }
            default {
                # Symlink entire directory to ~/.config
                set target [file join $config_home $dirname]
                createSymlink $dir $target
            }
        }
    }
}

if {![file isdirectory $dots_out]} {
    clone_dots
}

linkDots
