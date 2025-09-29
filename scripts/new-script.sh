#!/usr/bin/env bash

read -p "Name for script: " name

SCRIPT_PATH="$HOME/.alatar/scripts/$name.sh"
touch "$SCRIPT_PATH"

read -p "Make executable? (y/n) " makeexec

case "$makeexec" in
    [Yy]*) 
      chmod +x "$SCRIPT_PATH"   ;;
    [Nn]*) ;;
    *) ;;
esac

read -p "Open in editor? (y/n) " openeditor

case "$openeditor" in
    [Yy]*) 
      $EDITOR $SCRIPT_PATH ;;
    [Nn]*) ;;
    *) ;;
esac
