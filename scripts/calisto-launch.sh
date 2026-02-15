#!/usr/bin/env bash

export CALISTO_DEV_DIR=/home/dneumann/Projects/calisto
MARKER_FILE="$HOME/.config/calisto/installed-hash"

# Kill any existing calisto instances first
pkill -f calisto.lua || true
sleep 0.1

# Get current git state (commit hash + dirty indicator)
cd "$CALISTO_DEV_DIR"
CURRENT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "no-git")
if [[ -n $(git status -s 2>/dev/null) ]]; then
    CURRENT_HASH="${CURRENT_HASH}-dirty"
fi

# Check if calisto is installed and if it needs updating
NEEDS_INSTALL=false

if ! command -v calisto &> /dev/null; then
    echo "Calisto not found in profile, installing..."
    NEEDS_INSTALL=true
elif [[ ! -f "$MARKER_FILE" ]] || [[ "$CURRENT_HASH" != "$(cat "$MARKER_FILE")" ]]; then
    echo "Calisto source has changed, updating..."
    NEEDS_INSTALL=true
fi

# Install/update if needed
if [[ "$NEEDS_INSTALL" == true ]]; then
    mkdir -p "$(dirname "$MARKER_FILE")"
    nix profile remove calisto 2>/dev/null || true
    nix profile install "$CALISTO_DEV_DIR"
    echo "$CURRENT_HASH" > "$MARKER_FILE"
fi

# Launch calisto
exec calisto
