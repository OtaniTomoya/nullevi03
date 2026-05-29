#!/bin/sh
set -eu

STATE_DIR="${TELEGRAM_STATE_DIR:-${HOME}/.claude/channels/telegram}"
ENV_FILE="${STATE_DIR}/.env"
TOKEN="${TELEGRAM_BOT_TOKEN:-}"

usage() {
  cat <<'EOF'
Usage:
  scripts/configure-telegram.sh
  scripts/configure-telegram.sh '<BotFather token>'
  TELEGRAM_BOT_TOKEN=<BotFather token> scripts/configure-telegram.sh
  scripts/configure-telegram.sh --check
  scripts/configure-telegram.sh --clear

Writes the Telegram bot token to ~/.claude/channels/telegram/.env with mode 600.
This is the same token file used by the official Telegram channel plugin.
EOF
}

read_token_from_file() {
  if [ ! -f "$ENV_FILE" ]; then
    return 1
  fi

  sed -n 's/^TELEGRAM_BOT_TOKEN=//p' "$ENV_FILE" | tail -n 1
}

prompt_for_token() {
  if [ ! -t 0 ]; then
    echo "Pass the BotFather token as an argument or set TELEGRAM_BOT_TOKEN." >&2
    usage >&2
    exit 2
  fi

  printf 'Paste BotFather token: ' >&2
  old_stty=$(stty -g 2>/dev/null || true)
  if [ -n "$old_stty" ]; then
    stty -echo
  fi
  IFS= read -r token
  if [ -n "$old_stty" ]; then
    stty "$old_stty"
    printf '\n' >&2
  fi

  printf '%s\n' "$token"
}

validate_token() {
  token="$1"

  if [ -z "$token" ]; then
    echo "Telegram token is not configured" >&2
    return 1
  fi

  if ! command -v curl > /dev/null 2>&1; then
    echo "curl not found" >&2
    return 1
  fi

  response=$(curl -sS --max-time 10 "https://api.telegram.org/bot${token}/getMe" || true)
  case "$response" in
    *'"ok":true'*)
      username=$(printf '%s\n' "$response" | sed -n 's/.*"username":"\([^"]*\)".*/\1/p')
      if [ -n "$username" ]; then
        echo "Telegram token is valid for @${username}"
      else
        echo "Telegram token is valid"
      fi
      ;;
    *)
      echo "Telegram token validation failed" >&2
      return 1
      ;;
  esac
}

write_token() {
  token="$1"

  if [ -z "$token" ]; then
    echo "Pass the BotFather token as an argument or set TELEGRAM_BOT_TOKEN." >&2
    usage >&2
    exit 2
  fi

  validate_token "$token"

  mkdir -p "$STATE_DIR"

  tmp="${ENV_FILE}.$$"
  if [ -f "$ENV_FILE" ]; then
    grep -v '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" > "$tmp" || true
  else
    : > "$tmp"
  fi

  printf 'TELEGRAM_BOT_TOKEN=%s\n' "$token" >> "$tmp"
  mv "$tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE"

  echo "Wrote ${ENV_FILE}"
  echo "Restart Claude Code or run /reload-plugins before pairing."
}

clear_token() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "No token file found at ${ENV_FILE}"
    return 0
  fi

  tmp="${ENV_FILE}.$$"
  grep -v '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" > "$tmp" || true

  if [ -s "$tmp" ]; then
    mv "$tmp" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
  else
    rm -f "$tmp" "$ENV_FILE"
  fi

  echo "Cleared Telegram token from ${ENV_FILE}"
}

case "${1:-}" in
  --check)
    validate_token "$(read_token_from_file || true)"
    ;;
  --clear)
    clear_token
    ;;
  -h|--help)
    usage
    ;;
  "")
    if [ -n "$TOKEN" ]; then
      write_token "$TOKEN"
    else
      prompted_token=$(prompt_for_token) || exit $?
      write_token "$prompted_token"
    fi
    ;;
  *)
    if [ $# -eq 1 ]; then
      write_token "$1"
    else
      usage >&2
      exit 2
    fi
    ;;
esac
