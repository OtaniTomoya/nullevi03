#!/bin/sh


TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-00000000:xxxxxxxxxxxxxxxxxxxxxxxxxxxx}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:xxxxxxxxxxx}"

notify_telegram() {
  text="$1"
  if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=${text}" \
      > /dev/null 2>&1 || true
  fi
}

FIRST=1
while true; do
  if [ "$FIRST" = "1" ]; then
    notify_telegram "🦐 boot.sh起動: ナルエビ三世を起動します🌅"
    FIRST=0
  else
    notify_telegram "🦐 ナルエビ三世が終了 → 5秒後に再起動します🔄"
    sleep 5
    notify_telegram "🦐 ナルエビ三世を再起動します🌅"
  fi
  claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official -c
  echo "ナルエビ三世が終了しました。5秒後に再起動します..."
done

