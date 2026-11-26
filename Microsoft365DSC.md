# Microsoft365DSC 導入・構成管理資料

## 1. 目的
Microsoft 365 E3 の既存テナントの設定をコード化し、棚卸し、変更履歴管理、監査、構成ドリフト検知、検証環境への展開を実現する。

## 2. Microsoft365DSC とは
Microsoft 365 向けの Desired State Configuration (DSC) リソースを提供する OSS。MIT ライセンスで商用・社内利用が可能。再配布時には著作権・ライセンス表記を保持する。依存モジュールのライセンスは別途確認する。Microsoft の正式な製品サポートとは区別する。

## 3. 前提条件
- Microsoft 365 E3（Entra ID P1 を含む）。Office 365 E3 とは区別する。
- Windows PC または Windows Server、導入バージョンが要求する PowerShell / DSC 実行環境。
- Microsoft の認証・管理 API への HTTPS 通信。通常、受信ポートの開放は不要。
- 対象サービスのライセンス、API 権限、管理ロール。
- 専用 Azure VM や追加の Azure 契約は原則不要。

E3 でも利用可能だが、E5 固有の機能は対象外となる場合がある。Teams は契約内容に依存する。

## 4. 内部構造

```mermaid
flowchart TD
    A[ローカル Windows / PowerShell] --> B[Microsoft365DSC]
    B --> C[DSC リソース]
    C --> D[Graph SDK / Exchange / Teams / PnP]
    D --> E[Microsoft 365 管理 API]
    D --> F[Entra ID OAuth 2.0 認証]
    E --> G[設定の取得・正規化]
    G --> H[DSC 構成ファイル]
```

各リソースは Get-TargetResource（取得）、Test-TargetResource（比較）、Set-TargetResource（適用）、Export-TargetResource（エクスポート）などを実装する。サービスごとに必要なトークンや権限は異なる。

## 5. 取得対象

| サービス | 主な設定 | 注意点 |
|---|---|---|
| Entra ID | 条件付きアクセス、認証、ユーザー、グループ、アプリ | P2 固有機能は別途契約 |
| Exchange | 組織設定、メールフロールール | メール本文は対象外 |
| SharePoint / OneDrive | 共有、サイト、テナント設定 | ファイル内容は対象外 |
| Teams | 会議、外部アクセス等のポリシー | 契約に依存 |
| Intune | 構成・準拠ポリシー | 追加機能は契約に依存 |
| Purview | DLP、保持等 | ライセンス・権限に依存 |

すべての設定が取得できるわけではない。対応リソース一覧と実際の取得結果を確認する。

## 6. 初期導入と手動エクスポート

導入前に公式ドキュメントで対象リリースの PowerShell 要件を確認する。以下はコマンド例であり、実テナントで未検証。

```powershell
Install-Module Microsoft365DSC -Scope CurrentUser -Force
Update-M365DSCDependencies
Set-M365DSCTelemetryOption -Enabled $false
Get-Command Export-M365DSCConfiguration -Syntax
Export-M365DSCConfiguration -LaunchWebUI
```

Export Generator で対象リソースと認証方式を選び、生成されたコマンドをローカルで実行する。MFA がある環境では対応する対話認証または証明書認証を選ぶ。最初は Entra ID の少数リソースから検証する。

取得対象の例：AADConditionalAccessPolicy、AADTenantDetails。必要権限は次のコマンドで確認する。

```powershell
Get-M365DSCCompiledPermissionList -ResourceNameList @(
    'AADTenantDetails',
    'AADConditionalAccessPolicy'
)
```

出力された Read / Update 権限を区別し、取得専用アプリには必要な読み取り権限のみを付与する。サービス固有の管理ロールも確認する。

## 7. 定期取得の推奨構成

```mermaid
flowchart TD
    A[Microsoft 365 E3] -->|HTTPS / 読み取り| B[Windows Server / Microsoft365DSC]
    C[Entra ID アプリ登録 / 証明書] --> B
    D[タスクスケジューラ または Self-hosted Runner] --> B
    B --> E[ローカル出力 / 機密情報検査]
    E --> F[承認済み Private Git Repository]
    F --> G[差分検知・レビュー・通知]
```

- 取得専用の Entra ID アプリ登録と証明書認証を使用する。リソースごとのアプリ認証対応を確認する。
- 毎日1回の実行を初期案とする。頻度は運用要件に合わせて決定する。
- 証明書秘密鍵は OS の証明書ストア等で保護し、有効期限と更新を管理する。
- Git への保存は社内規程に従い、機密情報を検査してから実施する。
- API エラー、権限不足、取得件数、終了状態を記録し、部分取得を正常な設定削除と誤認しない。
- 出力の順序や揮発性プロパティによる不要な差分を抑える。モジュールバージョンを固定・記録する。

## 8. 環境再構築と構成適用

DSC 構成ファイルを利用して、対応する設定を別テナントへ適用できる。ただし、完全なテナント複製ではない。

1. 既存テナントから設定を取得する。
2. テナント ID、ドメイン、ユーザー・グループ ID、アプリ ID などを移行先に合わせる。
3. ライセンス、依存関係、対象リソースの適用可否を確認する。
4. 検証テナントで構成をコンパイル・比較し、対応する DSC 実行方式で適用する。
5. 再取得して期待する設定と比較する。
6. 本番適用は別の更新専用 ID、承認、変更計画、復旧手順を用意して実施する。

ユーザーパスワード、メール本文、ファイル内容、チャット履歴、秘密鍵、テナント契約自体はこの方法による完全復元の対象外。設定の復旧もリソースの対応状況に依存する。条件付きアクセス変更では管理者のロックアウト対策を必須とする。

## 9. 導入ステップ

| フェーズ | 実施内容 | 完了条件 |
|---|---|---|
| PoC | ローカルで Entra ID の少数設定を取得 | 管理画面と取得結果が一致 |
| 棚卸し | 対象サービスを拡大 | 取得成功・失敗・対象外を一覧化 |
| 自動化 | 証明書認証、定期実行、Git 差分 | 無人取得と異常通知を確認 |
| 構成管理 | 検証環境で適用・比較 | 変更結果と復旧手順を確認 |
| 本番展開 | 承認付き変更管理 | 権限分離・監査証跡を確保 |

## 10. セキュリティと制約
- 取得処理はローカルで動作するが、Microsoft のクラウド API との通信が必要。
- テレメトリ無効化だけで全依存モジュールの外部通信がなくなるとは限らない。
- 管理者権限の常用を避け、取得と適用の ID を分離する。
- Git の非公開設定だけに依存せず、アクセス制御、秘密情報検査、保持期間を定義する。
- 設定スナップショットは Microsoft 365 のデータバックアップの代替ではない。

## 11. 参考情報
- 公式プロジェクト: https://microsoft365dsc.com/
- ソースコード・ライセンス: https://github.com/microsoft/Microsoft365DSC
- Export Generator: https://export.microsoft365dsc.com/
- Microsoft Graph PowerShell: https://learn.microsoft.com/powershell/microsoftgraph/overview

## 12. 未確認事項
本資料は導入検討用。最新リリースの動作要件、個別リソースの対応状況、ライセンス原文、実テナントでの認証・取得・適用は未検証。毎日取得、Windows Server、Git 管理は推奨構成として仮定しており、確定要件ではない。
