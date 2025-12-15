#!/usr/bin/env bash
set -euo pipefail

# Toggle the floating cheatsheet terminal like the other floating helpers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export APP_ID="cheatsheet-term"
export TITLE="Keybindings Cheatsheet"
export MARK="cheatsheet-term"
export LAUNCHER="$SCRIPT_DIR/launch-cheatsheet.sh"

exec "$SCRIPT_DIR/toggle-floating-terminal.sh"
