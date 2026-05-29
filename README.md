# ナルエビちゃん三世

Claude Code を Telegram から呼び出すための小さな起動ラッパーです。
Claude Code の subscription/OAuth 認証を使い、公式 Telegram channel plugin へ接続します。

## 前提

- Claude Code CLI
- Claude subscription でログイン済みの Claude Code
- Telegram BotFather で作成した bot token
- Bun。Telegram channel plugin の MCP server が Bun で動きます
- macOS で常駐させる場合は launchd

## 初期セットアップ

```sh
cd /Users/tomoya/IQLab/ai-concierge/nullevi03
brew install oven-sh/bun/bun
claude --version
claude auth status
claude plugin marketplace update claude-plugins-official
claude plugin install telegram@claude-plugins-official --scope local
```

長時間の常駐で subscription 認証を安定させる場合は、一度だけ実行します。

```sh
claude setup-token
```

## Telegram の設定

1. Telegram の BotFather で bot を作成し、token を取得します。
2. Claude Code を起動します。
3. Claude Code 内で token を保存します。

```text
/telegram:configure <BotFather token>
/reload-plugins
```

CLI だけで保存する場合は、repo ではなく Claude Code の channel state に token を書きます。

```sh
scripts/configure-telegram.sh
scripts/configure-telegram.sh --check
```

4. いったん終了して、この repo から channel 付きで起動します。

```sh
./boot.sh
```

5. Telegram で bot に DM します。bot から pairing code が返ったら、Claude Code 側で承認します。

```text
/telegram:access pair <code>
/telegram:access policy allowlist
```

`allowlist` に切り替えるまでは、新しい DM に pairing code が返ります。自分の接続を確認したら必ず lock down してください。

## 起動

```sh
./boot.sh
```

事前チェックだけを行う場合:

```sh
./boot.sh --check
```

`.env.example` を `.env` にコピーすると、起動通知や追加設定を環境変数で渡せます。実 token を GitHub に commit しないでください。

## macOS launchd で常駐

Claude Code と Telegram plugin の設定が終わってから実行します。

```sh
chmod +x scripts/install-launchd.sh
scripts/install-launchd.sh install
```

確認と停止:

```sh
scripts/install-launchd.sh status
scripts/install-launchd.sh uninstall
```

ログ:

```sh
tail -f ~/Library/Logs/nullevi03/err.log
```

## 設定値

| 変数 | 目的 | 既定値 |
| --- | --- | --- |
| `TELEGRAM_BOT_TOKEN` | BotFather token。通常は `/telegram:configure` を使う | なし |
| `TELEGRAM_CHAT_ID` | `boot.sh` の起動・再起動通知先 | なし |
| `CLAUDE_RESTART_DELAY` | Claude 終了後に再起動するまでの秒数 | `5` |
| `CLAUDE_BYPASS_PERMISSIONS` | `--dangerously-skip-permissions` を付けるか | `1` |
| `CLAUDE_CONTINUE` | `-c` で最新会話を継続するか。初回は `0` のまま起動する | `0` |
| `REQUIRE_TELEGRAM_TOKEN` | Telegram token 未設定時に起動を止めるか | `1` |
| `CLAUDE_SESSION_ID` | 固定 session を resume する場合の UUID | なし |
| `CLAUDE_MODEL` | `sonnet` などの model 指定 | なし |
| `CLAUDE_EFFORT` | `low`, `medium`, `high` など | なし |

## 注意

- `CLAUDE_BYPASS_PERMISSIONS=1` は強い権限で動きます。Telegram 経由で操作できる相手を `allowlist` で絞ってください。
- Telegram Bot API は過去ログ検索を提供しません。bot は届いた新規メッセージだけを Claude Code に渡します。
- ライセンスは upstream で未整備です。公開・再配布の扱いは fork 側で別途判断してください。

## 免責事項

家が燃えたとか、なんか起きても全て責任は負わないです。
