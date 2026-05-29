#!/bin/sh
set -eu

if [ -f ./.env ]; then
  set -a
  . ./.env
  set +a
fi

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
CLAUDE_CHANNELS="${CLAUDE_CHANNELS:-plugin:telegram@claude-plugins-official}"
CLAUDE_RESTART_DELAY="${CLAUDE_RESTART_DELAY:-5}"
CLAUDE_BYPASS_PERMISSIONS="${CLAUDE_BYPASS_PERMISSIONS:-1}"
CLAUDE_SESSION_NAME="${CLAUDE_SESSION_NAME:-nullevi03}"
CLAUDE_CONTINUE="${CLAUDE_CONTINUE:-0}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >&2
}

usage() {
  cat <<'EOF'
Usage: ./boot.sh [--check]

Environment:
  TELEGRAM_BOT_TOKEN        Telegram bot token. May also be configured through /telegram:configure.
  TELEGRAM_CHAT_ID          Optional chat ID for boot/restart notifications.
  CLAUDE_BIN                Claude Code executable. Default: claude
  CLAUDE_CHANNELS           Claude Code channel spec. Default: plugin:telegram@claude-plugins-official
  CLAUDE_RESTART_DELAY      Seconds to wait before restarting Claude. Default: 5
  CLAUDE_BYPASS_PERMISSIONS Set to 0 to avoid --dangerously-skip-permissions. Default: 1
  CLAUDE_CONTINUE           Set to 1 to pass -c/--continue. Default: 0
  CLAUDE_SESSION_ID         Optional Claude session UUID to resume instead of the latest session.
  CLAUDE_MODEL              Optional Claude model alias/name.
  CLAUDE_EFFORT             Optional effort level.
EOF
}

notify_telegram() {
  text="$1"

  if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    return 0
  fi

  curl -sS --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${text}" \
    > /dev/null 2>&1 || true
}

check_setup() {
  ok=1

  if ! command -v "$CLAUDE_BIN" > /dev/null 2>&1; then
    log "ERROR: Claude Code CLI not found: $CLAUDE_BIN"
    ok=0
  else
    log "OK: $("$CLAUDE_BIN" --version 2>/dev/null || printf '%s' "$CLAUDE_BIN")"
  fi

  if ! command -v curl > /dev/null 2>&1; then
    log "ERROR: curl not found"
    ok=0
  else
    log "OK: curl found"
  fi

  if ! command -v bun > /dev/null 2>&1; then
    log "ERROR: bun not found. Install with: brew install oven-sh/bun/bun"
    ok=0
  else
    log "OK: bun $(bun --version 2>/dev/null || true)"
  fi

  if command -v "$CLAUDE_BIN" > /dev/null 2>&1; then
    if "$CLAUDE_BIN" auth status > /dev/null 2>&1; then
      log "OK: Claude auth is available"
    else
      log "WARN: Claude auth is not available. Run: claude auth login"
    fi

    if "$CLAUDE_BIN" plugin list 2>/dev/null | grep -q 'telegram@claude-plugins-official'; then
      log "OK: telegram@claude-plugins-official plugin is installed"
    else
      log "WARN: Telegram plugin is not installed. Run: claude plugin install telegram@claude-plugins-official --scope local"
    fi
  fi

  if [ -z "$TELEGRAM_BOT_TOKEN" ] && [ ! -f "$HOME/.claude/channels/telegram/.env" ]; then
    log "WARN: Telegram token is not configured. Run /telegram:configure <token> in Claude Code or scripts/configure-telegram.sh '<token>'."
  else
    log "OK: Telegram token source found"
  fi

  if [ "$ok" -eq 1 ]; then
    return 0
  fi

  return 1
}

run_claude() {
  set -- --channels "$CLAUDE_CHANNELS" --name "$CLAUDE_SESSION_NAME"

  if [ "$CLAUDE_BYPASS_PERMISSIONS" = "1" ]; then
    set -- "$@" --dangerously-skip-permissions
  fi

  if [ -n "${CLAUDE_MODEL:-}" ]; then
    set -- "$@" --model "$CLAUDE_MODEL"
  fi

  if [ -n "${CLAUDE_EFFORT:-}" ]; then
    set -- "$@" --effort "$CLAUDE_EFFORT"
  fi

  if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    set -- "$@" --resume "$CLAUDE_SESSION_ID"
  elif [ "$CLAUDE_CONTINUE" = "1" ]; then
    set -- "$@" -c
  fi

  "$CLAUDE_BIN" "$@"
}

case "${1:-}" in
  --check)
    check_setup
    exit $?
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

check_setup || log "Continuing despite setup warnings."

FIRST=1
while :; do
  if [ "$FIRST" = "1" ]; then
    notify_telegram "nullevi03 boot.sh started"
    FIRST=0
  else
    notify_telegram "nullevi03 exited; restarting in ${CLAUDE_RESTART_DELAY}s"
    sleep "$CLAUDE_RESTART_DELAY"
    notify_telegram "nullevi03 restarting"
  fi

  set +e
  run_claude
  status=$?
  set -e

  log "Claude exited with status ${status}; restarting in ${CLAUDE_RESTART_DELAY}s"
done
