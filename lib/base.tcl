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
    puts "$message"
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
    set shells_content [slurp "/etc/shells"]
    set zsh_path ""

    foreach line [split $shells_content "\n"] {
        set line [string trim $line]
        if {$line eq "" || [string range $line 0 0] eq "#"} {
            continue
        }
        if {[string match "*/zsh" $line]} {
            set zsh_path $line
            break
        }
    }

    if {$zsh_path eq ""} {
        error "zsh not found in /etc/shells. Ensure zsh is installed and listed in /etc/shells"
    }

    set current_shell [string trim $::env(SHELL)]
    if {$current_shell ne $zsh_path} {
        log "Changing default shell to zsh for current user"
        puts "Running: chsh -s $zsh_path"
        if {[catch {exec chsh -s $zsh_path <@stdin >@stdout 2>@stderr} result]} {
            error "Failed to change shell to zsh"
        }
        puts "Default shell changed to zsh for current user"
        puts "NOTE: You need to log out and back in for this to take effect"
    }

    if {[catch {exec getent passwd root} root_entry]} {
        log "WARNING: Could not get root user info"
        return
    }
    set root_shell [lindex [split [string trim $root_entry] :] 6]
    if {$root_shell ne $zsh_path} {
        log "Changing default shell to zsh for root"
        if {[catch {exec sudo chsh -s $zsh_path root <@stdin >@stdout 2>@stderr}]} {
            log "WARNING: Could not change root shell to zsh"
        } else {
            puts "Default shell changed to zsh for root"
        }
    }
}

proc windowIsVisible {mark} {
    set result [catch {exec swaymsg -t get_tree} tree]
    if {$result == 0} {
        if {[catch {exec sh -c "echo '$tree' | jq -r '.. | select(.marks? and (.marks | contains(\[\"$mark\"\])) and .visible == true) | .id'"} id]} {
            return 0
        }
        if {[string length $id] > 0} {
            return 1
        }
    }
    return 0
}

proc windowExists {mark} {
    set result [catch {exec swaymsg -t get_tree} tree]
    if {$result == 0} {
        if {[string match "*\"$mark\"*" $tree]} {
            return 1
        }
    }
    return 0
}

proc toggleScratchpadWindow {mark spawnCmd {delay 100}} {
    if {[windowExists $mark]} {
        if {[windowIsVisible $mark]} {
            catch {exec swaymsg "\[con_mark=\"$mark\"\] move scratchpad"}
        } else {
            catch {exec swaymsg "\[con_mark=\"$mark\"\] scratchpad show"}
        }
    } else {
        eval exec $spawnCmd &
        after $delay
        catch {exec swaymsg "\[con_mark=\"$mark\"\] move scratchpad"}
        after 100
        catch {exec swaymsg "\[con_mark=\"$mark\"\] scratchpad show"}
    }
}
