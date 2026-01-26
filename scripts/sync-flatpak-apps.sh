#!/bin/bash
# Sync flatpak .desktop files to user applications directory
# This ensures rofi and other launchers can find flatpak applications

USER_APPS_DIR="$HOME/.local/share/applications"
FLATPAK_SYSTEM_DIR="/var/lib/flatpak/exports/share/applications"
FLATPAK_USER_DIR="$HOME/.local/share/flatpak/exports/share/applications"

# Create user applications directory if it doesn't exist
mkdir -p "$USER_APPS_DIR"

# Remove old flatpak symlinks (ones pointing to flatpak directories)
find "$USER_APPS_DIR" -type l | while read -r link; do
    target=$(readlink "$link")
    if [[ "$target" == */flatpak/exports/share/applications/* ]]; then
        rm "$link"
    fi
done

# Symlink system flatpak applications
if [ -d "$FLATPAK_SYSTEM_DIR" ]; then
    for desktop in "$FLATPAK_SYSTEM_DIR"/*.desktop; do
        [ -f "$desktop" ] || continue
        basename=$(basename "$desktop")
        ln -sf "$desktop" "$USER_APPS_DIR/$basename"
    done
fi

# Symlink user flatpak applications
if [ -d "$FLATPAK_USER_DIR" ]; then
    for desktop in "$FLATPAK_USER_DIR"/*.desktop; do
        [ -f "$desktop" ] || continue
        basename=$(basename "$desktop")
        ln -sf "$desktop" "$USER_APPS_DIR/$basename"
    done
fi

# Update desktop database
update-desktop-database "$USER_APPS_DIR" 2>/dev/null || true

echo "Flatpak applications synced to $USER_APPS_DIR"
