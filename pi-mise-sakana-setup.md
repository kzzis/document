# Pi / Oh My Pi + Sakana AI セットアップ（Windows / PowerShell / mise）

Windows上のPowerShellで、Pi、Oh My Pi、Sakana AIをローカルへ導入する手順です。WSLではなく、Windowsネイティブ環境を前提とします。

- OS: Windows 10 / 11
- シェル: PowerShell
- ツール管理: mise
- Pi: `@earendil-works/pi-coding-agent`
- Oh My Pi: `can1357/oh-my-pi`
- モデル: Sakana Fugu / Sakana Namazu

PowerShell 5.1以降で実行できます。普段使いには、Windows TerminalとPowerShell 7の組み合わせを推奨します。

## 1. miseをインストールする

PowerShellを通常ユーザーとして開き、mise公式のWindows用インストーラーを実行します。管理者権限は不要です。

```powershell
irm https://mise.run/powershell | iex
```

PowerShellをいったん閉じ、新しいPowerShellを開いて確認します。

```powershell
mise --version
```

miseが見つからない場合は、PowerShellを開き直します。公式インストーラーはmiseを `$HOME\.local\bin` に配置し、そのディレクトリをユーザーの `Path` へ追加します。

## 2. PowerShellでmiseを有効にする

次のコマンドは、PowerShellのプロファイルを必要に応じて作成し、miseの有効化設定を重複せずに追加します。

```powershell
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$activation = '(&mise activate pwsh) | Out-String | Invoke-Expression'

if (-not (Select-String -Path $PROFILE -SimpleMatch $activation -Quiet)) {
    Add-Content -Path $PROFILE -Value $activation
}
```

PowerShellを開き直すか、現在のPowerShellへプロファイルを読み込みます。

```powershell
. $PROFILE
```

## 3. Node.jsとPiをmiseで導入する

```powershell
mise use -g node@lts
mise use -g npm:@earendil-works/pi-coding-agent@latest
```

確認します。

```powershell
node --version
pi --version
mise ls
```

この手順の作成時に確認したPiは `1.6.0` です。同じバージョンへ固定する場合は、次のように指定します。

```powershell
mise use -g npm:@earendil-works/pi-coding-agent@1.6.0
```

## 4. SakanaのAPIキーを設定する

### 現在のPowerShellだけで使う

```powershell
$env:SAKANA_API_KEY = 'SakanaのAPIキー'
```

この値はPowerShellを閉じると消えます。

### ユーザー環境変数として保存する

```powershell
[Environment]::SetEnvironmentVariable(
    'SAKANA_API_KEY',
    'SakanaのAPIキー',
    [EnvironmentVariableTarget]::User
)q
```

保存後はPowerShellを開き直します。環境変数へ保存したキーはWindowsのユーザー環境へ平文で保持されるため、端末のセキュリティ要件に応じて管理方法を選んでください。

値そのものを表示せずに、設定状態を確認します。

```powershell
if ($env:SAKANA_API_KEY) {
    Write-Host 'SAKANA_API_KEY: OK'
} else {
    Write-Host 'SAKANA_API_KEY: 未設定'
}
```

## 5. SakanaモデルをPiへ登録する

Piの設定ディレクトリを作成します。

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\.pi\agent" | Out-Null
```

`models.json` をメモ帳で開きます。

```powershell
notepad.exe "$HOME\.pi\agent\models.json"
```

ファイルが存在しないと表示された場合は、作成を選択します。次の内容を保存してください。

```json
{
  "$schema": "https://pi.dev/schemas/models.schema.json",
  "providers": {
    "sakana": {
      "name": "Sakana AI",
      "baseUrl": "https://api.sakana.ai/v1",
      "api": "openai-responses",
      "apiKey": "$SAKANA_API_KEY",
      "authHeader": true,
      "models": [
        {
          "id": "fugu",
          "name": "Sakana Fugu",
          "reasoning": true,
          "thinkingLevelMap": {
            "off": null,
            "minimal": null,
            "low": null,
            "medium": null,
            "high": "high",
            "xhigh": "xhigh",
            "max": "max"
          },
          "input": ["text", "image"],
          "contextWindow": 1000000
        },
        {
          "id": "sakana-namazu",
          "name": "Sakana Namazu",
          "input": ["text", "image"]
        }
      ]
    }
  }
}
```

`apiKey` の `$SAKANA_API_KEY` は、Piが環境変数を参照するための公式構文です。

PowerShell標準機能でJSONの構文を確認します。

```powershell
Get-Content "$HOME\.pi\agent\models.json" -Raw |
    ConvertFrom-Json |
    Out-Null

Write-Host 'models.json: OK'
```

登録モデルと認証を確認します。

```powershell
pi --list-models sakana
pi auth check --provider sakana
```

## 6. Piを起動する

作業ディレクトリを作成して移動します。

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\Dev" | Out-Null
Set-Location "$HOME\Dev"
```

Fuguで起動します。

```powershell
pi --provider sakana --model fugu
```

Namazuで起動する場合:

```powershell
pi --provider sakana --model sakana-namazu
```

Pi内では `/model` からモデルを切り替えることもできます。

## 7. Oh My Piを導入する

Oh My Pi（OMP）はPiの拡張ではなく、Piから派生した別のコーディングエージェントです。`pi` と `omp` は別コマンドなので、同じPCへ併存できます。

miseでOh My Piを導入します。

```powershell
mise use -g github:can1357/oh-my-pi
```

確認します。

```powershell
omp --version
```

### SakanaモデルをOh My Piへ登録する

Oh My PiはPiの `$HOME\.pi\agent\models.json` をそのまま使用しません。Oh My Pi用の設定ディレクトリと `models.yml` を作成します。

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\.omp\agent" | Out-Null
notepad.exe "$HOME\.omp\agent\models.yml"
```

次の内容を保存します。

```yaml
providers:
  sakana:
    name: Sakana AI
    baseUrl: https://api.sakana.ai/v1
    api: openai-responses
    apiKey: SAKANA_API_KEY
    authHeader: true
    models:
      - id: fugu
        name: Sakana Fugu
        reasoning: true
        input: [text, image]
        contextWindow: 1000000
      - id: sakana-namazu
        name: Sakana Namazu
        input: [text, image]
```

Oh My Piの `apiKey: SAKANA_API_KEY` は、同名の環境変数を参照します。PiのJSON設定で使用する `"$SAKANA_API_KEY"` とは記法が異なります。

登録結果を確認します。

```powershell
omp models find sakana
```

Fuguで起動します。

```powershell
Set-Location "$HOME\Dev"
omp --model sakana/fugu
```

Namazuで起動する場合:

```powershell
omp --model sakana/sakana-namazu
```

Oh My Pi内では `/model` または `/models` からモデルを切り替えられます。

## 8. 更新する

mise管理のNode.js、Pi、Oh My Piを更新します。

```powershell
mise upgrade
```

更新後に確認します。

```powershell
pi --version
omp --version
mise ls
```

## トラブルシューティング

### `mise` が見つからない

PowerShellを閉じて開き直します。それでも見つからない場合は、インストール先を直接確認します。

```powershell
Test-Path "$HOME\.local\bin\mise.exe"
& "$HOME\.local\bin\mise.exe" --version
```

### `pi` または `node` が見つからない

現在のPowerShellだけmiseを有効にします。

```powershell
(&mise activate pwsh) | Out-String | Invoke-Expression
```

または、mise経由で直接確認します。

```powershell
mise exec -- pi --version
mise exec -- node --version
```

`mise exec -- pi` では動く場合、`$PROFILE` の有効化設定を確認してPowerShellを開き直します。

### `omp` が見つからない

現在のPowerShellだけmiseを有効にし、mise経由で確認します。

```powershell
(&mise activate pwsh) | Out-String | Invoke-Expression
mise exec -- omp --version
```

`mise ls` に `github:can1357/oh-my-pi` がなければ、もう一度導入します。

```powershell
mise use -g github:can1357/oh-my-pi
```

### PowerShellプロファイルを実行できない

実行ポリシーを確認します。

```powershell
Get-ExecutionPolicy -List
```

組織管理PCではポリシーを変更せず、管理者の方針に従ってください。プロファイルを利用できない場合でも、`mise exec -- pi` でPiを起動できます。

### `No API key found for sakana`

値を表示せず、現在のPowerShellに環境変数があるか確認します。

```powershell
[bool]$env:SAKANA_API_KEY
```

`False` の場合は、APIキーを設定してから同じPowerShell上でPiを起動します。ユーザー環境変数として保存した直後は、新しいPowerShellを開いてください。

### `models.json` のJSONエラー

```powershell
Get-Content "$HOME\.pi\agent\models.json" -Raw | ConvertFrom-Json
```

エラー位置を確認し、末尾の余分なカンマ、引用符、波括弧の対応を修正します。

### Oh My PiでSakanaモデルが表示されない

環境変数とモデル設定を確認します。

```powershell
[bool]$env:SAKANA_API_KEY
Get-Content "$HOME\.omp\agent\models.yml"
omp models find sakana
```

`apiKey` はドル記号を付けず、`SAKANA_API_KEY` と記述します。ユーザー環境変数を設定した直後は、新しいPowerShellを開いてください。

## 参照先

- [mise公式: Windowsへのインストール](https://mise.jdx.dev/installing-mise.html#windows)
- [mise公式: PowerShellの有効化](https://mise.jdx.dev/shell-setup.html#powershell)
- [Piリポジトリ](https://github.com/earendil-works/pi)
- [Pi: models.jsonの設定](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/models-configuration.md)
- [Pi: モデル設定](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/models.md)
- [Oh My Piリポジトリ](https://github.com/can1357/oh-my-pi)
- [Oh My Pi: モデル設定](https://github.com/can1357/oh-my-pi/blob/main/docs/models.md)
- [Oh My Pi: プロバイダー設定](https://github.com/can1357/oh-my-pi/blob/main/docs/providers.md)
