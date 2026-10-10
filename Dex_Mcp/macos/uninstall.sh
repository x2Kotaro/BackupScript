#!/bin/bash
# Dex_Mcp - remove the macOS auto-start LaunchAgent.
set -euo pipefail

LABEL="com.valkyrie.dexmcp"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM="$(id -u)"

launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
echo "removed $PLIST and stopped the daemon."
