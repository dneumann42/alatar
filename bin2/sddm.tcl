#!/usr/bin/env tclsh

lappend auto_path [file dirname [info script]]
package require tools
package provide sddm 1.0

proc do-install-command {args} {
    set installScript "$::env(HOME)/.alatar/alatar_dots/sddm/install.sh"

    if {![file exists $installScript]} {
        puts "Error: SDDM install script not found at $installScript"
        exit 1
    }

    puts "Installing Alatar SDDM theme..."
    puts "This will prompt for your sudo password."
    puts ""

    # Run the install script with sudo
    if {[catch {exec sudo bash $installScript >@ stdout 2>@ stderr} result]} {
        puts "Error: Installation failed"
        exit 1
    }

    puts ""
    puts "Installation complete!"
    puts ""
    puts "To apply changes immediately, run:"
    puts "  sudo systemctl restart sddm"
    puts ""
    puts "Or simply reboot your system."
}

proc do-update-theme-command {args} {
    set themeConf "$::env(HOME)/.alatar/alatar_dots/sddm/alatar-theme/theme.conf"
    set destTheme "/usr/share/sddm/themes/alatar/theme.conf"

    if {![file exists $themeConf]} {
        puts "Error: SDDM theme.conf not found at $themeConf"
        exit 1
    }

    if {![file isdirectory /usr/share/sddm/themes/alatar]} {
        puts "Error: SDDM Alatar theme not installed"
        puts "Run: ./alatar.tcl sddm install"
        exit 1
    }

    puts "Updating SDDM theme colors..."

    if {[catch {exec sudo cp $themeConf $destTheme >@ stdout 2>@ stderr} result]} {
        puts "Error: Failed to copy theme.conf"
        exit 1
    }

    puts "✓ SDDM theme colors updated"
    puts ""
    puts "Changes will take effect on next login screen."
    puts "To apply immediately: sudo systemctl restart sddm"
}

proc build-install-command {} {
    Command new "i" "install" \
        do-install-command \
        {Install Alatar SDDM theme and configuration (requires sudo)}
}

proc build-update-theme-command {} {
    Command new "u" "update-theme" \
        do-update-theme-command \
        {Update SDDM theme colors after wallpaper change (requires sudo)}
}

proc create-sddm-module {} {
    set m [Module new "s" "sddm" "Manage SDDM login manager"]
    $m add-arg [build-install-command]
    $m add-arg [build-update-theme-command]
    return $m
}
