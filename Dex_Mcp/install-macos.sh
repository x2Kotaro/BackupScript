#!/bin/bash
# Dex_Mcp - macOS auto-start installer.
#
# Registers server.js as a launchd LaunchAgent so it:
#   - starts on login
#   - restarts on crash / if it exits (KeepAlive)
#   - keeps running across Claude Code sessions
#
# Run once. After this you never touch the server again.
#   bash Dex_Mcp/install-macos.sh
#
# Uninstall:
#   bash Dex_Mcp/uninstall-macos.sh

set -euo pipefail

LABEL="com.valkyrie.dexmcp"
PORT="${DEX_MCP_PORT:-8790}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_JS="$SCRIPT_DIR/server.js"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs"

NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  echo "error: node not found on PATH. Install Node 18+ first (brew install node), then re-run." >&2
  exit 1
fi
echo "node:      $NODE_BIN ($("$NODE_BIN" --version))"
echo "server:    $SERVER_JS"
echo "root:      $REPO_ROOT"
echo "port:      $PORT"
echo "plist:     $PLIST"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$NODE_BIN</string>
    <string>$SERVER_JS</string>
    <string>--daemon</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>DEX_MCP_ROOT</key>
    <string>$REPO_ROOT</string>
    <key>DEX_MCP_PORT</key>
    <string>$PORT</string>
  </dict>
  <key>WorkingDirectory</key>
  <string>$REPO_ROOT</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>5</integer>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/$LABEL.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/$LABEL.log</string>
</dict>
</plist>
EOF

echo
echo "wrote $PLIST"

UID_NUM="$(id -u)"
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
launchctl enable "gui/$UID_NUM/$LABEL"
launchctl kickstart -k "gui/$UID_NUM/$LABEL"

echo "loaded. waiting for port $PORT ..."
for i in $(seq 1 20); do
  if curl -fsS "http://127.0.0.1:$PORT/ping" >/dev/null 2>&1; then
    echo "ok - daemon answering on http://127.0.0.1:$PORT/ping"
    echo
    echo "done. MCP server 'dex' is set. Restart Claude Code and check /mcp."
    exit 0
  fi
  sleep 0.5
done

echo "warning: daemon did not answer /ping yet. Check log:" >&2
echo "  tail -f $LOG_DIR/$LABEL.log" >&2
exit 1
