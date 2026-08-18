# HHKB Type-S US を Windows で Mac 風に使う設定

## ゴール

HHKB の US 配列を Windows でも Mac とほぼ同じ指使いで使う。

最終的な操作は次のとおり。

| HHKB の操作 | Windows での動作 |
|---|---|
| 左 Command 相当（左◇）単押し | 英数 / IME OFF |
| 右 Command 相当（右◇）単押し | かな / IME ON |
| Command + C | コピー |
| Command + V | ペースト |
| Command + X | 切り取り |
| Command + Z | Undo |
| Command + Shift + Z | Redo |
| Command + A | 全選択 |
| Command + S | 保存 |
| Command + F | 検索 |
| Command + T | 新規タブ |
| Command + W | タブを閉じる |
| Command + Tab | アプリ切り替え |
| Fn + 左 Command 相当（左◇） | Windows キー |

ポイントは、**Command 用のキーを Win キーそのものにはしない**こと。

- 左◇ → `F23`
- 右◇ → `F24`

として Windows に送信し、AutoHotkey で Command として扱う。

これにより、Command と Windows キーを完全に分離できる。

---

# 1. 前提

想定キーボード:

- HHKB Professional HYBRID Type-S US 配列
- または F23 / F24 をキーマップ変更ツールから割り当てられる HHKB Professional

2026年3月5日公開の対応ファームウェア以降では、HHKB Professional のキーマップ変更ツールから `F13`〜`F24` を割り当て可能。

HHKB Professional HYBRID Type-S / HYBRID 英語配列の場合は、ファームウェア `A0.48` 以降を使用する。

---

# 2. HHKB のファームウェアを更新

PFU 公式の **HHKB Professional キーマップ変更ツール**を使用する。

公式ダウンロード:

https://happyhackingkb.com/jp/download/

## 手順

1. HHKB を USB ケーブルで Windows PC に接続する
2. HHKB Professional キーマップ変更ツールを起動する
3. 必要ならファームウェアを最新版へ更新する
4. キーマップ変更画面を開く

キーマップ変更ツールは Bluetooth 接続ではなく、USB 接続で使用する。

---

# 3. HHKB 純正キーマップ設定

## 標準レイヤー

スペースキー左右の◇キーを Command 専用キーとして使う。

```text
左◇ → F23
右◇ → F24
```

イメージ:

```text
Alt   左◇        Space        右◇   Alt
       │                       │
       └─ F23                  └─ F24
          Command                Command
```

Windows から見ると、

```text
F23 = 左 Command
F24 = 右 Command
```

になる。

## Fn レイヤー

Windows キーも使えるようにする。

Fn レイヤーへ切り替え、**左◇と同じ物理位置**に `Left Windows` を設定する。

```text
Fn + 左◇ → Left Windows
```

これで、

```text
左◇          → Command
Fn + 左◇     → Windows キー
```

として使い分けられる。

### HHKB 側の最終設定

```text
【標準レイヤー】

左◇ → F23
右◇ → F24


【Fn レイヤー】

Fn + 左◇ → Left Windows
```

その他のキーは基本的にデフォルトのままでよい。

---

# 4. Windows を US 配列にする

HHKB US 配列を刻印どおりに使うため、Windows 側のハードウェアキーボードレイアウトを US / 101・102 キーにする。

Windows 11 では、おおむね以下から設定する。

```text
設定
  ↓
時刻と言語
  ↓
言語と地域
  ↓
日本語
  ↓
言語のオプション
  ↓
ハードウェア キーボード レイアウト
  ↓
英語キーボード (101/102 キー)
```

変更後、Windows の再起動またはサインアウトを求められた場合は実施する。

これで US 配列の、

```text
[ ] \ ; ' , . /
```

などが刻印どおりになりやすい。

---

# 5. AutoHotkey v2 をインストール

AutoHotkey v2 をインストールする。

公式:

https://www.autohotkey.com/

インストール後、任意の場所に次のファイルを作る。

```text
hhkb.ahk
```

---

# 6. AutoHotkey の設定

以下を `hhkb.ahk` に保存する。

```ahk
#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; HHKB Windows Mac-like keymap
;
; HHKB標準レイヤー
;   左◇ = F23
;   右◇ = F24
;
; HHKB Fnレイヤー
;   Fn + 左◇ = Left Windows
; ============================================================


; ------------------------------------------------------------
; Command 単押し
; ------------------------------------------------------------

; 左Command → 英数 / IME OFF
F23::Send "{vk1A}"

; 右Command → かな / IME ON
F24::Send "{vk16}"


; ------------------------------------------------------------
; 左Command(F23) + 基本ショートカット
; ------------------------------------------------------------

F23 & c::Send "^c"
F23 & v::Send "^v"
F23 & x::Send "^x"
F23 & z::Send "^z"
F23 & a::Send "^a"
F23 & s::Send "^s"
F23 & f::Send "^f"
F23 & t::Send "^t"
F23 & w::Send "^w"
F23 & n::Send "^n"
F23 & o::Send "^o"
F23 & p::Send "^p"
F23 & r::Send "^r"

; アプリ切り替え
F23 & Tab::Send "!{Tab}"


; ------------------------------------------------------------
; 右Command(F24) + 基本ショートカット
; 左右どちらのCommandでも同じショートカットを使えるようにする
; ------------------------------------------------------------

F24 & c::Send "^c"
F24 & v::Send "^v"
F24 & x::Send "^x"
F24 & z::Send "^z"
F24 & a::Send "^a"
F24 & s::Send "^s"
F24 & f::Send "^f"
F24 & t::Send "^t"
F24 & w::Send "^w"
F24 & n::Send "^n"
F24 & o::Send "^o"
F24 & p::Send "^p"
F24 & r::Send "^r"

; アプリ切り替え
F24 & Tab::Send "!{Tab}"
```

AutoHotkey のカスタムコンビネーションでは、`F23 & c` のように通常の修飾キー以外も組み合わせキーとして使える。

---

# 7. 英数 / かな切り替え

上の設定では Windows の Virtual-Key Code を直接送信する。

```text
vk1A = VK_IME_OFF
vk16 = VK_IME_ON
```

そのため、

```text
左◇ 単押し → IME OFF → 英数
右◇ 単押し → IME ON  → かな
```

となる。

トグル方式ではないため、

```text
左 = 必ず英数
右 = 必ず日本語
```

という Mac の英数 / かなキーに近い挙動になる。

## もし IME ON / OFF が効かない場合

環境や IME によって直接の `VK_IME_ON` / `VK_IME_OFF` が期待どおり動作しない場合は、Microsoft IME のキー設定を使う。

AutoHotkey を次のように変更する。

```ahk
; 左Command → 無変換
F23::Send "{vk1D}"

; 右Command → 変換
F24::Send "{vk1C}"
```

Windows / Microsoft IME 側で、

```text
無変換 → IME OFF
変換   → IME ON
```

に割り当てる。

Virtual-Key Code は、

```text
vk1D = VK_NONCONVERT
vk1C = VK_CONVERT
```

となる。

---

# 8. Command + Shift 系

AutoHotkey のカスタムコンビネーションは Shift を押した状態でも反応する。

まず以下を試す。

```text
Command + Shift + Z
Command + Shift + T
Command + Shift + Tab
```

アプリによって期待した動作にならない場合は、個別ショートカットとして追加する。

例:

```ahk
; 必要になった場合だけ追加
; Shift の状態を確認して専用処理を作る
```

普段使うアプリに合わせて後から追加するのがおすすめ。

---

# 9. Windows キー

Command 用に Win キーを潰していないため、Windows キーは HHKB の Fn レイヤーから直接出す。

```text
Fn + 左◇
    ↓
Left Windows
```

使用例:

```text
Fn + 左◇                 → スタートメニュー
Fn + 左◇ + E             → エクスプローラー
Fn + 左◇ + R             → ファイル名を指定して実行
Fn + 左◇ + I             → Windows 設定
```

HHKB 本体が `Left Windows` を直接送るため、この部分に AutoHotkey は不要。

---

# 10. 最終的なキー配置

```text
                    HHKB US / Windows

┌──────────────────────────────────────────────────┐
│                                                  │
│               通常の US 配列                     │
│                                                  │
│        Alt   F23       Space       F24   Alt      │
│              │                      │             │
│              │                      │             │
│        左 Command              右 Command          │
│        単押し: 英数            単押し: かな        │
│                                                  │
└──────────────────────────────────────────────────┘


Fn + 左 Command位置 → Windows キー
```

---

# 11. Mac と Windows の対応

| Mac | HHKB + Windows |
|---|---|
| 左 Command | 左◇ / F23 |
| 右 Command | 右◇ / F24 |
| 英数 | 左◇単押し |
| かな | 右◇単押し |
| Command + C | 左/右◇ + C |
| Command + V | 左/右◇ + V |
| Command + Z | 左/右◇ + Z |
| Command + A | 左/右◇ + A |
| Command + S | 左/右◇ + S |
| Command + F | 左/右◇ + F |
| Command + T | 左/右◇ + T |
| Command + W | 左/右◇ + W |
| Command + Tab | 左/右◇ + Tab |
| Windows キー | Fn + 左◇ |

---

# 12. 起動時に AutoHotkey を自動起動

毎回 `hhkb.ahk` を実行するのが面倒な場合は、Windows のスタートアップへ登録する。

`Win + R` を押して、

```text
shell:startup
```

を入力する。

開いたスタートアップフォルダへ `hhkb.ahk` のショートカットを置く。

これで Windows ログイン時に自動的に設定が有効になる。

---

# 13. 設定順序まとめ

この順番で設定すると分かりやすい。

1. HHKB を USB 接続
2. HHKB Professional キーマップ変更ツールをインストール
3. HHKB ファームウェアを最新版へ更新
4. 標準レイヤーで `左◇ → F23`
5. 標準レイヤーで `右◇ → F24`
6. Fn レイヤーで `左◇位置 → Left Windows`
7. Windows のキーボードレイアウトを `英語キーボード (101/102 キー)` にする
8. AutoHotkey v2 をインストール
9. `hhkb.ahk` を作成
10. AutoHotkey スクリプトを起動
11. 左◇で英数になることを確認
12. 右◇でかなになることを確認
13. `◇ + C`、`◇ + V` などを確認
14. `Fn + 左◇` で Windows キーが動くことを確認
15. 問題なければ `hhkb.ahk` をスタートアップへ登録

---

# 14. おすすめ完成形

```text
HHKB本体
────────────────────────
左◇          = F23
右◇          = F24
Fn + 左◇     = Left Windows


AutoHotkey
────────────────────────
F23 単押し   = 英数
F24 単押し   = かな

F23/F24 + C  = Ctrl + C
F23/F24 + V  = Ctrl + V
F23/F24 + X  = Ctrl + X
F23/F24 + Z  = Ctrl + Z
F23/F24 + A  = Ctrl + A
F23/F24 + S  = Ctrl + S
F23/F24 + F  = Ctrl + F
F23/F24 + T  = Ctrl + T
F23/F24 + W  = Ctrl + W
F23/F24 + Tab = Alt + Tab


Windows
────────────────────────
キーボード = 英語 101/102
IME         = Microsoft IME
```

この構成の狙いは、**Windows でも Mac と同じ Command の物理位置・英数/かなの指使いを維持しつつ、本来の Windows キーも残すこと**。

---

# 参考

- PFU HHKB ダウンロード / キーマップ変更ツール  
  https://happyhackingkb.com/jp/download/
- PFU HHKB ファームウェア更新履歴  
  https://happyhackingkb.com/jp/download/renewal-history.html
- Microsoft 日本語 IME  
  https://support.microsoft.com/ja-jp/windows/hardware/input-devices/microsoft-japanese-ime
- Microsoft Virtual-Key Codes  
  https://learn.microsoft.com/ja-jp/windows/win32/inputdev/virtual-key-codes
- AutoHotkey v2 Hotkeys  
  https://www.autohotkey.com/docs/v2/Hotkeys.htm
