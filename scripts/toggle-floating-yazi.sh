#!/usr/bin/env bash
set -euo pipefail

# Toggle a floating Ghostty window running yazi.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_ID="${APP_ID:-app.floating-yazi}"
TITLE="${TITLE:-Yazi}"
LAUNCHER="${LAUNCHER:-$SCRIPT_DIR/launch-floating-ghostty.sh}"
FLOAT_WIDTH="${FLOAT_WIDTH:-1400}"
FLOAT_HEIGHT="${FLOAT_HEIGHT:-900}"
CMD="${*:-yazi}"

export APP_ID TITLE LAUNCHER FLOAT_WIDTH FLOAT_HEIGHT
exec "$SCRIPT_DIR/toggle-floating-terminal.sh" "$CMD"
