#!/bin/sh
set -eu

LABEL="${NULLEVI03_LAUNCHD_LABEL:-com.iqlab.nullevi03}"
ACTION="${1:-install}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
PLIST_DIR="${HOME}/Library/LaunchAgents"
LOG_DIR="${HOME}/Library/Logs/nullevi03"
PLIST="${PLIST_DIR}/${LABEL}.plist"
GUI_TARGET="gui/$(id -u)"

usage() {
  cat <<EOF
Usage: scripts/install-launchd.sh [install|uninstall|restart|status]

Installs a user LaunchAgent for ${LABEL}.
Logs:
  ${LOG_DIR}/out.log
  ${LOG_DIR}/err.log
EOF
}

write_plist() {
  mkdir -p "$PLIST_DIR" "$LOG_DIR"

  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>${REPO_DIR}/boot.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${REPO_DIR}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/out.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/err.log</string>
</dict>
</plist>
EOF
}

install_agent() {
  write_plist
  launchctl bootout "$GUI_TARGET" "$PLIST" > /dev/null 2>&1 || true
  launchctl bootstrap "$GUI_TARGET" "$PLIST"
  launchctl kickstart -k "${GUI_TARGET}/${LABEL}"
  echo "Installed and started ${LABEL}"
  echo "Logs: ${LOG_DIR}/err.log"
}

uninstall_agent() {
  launchctl bootout "$GUI_TARGET" "$PLIST" > /dev/null 2>&1 || true
  rm -f "$PLIST"
  echo "Uninstalled ${LABEL}"
}

case "$ACTION" in
  install)
    install_agent
    ;;
  uninstall)
    uninstall_agent
    ;;
  restart)
    launchctl kickstart -k "${GUI_TARGET}/${LABEL}"
    ;;
  status)
    launchctl print "${GUI_TARGET}/${LABEL}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
