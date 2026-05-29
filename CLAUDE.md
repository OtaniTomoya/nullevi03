# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

「ナルエビちゃん三世」は、Claude Code を Telegram Bot 経由で常時稼働させるための極小ラッパー。リポジトリ本体には Bot ロジックは存在せず、`claude` CLI を `claude-plugins-official` の `plugin:telegram` チャンネルに繋いで起動・再起動するだけのシェルスクリプトで構成されている。Claude Code subscription/OAuth 認証で動かす前提で、launchd 常駐もサポートする。

## 起動方法

```sh
./boot.sh
./boot.sh --check
```

- `boot.sh` は `claude --channels plugin:telegram@claude-plugins-official` を無限ループで実行し、終了したら `CLAUDE_RESTART_DELAY` 秒待って再起動する。
- 初回起動では既定で `-c` を付けない。最新会話を継続したい場合は `CLAUDE_CONTINUE=1` を使う。
- 既定では Telegram token 未設定時に起動を止める。token なしで検証したい場合だけ `REQUIRE_TELEGRAM_TOKEN=0` を使う。
- 既定では `--dangerously-skip-permissions` を付ける。変更する場合は `CLAUDE_BYPASS_PERMISSIONS=0` を使う。
- 初回起動と再起動の各イベントを、`TELEGRAM_BOT_TOKEN` と `TELEGRAM_CHAT_ID` がある場合だけ Telegram にプッシュ通知する (`notify_telegram` 関数)。
- `CLAUDE_SESSION_ID` がある場合は `--resume <id>`、`CLAUDE_CONTINUE=1` の場合は `-c` で前回セッションを継続する。
- macOS では `scripts/install-launchd.sh install` で user LaunchAgent として常駐できる。

## 必須の前提

- Claude Code が CLI として導入され、subscription/OAuth 認証済みであること。
- 長時間の常駐では `claude setup-token` を実行しておくこと。
- `telegram@claude-plugins-official` が local scope で install 済みであること。
- Bot 作成は BotFather で行う。token は `/telegram:configure <token>`、`scripts/configure-telegram.sh`、BotFather のメッセージ全文をコピーした状態で `scripts/configure-telegram.sh --clipboard`、または `scripts/configure-telegram.sh --wait-clipboard` により `~/.claude/channels/telegram/.env` に保存するのが基本。
- 起動通知を使う場合のみ、環境変数または `.env` で `TELEGRAM_BOT_TOKEN` と `TELEGRAM_CHAT_ID` を渡す。

## 編集時の注意

- スクリプトは POSIX sh で書かれている (`#!/bin/sh`)。bash 固有構文を持ち込まないこと。
- 認証情報は repository に commit しない。`.env`、`~/.claude/channels/telegram/.env`、launchd plist に実 token を固定しない。
- `--dangerously-skip-permissions` の既定値変更は挙動を大きく変えるため、ユーザー確認を取ること。
