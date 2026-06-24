# 外部DB接続 切り替え設計 提案

**InventoryWeb バックエンド アーキテクチャ**

---

## 1. 背景と課題

### 現状

- 外部データ（在庫・BOM・生産指示）は **AS400（MES）** から取得
- 将来的に **mcframe ERP** への移行が確定している
- mcframe は **DB直接接続** または **API接続** の可能性がある

### 課題

何も対策しなければ、移行時に以下が発生する。

```
AS400のカラム変更・mcframe移行
    ↓
Repository・Service・UseCase・Controller
すべてのレイヤーに影響が波及
```

---

## 2. 方針

> **AS400の詳細を1箇所に閉じ込め、切り替え時の影響範囲をGateway1クラスに限定する**

- Application層（Service / UseCase）は外部DBの都合を知らない
- 接続方式（DB直接・API・gRPC）が変わっても上位レイヤーはノータッチ
- 立ち上げフェーズで構造を作っておくことで、将来の手戻りをゼロにする

---

## 3. アーキテクチャ

### レイヤー構成

```
Controller
    ↓
UseCase / Service         ← StockInfo など「ドメインモデル」しか見ない
    ↓
IExternalDbGateway        ← 抽象インターフェース（変わらない）
    ↓
As400Gateway              ← 今はここだけ実装
McframeGateway            ← 移行時に追加、差し替え
ShadowGateway             ← 並走検証期間に使用
```

### ディレクトリ構成

```
Infrastructure/
├── Gateway/
│   ├── IExternalDbGateway.cs       ← 抽象（変わらない）
│   ├── As400/
│   │   ├── As400Gateway.cs         ← 今の実装（将来削除）
│   │   └── Records/
│   │       └── As400StockRecord.cs ← AS400由来の型をここに隔離
│   ├── Mcframe/
│   │   ├── McframeGateway.cs       ← 移行時に追加
│   │   └── Records/
│   │       └── McframeStockResponse.cs
│   └── Shadow/
│       └── ShadowGateway.cs        ← 並走検証用
Domain/
└── Models/
    └── StockInfo.cs                ← Serviceが参照するドメインモデル
```

---

## 4. 実装方針

### 4-1. インターフェース（変わらない）

```csharp
// Infrastructure/Gateway/IExternalDbGateway.cs
public interface IExternalDbGateway
{
    Task<StockInfo?> GetStockAsync(string partNo);
    Task<IEnumerable<BomItem>> GetBomAsync(string partNo);
    Task<IEnumerable<ProductionOrder>> GetProductionOrdersAsync(string partNo);
}
```

### 4-2. ドメインモデル（変わらない）

```csharp
// Domain/Models/StockInfo.cs
public record StockInfo
{
    public string PartNo { get; init; } = "";
    public decimal AvailableQty { get; init; }
    public string Unit { get; init; } = "";
}
```

### 4-3. AS400 Gateway（現行・将来削除予定）

```csharp
/// <summary>
/// AS400(MES)接続の暫定実装。
/// mcframe移行時は McframeGateway に差し替え、このクラスは削除する。
/// </summary>
public class As400Gateway : IExternalDbGateway
{
    public async Task<StockInfo?> GetStockAsync(string partNo)
    {
        const string sql = """
            SELECT PART_NO, STOCK_QTY, UNIT
            FROM MESLIB.STOCKMST
            WHERE PART_NO = @partNo
            """;

        var record = await conn.QueryFirstOrDefaultAsync<As400StockRecord>(sql, new { partNo });
        if (record is null) return null;

        // AS400の都合はここで完結。上位には漏らさない。
        return new StockInfo
        {
            PartNo = record.PartNo,
            AvailableQty = record.StockQty,
            Unit = record.Unit
        };
    }
}
```

### 4-4. mcframe Gateway（API接続の場合も同じ構造）

```csharp
public class McframeGateway : IExternalDbGateway
{
    public async Task<StockInfo?> GetStockAsync(string partNo)
    {
        // DB直接・API・いずれの場合もここで吸収
        // カラム分割・名前変更・単位変換もここで完結
        return new StockInfo
        {
            PartNo = r.ItemCode,
            AvailableQty = r.AvailableQty - r.ReservedQty,
            Unit = ConvertUnit(r.UnitCode)
        };
    }
}
```

### 4-5. DI 切り替え

```csharp
// appsettings.json の1行を変えるだけで切り替え完了
var provider = config["ExternalDb:Provider"];

switch (provider)
{
    case "AS400":   services.AddScoped<IExternalDbGateway, As400Gateway>();    break;
    case "Shadow":  services.AddScoped<IExternalDbGateway, ShadowGateway>();   break;
    case "Mcframe": services.AddScoped<IExternalDbGateway, McframeGateway>();  break;
}
```

```json
{
  "ExternalDb": {
    "Provider": "AS400"
  }
}
```

---

## 5. モデル自動生成（scaffold）について

### 採用しない

| 対象DB | 方式 | 理由 |
|---|---|---|
| PostgreSQL（自社管理） | EF Core Code First + Migration | 変更を自分たちで管理できる |
| AS400 | Dapper + 手書きRecord | 他システム管理、必要カラムのみ取得 |
| mcframe（将来） | Dapper or HttpClient + 手書きRecord | 同上 |

### scaffold を使わない理由

- AS400・mcframe は**自分たちで管理できない**DBであり、再生成のたびに差分が発生する
- 自動生成ファイルは Git diff が大量になりレビューが困難
- 不要なカラムまでモデルに含まれ、ドメインモデルとの境界が曖昧になる

---

## 6. 移行フェーズ

### フェーズ全体像

```
Phase 0: 準備・調査          ← 今
Phase 1: 並走（Shadow Mode）
Phase 2: 検証・差異吸収
Phase 3: 切り替え（設定1行）
Phase 4: AS400接続撤去
```

### Phase 0：準備・調査

| 確認項目 | 担当 |
|---|---|
| mcframe DB直接接続可否（ベンダー確認） | PJ責任者 |
| mcframe テーブル定義・カラム名取得 | ベンダー／DBA |
| 品番体系の一致確認（コード変換要否） | 業務担当 |
| 読み取り専用ユーザーの発行 | DBA |

> mcframeベンダーがDB直接接続を許可しないケースがある。**最初に確認必須。**  
> API提供の場合も Gateway パターンで対応可能。構造は変わらない。

### Phase 1：Shadow Mode（並走）

本番はAS400の結果を返しつつ、mcframeの結果を裏で取得してログに差異を記録する。

```csharp
public async Task<StockInfo?> GetStockAsync(string partNo)
{
    var primary = await _as400.GetStockAsync(partNo);   // 本番に返す

    _ = CompareAsync(partNo, primary);                  // 裏で差異ログ取得

    return primary;
}
```

### Phase 2：差異吸収

Shadow ログを1〜2週間収集し、差異を分析・対処する。

| 差異パターン | 対処 |
|---|---|
| 品番コード体系の違い | McframeGateway 内で変換ロジック追加 |
| 在庫更新タイミングのズレ | 業務要件として許容範囲を確認 |
| カラム分割・名前変更 | McframeGateway 内で吸収 |
| 単位・桁の違い | Gateway 内の変換メソッドで対処 |

### Phase 3：切り替え

```json
// appsettings.Production.json の1行変更のみ
{
  "ExternalDb": {
    "Provider": "Mcframe"
  }
}
```

コード変更なし。問題があれば `"AS400"` に即時ロールバック可能。

### Phase 4：撤去

安定確認後（1〜2週間）に不要コードを削除する。

```
削除対象：
- Infrastructure/Gateway/As400/
- Infrastructure/Gateway/Shadow/
- ConnectionStrings.As400
- appsettings の AS400 / Shadow 分岐
- ODBCドライバ（サーバーから）
```

### タイムライン目安

| Phase | 期間 | 備考 |
|---|---|---|
| Phase 0 | 2〜3週間 | mcframeベンダー調整待ちが支配的 |
| Phase 1 | 1週間 | Shadow実装・本番投入 |
| Phase 2 | 2〜4週間 | 差異の多さによる |
| Phase 3 | 1日 | 設定変更・デプロイ・監視 |
| Phase 4 | 1〜2週間 | 安定確認後に撤去 |

---

## 7. 変更影響まとめ

### 各フェーズでの作業スコープ

| タイミング | 作業内容 | 影響範囲 |
|---|---|---|
| 今（立ち上げ） | As400Gateway 実装、DI に switch 追加 | Infrastructure のみ |
| Shadow 期間 | ShadowGateway 追加 | Infrastructure のみ |
| mcframe 切り替え | McframeGateway 追加、設定1行変更 | Infrastructure のみ |
| AS400 撤去 | As400Gateway・ShadowGateway 削除 | Infrastructure のみ |
| **Service / UseCase / Controller** | **ずっとノータッチ** | — |

### カラム変更が来た場合

```
AS400のカラム変更
    ↓ scaffold 再生成不要（手書きRecordのため）
As400Gateway の ToStockInfo() でコンパイルエラー
    ↓
Gateway 内だけ修正
    ↓
Service 以上はノータッチ
```

---

## 8. ADR（アーキテクチャ決定記録）

```markdown
## ADR-001: 外部DB接続に Gateway パターンを採用

### 決定
IExternalDbGateway を介して外部DBアクセスを抽象化する

### 理由
- 現行: AS400(MES) との連携が必須
- 確定事項: 将来 mcframe ERP へ移行予定
- 接続方式（DB直接・API）が未確定のため、切り替えコストを最小化する

### 切り替え手順
1. McframeGateway を実装
2. appsettings の Provider を "Mcframe" に変更してデプロイ
3. 安定確認後、As400Gateway を削除

### 対象ファイル
- Infrastructure/Gateway/IExternalDbGateway.cs  ← 変更しない
- Infrastructure/Gateway/As400/As400Gateway.cs  ← 将来削除
- Infrastructure/Gateway/Mcframe/McframeGateway.cs ← 移行時追加
```

---

*作成日: 2026年6月*
