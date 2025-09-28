#!/usr/bin/env bash

# Director, enforces a consistent directory structure
# programs tend to mess up the home directory

# Folder structure
# ~/.config/
# ~/.repos/
# ~/.alatar/
#
# ~/Documents/
# ~/Downloads/
# ~/Projects/
# ~/Media/Videos
# ~/Media/Music
# ~/Media/Pictures

## Check if directory in home should be somewhere else
## ex. Videos shouldn't be ~/Videos but in ~/Media/Videos
## director will prompt if you want to move all contents within ~/Videos to
## ~/Media/Videos, and it will delete the old folder. Director will be smart about symlinks

function move_to_media_folder {
    # $1 is the source directory
    # $2 is the target directory

    if [ -d "$HOME/$1" ]; then
        echo "$1 folder exists, merge the contents with $2"
        read -p "Continue (y/n) " answer
        case "$answer" in
            [Yy]*) 
                mkdir -p "$HOME/$2"
                mv "$HOME/$1/*" "$HOME/$2"
                rm -rf "$HOME/$1" ;;
            [Nn]*) echo "No" ;;
            *) echo "Invalid" ;;
        esac
    fi
}

function build_directory_structure {
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.repos"

    mkdir -p "$HOME/Projects"
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Documents"

    mkdir -p "$HOME/Media/Videos" 
    mkdir -p "$HOME/Media/Pictures" 
    mkdir -p "$HOME/Media/Music" 

    mkdir -p "$HOME/.local/bin"
}

function sync_directory_structure {
    build_directory_structure

    move_to_media_folder "Videos" "Media/Videos"
    move_to_media_folder "Pictures" "Media/Pictures"
    move_to_media_folder "Music" "Media/Music"
}
