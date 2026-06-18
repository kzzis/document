# claudecode.nvim + tmux ハイブリッド構成 セットアップ手順

## 構成概要

```
Neovim (claudecode.nvim) ←WebSocket→ Claude Code (tmuxポップアップ)
```

- Neovim起動時にclaudecode.nvimがWebSocketサーバーを裏で立ち上げる
- tmuxの `prefix + y` でClaudeをポップアップ起動
- Claude側が自動でNeovimのWebSocketを検出して接続

## 前提条件

- Claude Code CLI インストール済み
- Neovim 0.8+
- lazy.nvim（プラグインマネージャー）
- snacks.nvim（claudecode.nvimの依存）

---

## 1. claudecode.nvim インストール

`~/.config/nvim/lua/plugins/claudecode.lua` を作成：

```lua
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    auto_start = true,  -- Neovim起動時に自動でWebSocketサーバー起動
    terminal = {
      provider = "none",  -- ターミナルはtmuxに任せる
    },
  },
  keys = {
    -- Diffのaccept/rejectだけ設定
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
    -- 選択範囲送信（tmuxセッションへ）
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
  },
}
```

---

## 2. tmux設定（既存に追記）

`.tmux.conf` の既存の `prefix + y` バインドを修正：

```bash
# Claude Codeをセッション管理しながらポップアップ
# --ide フラグでNeovim接続を有効化
bind -r y run-shell '\
  SESSION="claude-$(echo #{pane_current_path} | md5sum | cut -c1-8)"; \
  tmux has-session -t "$SESSION" 2>/dev/null || \
  tmux new-session -d -s "$SESSION" -c "#{pane_current_path}" "claude --ide"; \
  tmux display-popup -w80% -h80% -E "tmux attach-session -t $SESSION"'
```

変更点は `"claude"` → `"claude --ide"` のみ。

---

## 3. 動作確認

```bash
# tmux設定再読み込み
tmux source ~/.tmux.conf
```

Neovimを起動してWebSocketサーバーを確認：

```
:ClaudeCodeStatus
# "Server running on port XXXXX" と出ればOK
```

その後 `prefix + y` でClaudeを起動し、接続されれば完了。

---

## トラブルシューティング

**ClaudeがNeovimを検出しない場合**

```bash
# ロックファイルの存在確認
ls ~/.claude/ide/
# *.lock ファイルがあればWebSocketサーバーは起動している
```

**セッションが古いディレクトリのclaudeが動いている場合**

```bash
# 既存セッションを削除して再起動
tmux kill-session -t "claude-xxxxxxxx"
```
