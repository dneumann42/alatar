#!/usr/bin/env tclsh

lappend auto_path [file dirname [info script]]
package require tools
package provide dots 1.0

# Helper proc to create symlinks, removing existing ones first
proc create_symlink {target linkname} {
    if {[file exists $linkname]} {
        file delete $linkname
    }
    file link -symbolic $linkname $target
}

proc do-deploy-command {args} {
    set dotsDir "$::env(HOME)/.alatar/alatar_dots"
    set dotsRepo "git@github.com:dneumann42/alatar_dots.git"

    if {![file exists $dotsDir]} {
        puts "Cloning dotfiles repository..."
        exec git clone $dotsRepo $dotsDir
    }

    set configDir "$::env(HOME)/.config"
    file mkdir $configDir

    create_symlink "$dotsDir/zsh/zshenv" "$::env(HOME)/.zshenv"
    create_symlink "$dotsDir/zsh/zshrc" "$::env(HOME)/.zshrc"
    create_symlink "$dotsDir/zsh/zprofile" "$::env(HOME)/.zprofile"
    create_symlink "$dotsDir/zsh/zalias" "$::env(HOME)/.zalias"
    create_symlink "$dotsDir/zsh/paths.sh" "$::env(HOME)/.zsh_paths.sh"
    puts "Linked zsh files"

    foreach path [glob -nocomplain -directory $dotsDir *] {
        set name [file tail $path]

        if {$name in {.git zsh newsboat applications}} {
            continue
        }

        if {![file isdirectory $path]} {
            continue
        }

        set dest "$configDir/$name"

        if {[file exists $dest] && [file isdirectory $dest]} {
            set isSymlink [expr {![catch {file readlink $dest}]}]
            if {!$isSymlink} {
                file delete -force $dest
            }
        }

        create_symlink $path $dest
        puts "Linked $path -> $dest"
    }

    # Special newsboat handling
    set newsboatRepoDir "$dotsDir/newsboat"
    if {[file isdirectory $newsboatRepoDir]} {
        set newsboatConfigDir "$configDir/newsboat"

        if {[info exists ::env(XDG_DATA_HOME)]} {
            set newsboatDataDir "$::env(XDG_DATA_HOME)/newsboat"
        } else {
            set newsboatDataDir "$::env(HOME)/.local/share/newsboat"
        }

        set newsboatCacheDest "$newsboatDataDir/cache.db"

        file mkdir $newsboatConfigDir
        file mkdir $newsboatDataDir

        # Migrate legacy newsboat directory if it exists
        set newsboatLegacyDir "$::env(HOME)/.newsboat"
        if {[file isdirectory $newsboatLegacyDir]} {
            set legacyCache "$newsboatLegacyDir/cache.db"
            set legacyHistory "$newsboatLegacyDir/history.cmdline"

            if {[file exists $legacyCache] && ![file exists $newsboatCacheDest]} {
                file rename $legacyCache $newsboatCacheDest
                puts "Moved legacy newsboat cache to $newsboatCacheDest"
            }

            set newsboatHistoryDest "$newsboatConfigDir/history.cmdline"
            if {[file exists $legacyHistory] && ![file exists $newsboatHistoryDest]} {
                file rename $legacyHistory $newsboatHistoryDest
                puts "Moved legacy newsboat history to $newsboatHistoryDest"
            }

            file delete -force $newsboatLegacyDir
            puts "Removed legacy ~/.newsboat directory"
        }

        create_symlink "$newsboatRepoDir/config" "$newsboatConfigDir/config"
        create_symlink "$newsboatRepoDir/urls" "$newsboatConfigDir/urls"
        puts "Linked newsboat config into $newsboatConfigDir"
    }

    # Desktop files: symlink to ~/.local/share/applications
    set appsRepoDir "$dotsDir/applications"
    if {[file isdirectory $appsRepoDir]} {
        set appsDestDir "$::env(HOME)/.local/share/applications"
        file mkdir $appsDestDir

        foreach desktopFile [glob -nocomplain -directory $appsRepoDir *.desktop] {
            set filename [file tail $desktopFile]
            set destFile "$appsDestDir/$filename"
            create_symlink $desktopFile $destFile
            puts "Linked $desktopFile -> $destFile"
        }
    }

    puts "Dotfiles deployment complete!"
}

proc build-deploy-command {} {
    Command new "d" "deploy" \
	do-deploy-command \
	{Deploys dot files by symlinking into $XDG_CONFIG_HOME}
}

proc create-dots-module {} {
    set m [Module new "d" "dots" "Manage dotfiles"]
    $m add-arg [build-deploy-command]
    return $m
}
