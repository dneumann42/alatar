#!/usr/bin/env tclsh

proc slurp {path} {
    if {[catch {open "$path" r} fp]} {
        error "Failed to open file '$path': $fp"
    }
    if {[catch {read $fp} contents]} {
        close $fp
        error "Failed to read file '$path': $contents"
    }
    close $fp
    return [string trim $contents]
}

proc dump {path content} {
    if {[catch {open $path w} fp]} {
        error "Failed to open file '$path' for writing: $fp"
    }
    if {[catch {puts -nonewline $fp $content} err]} {
        close $fp
        error "Failed to write to file '$path': $err"
    }
    close $fp
}

proc readLine {prompt} {
    puts -nonewline "$prompt"
    flush stdout
    gets stdin input
    return $input
}

proc log {message} {
    puts "INFO: $message"
}

proc serviceEnabled {service} {
    if {[catch {exec systemctl is-enabled $service 2>@1} result]} {
	return 0
    }
    return [expr {[string trim $result] eq "enabled"}]
}

proc enableService {service} {
    if {[serviceEnabled $service]} {
	return
    }
    if {[catch {exec sudo systemctl enable $service 2>@1} result]} {
	error "Failed to enable service $service: $result"
    }
    puts "Enabled service $service"
}

proc serviceActive {service} {
    if {[catch {exec systemctl is-active $service 2>@1} result]} {
	return 0
    }
    return [expr {$result eq "active"}]
}

proc startService {service} {
    if {[serviceActive $service]} {
	return
    }
    if {[catch {exec sudo systemctl start $service 2>@1} result]} {
	error "Failed to start service $service: $result"
    }
    puts "Started service $service"
}

proc ensureService {service} {
    enableService $service
    startService $service
}

proc ensureZshShell {} {
    # Get zsh path
    if {[catch {exec which zsh} zsh_path]} {
        error "zsh not found in PATH. Ensure zsh is installed first."
    }
    set zsh_path [string trim $zsh_path]

    # Check current user's shell
    set current_shell [string trim $::env(SHELL)]
    if {$current_shell ne $zsh_path} {
        log "Changing default shell to zsh for current user"
        if {[catch {exec chsh -s $zsh_path 2>@1} result]} {
            error "Failed to change shell to zsh: $result"
        }
        puts "Default shell changed to zsh for current user"
        puts "NOTE: You need to log out and back in for this to take effect"
    }

    # Check root's shell
    if {[catch {exec getent passwd root} root_entry]} {
        log "WARNING: Could not get root user info: $root_entry"
        return
    }
    set root_shell [lindex [split [string trim $root_entry] :] 6]
    if {$root_shell ne $zsh_path} {
        log "Changing default shell to zsh for root"
        if {[catch {exec sudo chsh -s $zsh_path root 2>@1} result]} {
            # Some systems might not allow this, just warn
            log "WARNING: Could not change root shell to zsh: $result"
        } else {
            puts "Default shell changed to zsh for root"
        }
    }
}
