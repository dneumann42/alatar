namespace eval ::alatar::deps {
    variable dependencies {
	flatpak { flatpak }
	rust { rustup }
	base { lsd bat git ripgrep jq zsh !ensure_rust ruby }
	desktop {
	    sway swaybg rofi ghostty brightnessctl ly pipewire pipewire-audio pipewire-pulse wireplumber pavucontrol
	    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
	    zellij yazi tldr waybar mpv yt-dlp ffmpeg swayimg zathura zathura-pdf-mupdf
	    libnotify mako imagemagick inotify-tools polkit-gnome !ensure_wallust
	    @app.zen_browser.zen
	    @com.spotify.Client
	    @com.github.tchx84.Flatseal
	}
    }

    proc packageInstalled {package} {
	if {[catch {exec pacman -Qi $package}]} {
	    return 0;
	}
	return 1;
    }

    proc flatpakInstalled {package} {
	if {[catch {exec flatpak info $package 2>@1}]} {
	    return 0;
	}
	return 1;
    }

    proc ensureDep {dep} {
	variable dependencies
	if {[dict exists $dependencies $dep]} {
	    set actions [dict get $dependencies $dep]
	    foreach action $actions {
		if {[string range $action 0 0] eq "!"} {
		    set proc_name [string range $action 1 end]
		    if {[catch {$proc_name} result]} {
		        puts "ERROR: Failed to run $proc_name: $result"
		    }
		    continue;
		}
		if {[string range $action 0 0] eq "@"} {
		    ensureDep {flatpak}
		    set name [string range $action 1 end]
		    if {[flatpakInstalled $name]} {
		        continue;
		    }
		    puts "Installing flatpak: $name"
		    if {[catch {exec flatpak install -y $name 2>@1} result]} {
		        puts "ERROR: Failed to install flatpak $name: $result"
		    } else {
		        puts "Successfully installed flatpak: $name"
		    }
		    continue;
		}
		if {[packageInstalled $action]} {
		    continue;
		}
		puts "Installing $action"
		if {[catch {exec sudo pacman -S --noconfirm --needed $action 2>@1} result]} {
		    puts "ERROR: Failed to install package $action: $result"
		} else {
		    puts "Successfully installed: $action"
		}
	    }
	} else {
	    error "Undefined dependency: $dep"
	}
    }

    proc ensure {deps} {
	foreach dep $deps {
	    ensureDep $dep
	}
    }

    proc ensure_rust {} {
        ensure {rust}
        # Check if rustup has a default toolchain configured
        if {[catch {exec rustup default 2>@1} result] || [string match "*no default toolchain*" $result]} {
            puts "Setting up Rust default toolchain..."
            if {[catch {exec rustup default stable 2>@1} result]} {
                puts "ERROR: Failed to set default Rust toolchain: $result"
            } else {
                puts "Successfully set default Rust toolchain to stable"
            }
        }
    }

    proc ensure_wallust {} {
	if {[catch {exec which wallust}]} {
	    puts "Installing wallust via cargo..."
	    ensure_rust
	    if {[catch {exec cargo install wallust 2>@1} result]} {
		puts "ERROR: Failed to install wallust: $result"
	    } else {
		puts "Successfully installed wallust"
	    }
	}
    }
}

