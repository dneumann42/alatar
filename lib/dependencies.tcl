namespace eval ::alatar::deps {
    variable dependencies {
	flatpak { flatpak }
	base { lsd bat git ripgrep jq zsh }
	desktop {
	    sway rofi ghostty brightnessctl ly pipewire pavucontrol
	    zellij yazi tldr waybar mpv yt-dlp swayimg zathura zathura-pdf-mupdf
	    libnotify mako imagemagick
	    @app.zen_browser.zen
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
}
