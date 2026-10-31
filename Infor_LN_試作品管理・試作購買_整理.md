# Infor LNにおける試作品管理・試作購買の整理

- 作成日: 2026-10-31
- 対象: 新製品開発試作、顧客向けサンプル、設計から量産への移行、試作購買、案件別原価
- 想定製品: Infor LN
- 文書の目的: これまでの会話内容を整理し、RFPおよびベンダー確認に使用できる形にする

> **重要**
> 本書の「確認済」は、(1) 会話で業務要件として確認した事項、または (2) Infor公式資料で標準機能の存在を確認した事項を示す。導入予定バージョンでの利用可否、ライセンス、パラメータ、データ構成、操作手順、追加開発不要の保証を意味しない。これらは「要ベンダー確認」として区別する。

## 1. 結論

今回確認した範囲では、Infor LNに「試作品管理」という単一の正式機能を当てはめるのではなく、次の標準機能を組み合わせて実現性を評価するのが適切である。

- 設計品目・設計改訂・設計BOM: **Engineering Data Management**、**Engineering Item / Engineering Item Revision**、**Engineering BOM（EBOM）**
- 量産品目・量産BOM: **Item**、**Production BOM（PBOM）**
- 試作製造: **Production Order**（**Job Shop Control**）
- 案件との紐付け・案件別原価: **Project Pegging**
- 試作購買: **Purchase Requisition**、**Request for Quotation（RFQ）**、**Purchase Order**
- 入荷・検査・保管: **Warehousing**

Infor LNの標準機能には、設計品目の改訂管理、EBOM、設計データから生産用データへの移行、製造指図、購買依頼からRFQ／発注への変換、購買入荷、プロジェクトペグによる案件別の追跡に使える機能がある。一方、次は業務・システム設計に依存するため、ベンダーによるシナリオ実演と回答が必要である。

- 新製品開発試作と顧客向けサンプルを、どの品目区分・プロジェクト・オーダ種別で識別するか
- 試作の時点で Engineering Item のまま扱う範囲と、通常の Item／製造品目へ移行するタイミング
- 試作用BOMと量産PBOMを同じ構造で改訂管理するか、別構造にするか
- 試作製造を Production Order で実行するために必要な品目・BOM・工順の登録方法
- 品目未登録の購入要求を、RFQ、発注、入荷、検収、請求照合まで一貫処理できる範囲
- Project Peggingで取得できる案件別原価の粒度と会計連携
- 同一ERP環境内での論理会社、テーブル共有、物理データベースの構成

## 2. ステータスの定義

| 表記 | 意味 |
|---|---|
| **業務要件として確認済** | これまでの会話で、対象業務または必要性が明示されたもの |
| **Infor公式資料で確認済** | Infor公式資料上で、該当する標準機能または処理の存在を確認できたもの |
| **要ベンダー確認** | 導入バージョン、契約、設定、運用設計、データ構成、他機能との組合せ、追加開発の有無に依存するもの |

## 3. 会話で確認した対象範囲

### 3.1 試作の種類

以下の2種類を対象とすることは、**業務要件として確認済**である。

1. **新製品開発試作**
   - 量産前の設計検証、性能確認、製造性確認を目的とする試作
   - 設計改訂、試作BOM、試作部材の購入、社内製造、案件別原価の把握が必要
2. **顧客向けサンプル**
   - 顧客要求に基づくサンプル、評価品、特注試作品
   - 顧客・案件との紐付け、個別仕様、納期、調達・製造・入出庫、案件別原価の把握が必要

両者を同一の仕組みで扱うか、試作区分・オーダ種別・プロジェクト・品目グループなどで運用を分けるかは、**要ベンダー確認**である。

### 3.2 必要な業務領域

以下を一連の対象とすることは、**業務要件として確認済**である。

- 設計品目と改訂の管理
- 設計BOMと量産BOMの区別および移行
- 試作製造
- 試作購買（購買依頼、見積依頼、発注、入荷）
- 承認
- 案件別原価
- 品目未登録品の調達
- ERP環境、論理的なデータ分離、物理DBの関係整理

## 4. Infor LNの正式機能名称と位置付け

| 正式名称 | 日本語での位置付け | 試作業務での用途 | 状態 |
|---|---|---|---|
| **Engineering Data Management（EDM）** | 設計データ管理 | 製品設計中の品目、改訂、EBOMを管理し、生産用データへ移行する | **Infor公式資料で確認済** |
| **Engineering Item（E-item）** | 設計品目 | 開発中の品目を通常の生産・購買品目と区別して管理する | **Infor公式資料で確認済** |
| **Engineering Item Revision** | 設計品目改訂 | 試作1号、2号、設計変更などの改訂と状態を管理する | **Infor公式資料で確認済** |
| **Engineering BOM（EBOM）** | 設計BOM | 特定の設計品目改訂に対する構成部品を管理する | **Infor公式資料で確認済** |
| **Production BOM（PBOM）** | 生産／量産BOM | 製造で使用する正式な部品表を管理する | **Infor公式資料で確認済**。名称・データモデルはLNのバージョン／機能有効化状態により差異があり得るため要確認 |
| **Engineering Item - Item Relationship** | 設計品目と通常品目の関係 | 設計品目と生産・購買に使用するItemの対応付けに使う | **Infor公式資料で確認済** |
| **Finalize Engineering Data / EBOM-to-PBOM処理** | 設計から生産への移行 | 承認済みの設計改訂をItem／PBOMへ反映する候補処理 | **Infor公式資料で確認済**。自社想定の移行方法は要ベンダー確認 |
| **Production Order** | 製造指図 | 試作の材料、工順、数量、納期、実績、仕掛、完成、原価を管理する | **Infor公式資料で確認済** |
| **Job Shop Control** | 個別・ジョブショップ生産管理 | Production Orderの作成、計画、実行、実績、原価を管理する | **Infor公式資料で確認済** |
| **Project Pegging** | プロジェクトペギング | 購買、倉庫、製造の需要・供給・在庫・取引・原価を案件に紐付ける | **Infor公式資料で確認済** |
| **Purchase Requisition** | 購買依頼 | 試作部材・費用・サービスの購入要求、承認、RFQ／発注への変換 | **Infor公式資料で確認済** |
| **Request for Quotation（RFQ）** | 見積依頼 | 複数仕入先への見積依頼、回答、比較、選定 | **Infor公式資料で確認済** |
| **Purchase Order** | 購買発注 | 選定した仕入先への発注、納期・数量・価格の管理 | **Infor公式資料で確認済** |
| **Warehousing** | 倉庫管理 | 購買入荷、検査、入庫、保管、製造への払出、完成品入庫 | **Infor公式資料で確認済** |

> **補足:** LNのバージョンや Concept Activation の状態により、旧来のBOM、Production BOM、Job Shop BOMなどの用語・画面・移行方式が異なる可能性がある。RFPでは導入対象バージョンと有効化予定機能を明示させること。

## 5. 想定する試作品管理フロー

### 5.1 新製品開発試作

想定フローは次のとおりである。

1. **Engineering Item**を登録する
2. **Engineering Item Revision**を作成し、試作改訂を識別する
3. 改訂単位で**Engineering BOM**を作成する
4. 未手配部材について**Purchase Requisition**を作成する
5. 必要に応じて**RFQ**を実施し、回答比較・仕入先選定を行う
6. **Purchase Order**を発行する
7. **Warehousing**で受入、必要に応じて検査、入庫を行う
8. 社内製造分は**Production Order**で材料払出、作業実績、完成を記録する
9. **Project Pegging**で購買・倉庫・製造の数量と原価を試作案件に紐付ける
10. 評価結果に応じて新しい設計改訂を作成する
11. 量産移行時に承認済み改訂を通常の**Item**および**Production BOM**へ反映する

手順1～3、4～7、8、9、11に対応する標準機能の存在は**Infor公式資料で確認済**である。ただし、これらを自社の試作フローとして途切れなく使用できること、各処理間で引き継がれる項目、試作の時点で必要となるItem／PBOM登録のタイミングは**要ベンダー確認**である。

### 5.2 顧客向けサンプル

想定フローは次のとおりである。

1. 顧客、案件、要求仕様、希望納期、サンプル数量を登録する
2. 既存品流用か新規設計かを判定する
3. 新規設計の場合は**Engineering Item / Revision / EBOM**で仕様を管理する
4. 購入品は**Purchase Requisition → RFQ → Purchase Order → Warehousing**で手配する
5. 内作品は**Production Order**で製造する
6. **Project Pegging**で案件別に数量、在庫、取引、原価を追跡する
7. 顧客への出荷、評価結果、設計へのフィードバックを記録する

顧客要求を受ける起点をSales Order、Project、試作依頼の独自属性のいずれにするか、無償サンプルと有償サンプルをどう分けるか、出荷・売上・原価をどう処理するかは**要ベンダー確認**である。

## 6. 設計品目・EBOMと量産品目・PBOM

### 6.1 基本的な考え方

- **Engineering Item / Revision**は設計中の製品とその版を扱う。
- **Engineering BOM**は、特定のEngineering Item Revisionに対する設計構成を扱う。
- **Item / Production BOM**は、購買・製造・在庫などの実行業務で使用する生産用データである。
- Infor LNにはEngineering ItemとItemの関係付け、および設計データを生産用データへ移行する処理がある。

上記は**Infor公式資料で確認済**である。

### 6.2 試作で決める必要がある事項

次は**要ベンダー確認**である。

- 試作品ごとにEngineering Itemと通常Itemを別コードにするか
- Engineering Item RevisionとItem Revisionの対応関係
- 試作製造のProduction Orderを作成する時点で、通常Itemへの移行が必要か
- 試作BOMをEBOMだけで保持するか、試作用PBOM／Job Shop BOMも作成するか
- EBOMからPBOMへ全階層をコピーするか、承認対象だけを移行するか
- 既存PBOMを上書きするか、履歴・新改訂として残すか
- 図面、仕様書、検査記録をDocument Management／PLMとどう連携するか
- 設計承認、試作承認、量産移行承認をどの状態・ワークフローで表すか

## 7. 同一ERP環境と物理DBの区別

### 7.1 整理

「同じInfor LN環境を使う」ことと、「同じデータ領域・同じ物理DBを使う」ことは同義ではない。

- Infor LNの**Company**は、ユーザーの業務実行環境であり、会社番号でデータを分ける**論理データベース**に相当する。
- 1つのLNシステム内に複数Companyを構成できる。
- Companyごとにトランザクションを分離しつつ、品目など一部のテーブルを共有する構成が可能である。
- **Logical Company / Physical Company**および**Table Sharing**により、論理会社から別会社の物理テーブルを参照する構成が可能である。
- 同一ERP環境であっても、物理データベース、DBサーバー、スキーマ、テナントまで同一かどうかは導入アーキテクチャ次第である。

Companyが論理DBに相当し、Company間で一部テーブルを共有できることは**Infor公式資料で確認済**である。試作と量産をどのCompanyに置き、どのテーブルを共有し、物理DBをどう構成するかは**要ベンダー確認**である。

### 7.2 現時点の判断

試作業務のために、必ず量産とは別の物理DBを用意しなければならないとはいえない。候補は少なくとも次の3つである。

| 構成候補 | 概要 | 主な利点 | 主な確認点 |
|---|---|---|---|
| 同一Company・同一データ領域 | 試作区分、プロジェクト、品目、オーダ種別で識別 | マスタ・在庫・購買・製造の連携が容易 | 試作データと量産データの権限分離、誤使用防止 |
| 同一LN環境・別Company | 論理DBを分け、一部マスタを共有 | 業務データを分離しやすい | Company間連携、テーブル共有、移行、会計処理 |
| 別環境／別物理DB | 試作と量産を技術的に強く分離 | 隔離性が高い | マスタ同期、設計から量産への移送、運用・保守コスト |

推奨構成は、データ量、権限、変更頻度、量産への移行方法、会計単位、検証環境の用途を確認したうえで決定する。

## 8. 試作購買

### 8.1 標準機能で確認できる流れ

以下は**Infor公式資料で確認済**である。

1. **Purchase Requisition**を登録する
2. 購買依頼を承認者または承認者リストで承認／却下する
3. 承認済み購買依頼を**RFQ**または**Purchase Order**へ変換する
4. RFQを仕入先へ提示し、回答を受領・比較・選定する
5. Purchase Orderを発行する
6. Purchase Orderを**Warehousing**へリリースする
7. Warehousingで受入、必要に応じて入荷検査、入庫を行う
8. 入荷実績をProcurement側へ反映する

### 8.2 承認

Purchase Requisitionには、承認者／承認部門、承認階層、承認・却下、承認進捗に対応する標準機能がある。LN内承認または外部ワークフローを使う構成があり得る。

次は**要ベンダー確認**である。

- 金額、費目、案件、部門、緊急度に応じた承認経路の分岐
- 代理承認、督促、期限超過、差戻し、再申請
- RFQ、Purchase Order、価格差、納期変更に対する再承認
- Infor ION Workflow等を含む利用コンポーネントとライセンス
- 監査証跡、電子署名、職務分掌への対応

### 8.3 品目未登録調達

Infor公式用語のPurchase Requisitionは、標準品だけでなく、**nonstandard material、cost、service requirements**も対象に含む。したがって、品目マスタ登録前の要求を購買依頼として扱える可能性は、**Infor公式資料で確認済**である。

ただし、「品目未登録」の意味と後続処理は分けて確認する必要がある。

| 論点 | 状態 |
|---|---|
| 自由記述または非標準要求としてPurchase Requisitionを起票できるか | 標準機能の候補あり。具体的な入力項目は**要ベンダー確認** |
| 非標準要求をRFQへ変換できるか | **要ベンダー確認** |
| 品目コードを作らずPurchase Orderへ変換できるか | **要ベンダー確認** |
| 品目コードなしでWarehousing入荷・在庫計上できるか | **要ベンダー確認**。在庫管理対象なら通常は品目登録の要否を確認する |
| 費用・サービスとして検収・請求照合できるか | **要ベンダー確認** |
| 後から正式品目へ置換し、履歴を引き継げるか | **要ベンダー確認** |
| 非標準要求にもProject Peggingを付与できるか | **要ベンダー確認** |

品目未登録調達については、「購買依頼だけ非品目でよい」のか、「発注・入荷・在庫・原価まで品目コードなしで処理したい」のかをRFPで明確にする必要がある。

## 9. 案件別原価とProject Pegging

Project Peggingは、プロジェクトペグ対象品目について、需要と供給、在庫、取引をプロジェクトに紐付け、購買・倉庫・製造の各オーダにペグ配賦情報を持たせるための標準機能である。公式資料では、プロジェクト、活動、要素レベルでの追跡・原価把握、および購買・倉庫・ジョブショップオーダでのペグ配賦が説明されている。これは**Infor公式資料で確認済**である。

試作案件で必要な「案件別原価」を満たすには、次を**要ベンダー確認**とする。

- 原価集計単位: 試作案件、顧客案件、機種、改訂、試作号機、活動、要素
- 原価要素: 購入材料、内製材料、作業時間、外注、経費、物流費、不良・廃棄
- 予定原価、見積原価、実際原価、差異の比較
- 共通購入・まとめ発注を複数案件に配賦する方法
- 部分入荷、返品、代替材、追加工、手直しの案件配賦
- 試作用在庫を量産や別案件へ転用した場合のペグ移動と原価処理
- 財務会計、管理会計、プロジェクト会計への仕訳・連携
- Project Pegging、PCS Project、Infor LN Projectのどれをどの範囲で使うか

## 10. 確認済事項と要ベンダー確認事項の一覧

| ID | 項目 | 判定 | 備考 |
|---|---|---|---|
| C-01 | 新製品開発試作と顧客向けサンプルの双方を対象とする | **業務要件として確認済** | 会話で明示 |
| C-02 | Engineering ItemとRevisionを管理する標準機能がある | **Infor公式資料で確認済** | Engineering Data Management |
| C-03 | Revision単位のEngineering BOMを管理できる | **Infor公式資料で確認済** | EBOM |
| C-04 | 設計データからItem／PBOMへ移行する機能がある | **Infor公式資料で確認済** | パラメータ・移行方式は要確認 |
| C-05 | Production Orderで製造を管理できる | **Infor公式資料で確認済** | Job Shop Control |
| C-06 | Purchase Requisitionを承認し、RFQ／Purchase Orderへ変換する流れがある | **Infor公式資料で確認済** | 詳細設定は要確認 |
| C-07 | RFQ回答の受領・比較・選定に対応する機能がある | **Infor公式資料で確認済** | 仕入先連携方式は要確認 |
| C-08 | Purchase OrderをWarehousingへ連携し、入荷処理できる | **Infor公式資料で確認済** | 品目・費用・サービスで差異あり |
| C-09 | 購買依頼が非標準材料、費用、サービス要求を含み得る | **Infor公式資料で確認済** | 発注以降の非品目処理は要確認 |
| C-10 | Project Peggingで購買・倉庫・製造を案件に紐付けられる | **Infor公式資料で確認済** | 対象品目・原価粒度は要確認 |
| C-11 | Companyは論理DBに相当し、Company間でテーブル共有が可能 | **Infor公式資料で確認済** | 物理構成は要確認 |
| V-01 | 試作と量産を同一Companyに置くか | **要ベンダー確認** | データ・権限・会計・運用を比較 |
| V-02 | 試作と量産で物理DBを分ける必要があるか | **要ベンダー確認** | 非機能要件と移行方式で判断 |
| V-03 | 試作製造時の品目・BOM・工順の登録方式 | **要ベンダー確認** | 実機デモを要求 |
| V-04 | EBOMからPBOMへの移行・承認・履歴 | **要ベンダー確認** | 上書き／改訂／差分反映を確認 |
| V-05 | 顧客向けサンプルの受注・無償出荷・有償売上 | **要ベンダー確認** | Sales Order等との連携 |
| V-06 | 品目コードなしでのRFQ・発注・入荷・検収・請求照合 | **要ベンダー確認** | 処理段階ごとに回答を要求 |
| V-07 | 案件別原価の粒度と財務連携 | **要ベンダー確認** | Project Peggingの適用条件も確認 |
| V-08 | 各承認の経路、代理、差戻し、監査証跡 | **要ベンダー確認** | LN内／外部Workflowを確認 |

## 11. RFP記載用の要求事項

ベンダー回答は、各項目について少なくとも「標準」「パラメータ／マスタ設定」「アドオン」「外部連携」「運用回避」「対応不可」を区別し、対象バージョン、前提ライセンス、関連セッション、制約、概算工数を明記すること。

| 要求ID | 要求事項 | 優先度 | 想定するInfor LN機能 |
|---|---|---:|---|
| PRT-01 | 新製品開発試作と顧客向けサンプルを区別して管理できること | Must | Project Pegging、品目／オーダ属性等 |
| PRT-02 | 試作案件、顧客、機種、改訂、号機、担当、納期、状態を検索・追跡できること | Must | Project Pegging、追加情報項目等 |
| ENG-01 | 設計品目を量産品目と区別して登録できること | Must | Engineering Item |
| ENG-02 | 設計品目を改訂単位で管理し、状態、発効日、失効日、変更理由、承認履歴を保持できること | Must | Engineering Item Revision、Workflow |
| BOM-01 | 改訂単位のEngineering BOMを作成・比較・変更できること | Must | Engineering BOM |
| BOM-02 | 承認済みEBOMをItem／Production BOMへ統制された手順で移行できること | Must | Engineering Data Management、Production BOM |
| BOM-03 | 移行前後の対応関係、差分、履歴、再移行結果を追跡できること | Must | Engineering Item - Item Relationship等 |
| MFG-01 | 試作品をProduction Orderで製造し、材料、工順、数量、日程、実績を管理できること | Must | Production Order、Job Shop Control |
| MFG-02 | 試作途中の設計変更、材料変更、手直し、不良、廃棄を履歴付きで処理できること | Must | Production Order version／変更関連機能等 |
| PUR-01 | 試作部材・費用・サービスのPurchase Requisitionを登録できること | Must | Purchase Requisition |
| PUR-02 | 金額、部門、案件、費目等に応じて購買依頼を承認できること | Must | Requisition Approval、Workflow |
| PUR-03 | 購買依頼からRFQを作成し、複数仕入先の回答を比較・選定できること | Must | Request for Quotation |
| PUR-04 | 購買依頼またはRFQからPurchase Orderを作成できること | Must | Purchase Order |
| PUR-05 | 緊急購買、分割発注、複数案件のまとめ発注、部分入荷、返品に対応できること | Must | Procurement、Warehousing、Project Pegging |
| PUR-06 | 品目未登録の要求を起票し、必要な段階までRFQ・発注・検収へ引き継げること | Must | Nonstandard requisition等 |
| WH-01 | 発注に対して受入、入荷検査、入庫、保管、払出を実施できること | Must | Warehousing |
| CST-01 | 購買・倉庫・製造の予定／実際原価を試作案件別に集計できること | Must | Project Pegging、Production Order Costing |
| CST-02 | 案件、活動、要素、改訂、号機など必要な粒度で原価を照会できること | Must | Project Pegging、Project等 |
| DAT-01 | 同一LN環境内で試作と量産のデータを必要な範囲で分離できること | Must | Company、権限、オーダ／品目区分 |
| DAT-02 | 別Company構成の場合、共有するマスタと分離するトランザクションを定義できること | Must | Table Sharing Modeler |
| DAT-03 | 論理会社、物理会社、物理DB、DBサーバー、テナントの構成を提示すること | Must | Enterprise Server／導入アーキテクチャ |
| SEC-01 | 設計、購買、製造、倉庫、原価の権限と職務分掌を設定できること | Must | Authorization、Workflow |
| AUD-01 | 申請、承認、変更、発注、入荷、製造実績、原価の監査証跡を保持できること | Must | 各履歴・Workflow |
| INT-01 | 必要に応じてPLM、文書管理、会計、仕入先連携と接続できること | Should | ION、Document Management、API等 |

## 12. ベンダーへの質問文

以下は、そのままRFP質疑またはデモ依頼に使用できる質問文である。

### 12.1 全体・適用機能

1. Infor LNで、新製品開発試作と顧客向けサンプルをそれぞれどの標準機能、品目区分、オーダ種別、プロジェクト種別で管理する提案ですか。
2. 「試作品管理」として提示する機能のうち、Infor LN標準、設定対応、アドオン、外部製品連携、運用対応を明確に区分してください。
3. 回答の前提となるInfor LNの製品バージョン、リリース、Concept Activationの状態、必要ライセンスを提示してください。
4. 新製品開発試作と顧客向けサンプルについて、登録から完了までのEnd-to-Endデモを実施できますか。

### 12.2 設計品目・改訂・BOM

5. Engineering Item、Engineering Item Revision、通常のItemは、試作から量産までの各時点でどのように使い分けますか。
6. 試作1号、2号などの試作世代とEngineering Item Revisionをどのように対応させますか。
7. Engineering BOMの承認、凍結、発効、失効、変更理由、差分比較、履歴はどの標準機能で管理できますか。
8. 承認済みEngineering Item／EBOMを通常Item／Production BOMへ移行する標準手順を、関連セッション名とともに提示してください。
9. EBOMからPBOMへの移行時に、既存PBOMの上書き、改訂追加、差分反映、複数階層コピーをどのように制御しますか。
10. 試作段階のEBOMを用いてProduction Orderを作成するには、通常Item、PBOMまたはJob Shop BOMの事前作成が必要ですか。
11. 設計改訂後にすでに発行済みまたは着手済みのProduction Orderへ変更を反映する方法と制約を提示してください。

### 12.3 試作製造

12. Production Orderで、試作固有の材料、工順、作業時間、外注、不良、廃棄、手直し、完成を記録できますか。
13. 同じ設計改訂から複数の試作号機を製造した場合、号機別の材料・実績・原価をどのように識別しますか。
14. 試作途中の代替材、設計変更、追加工を、承認と履歴を保ったまま処理できますか。
15. 試作完成品を在庫に入れる場合と、在庫化せず顧客へ出荷する場合の標準フローをそれぞれ提示してください。

### 12.4 試作購買

16. Purchase RequisitionからRFQ、Purchase Order、Warehousing入荷まで、試作案件番号とプロジェクトペグはどの項目に引き継がれますか。
17. Purchase Requisitionの承認経路を、金額、部門、案件、費目、緊急度、仕入先などで分岐できますか。
18. 承認の代理、期限、督促、差戻し、再申請、再承認、監査証跡はどの機能で対応しますか。
19. RFQで複数仕入先への依頼、回答登録、価格・納期・条件比較、選定理由の保存を実施できますか。
20. 複数の試作案件の要求を1件のPurchase Orderにまとめた場合、発注明細、入荷、請求、原価を案件別に配賦できますか。
21. 部分入荷、過入荷、不足、検査不合格、返品、代替品の案件ペグと原価はどのように処理されますか。

### 12.5 品目未登録調達

22. 品目コード未登録の材料、費用、サービスをPurchase Requisitionに自由記述で登録できますか。
23. 品目コード未登録の要求をRFQへ変換する場合、説明、数量、単位、仕様書、希望納期、案件、見積回答は引き継がれますか。
24. 品目コードを作成せずPurchase Orderを発行できますか。可能な明細種別と制約を提示してください。
25. 品目コードなしでWarehousing入荷、入荷検査、在庫計上、製造への払出まで行えますか。できない場合、どの時点で品目登録が必須ですか。
26. 非品目の費用・サービスを検収し、請求書照合と案件別原価計上まで行えますか。
27. 購買依頼時は非標準要求として登録し、後から正式な品目コードへ置換する場合、元の申請、RFQ、発注、入荷との履歴関係を保持できますか。

### 12.6 案件別原価

28. Project Peggingにより、Purchase Requisition、RFQ、Purchase Order、Warehouse Order、Production Orderのどこまで同じ試作案件を引き継げますか。
29. 案件、活動、要素、改訂、号機別に、購入材料費、内製材料費、作業費、外注費、経費を集計できますか。
30. 予定原価、見積原価、実際原価、差異をどの画面・帳票で確認できますか。
31. 共通購入、まとめ発注、部分入荷、返品、転用、廃棄時の案件別原価配賦方法を提示してください。
32. Project Pegging、PCS Project、Infor LN Projectの適用範囲と、今回の試作業務に対する推奨構成を説明してください。

### 12.7 ERP環境・DB・データ共有

33. 提案構成では、試作と量産を同一Company、別Company、別テナント、別環境のいずれに配置しますか。その理由を提示してください。
34. Infor LNのCompany、Logical Company、Physical Company、物理DB、DBサーバー、テナントの対応関係を構成図で提示してください。
35. 試作と量産を別Companyにする場合、品目、取引先、設計データ、BOM、倉庫、購買、製造、会計の各テーブルを共有するか分離するか提示してください。
36. Table Sharingを使用する場合、共有対象、参照整合性、性能、障害時影響、変更管理、アップグレード上の制約を説明してください。
37. 試作から量産へ移行する際、Company間または環境間でItem、Revision、BOM、文書、原価履歴をどのように移送しますか。
38. 試作と量産を同一Companyにする場合、権限、ステータス、品目区分、倉庫、オーダ種別により誤使用を防止する方法を提示してください。

## 13. ベンダーデモの必須シナリオ

### デモ1: 新製品開発試作から量産移行

1. Engineering ItemとRevisionを新規登録
2. EBOMを作成
3. 試作部材の購買依頼、承認、RFQ、発注
4. 入荷・検査・入庫
5. Production Orderによる試作製造
6. 材料・作業・外注・経費の実績登録
7. Project Peggingによる案件別原価照会
8. 設計改訂
9. 承認済みEBOMからItem／PBOMへの量産移行
10. 移行前後の履歴・差分確認

### デモ2: 顧客向けサンプル

1. 顧客、案件、仕様、数量、納期の登録
2. 既存品流用と新規設計の両パターン
3. 購入・内製・外注を含む手配
4. 無償サンプルと有償サンプルの処理
5. 顧客出荷
6. 案件別原価と採算の確認

### デモ3: 品目未登録調達

1. 非標準材料または自由記述要求をPurchase Requisitionに登録
2. 承認
3. RFQと見積比較
4. Purchase Orderへの変換
5. 入荷またはサービス検収
6. 請求照合
7. Project Peggingによる案件別原価計上
8. 必要な時点で正式品目へ置換し、履歴を確認

### デモ4: 論理会社とデータ共有

1. 試作Companyと量産Companyの構成を表示
2. 共有マスタと非共有トランザクションを確認
3. Logical CompanyとPhysical Companyのテーブル対応を確認
4. 試作から量産への品目・BOM移行を実演
5. 権限分離と監査ログを確認

## 14. ベンダー回答フォーマット

各要求・質問に対し、次の形式で回答を求める。

| 項目 | 記載内容 |
|---|---|
| 対応区分 | 標準／設定／アドオン／外部連携／運用回避／対応不可 |
| 対象製品・バージョン | Infor LNのリリース、クラウド／オンプレミス等 |
| 機能・セッション | 正式機能名、セッション名、セッションコード |
| 前提条件 | Concept Activation、ライセンス、他モジュール、マスタ設定 |
| 処理概要 | 入力、承認、変換、連携、出力 |
| 制約 | 対象品目、状態、Company、ペグ、変更可否等 |
| 追加開発 | 必要性、方式、概算工数、保守影響 |
| データ移行 | 対象、方法、履歴、整合性 |
| 証跡 | 画面、帳票、API、公式ドキュメント、デモ結果 |

## 15. 公式資料の参照先

以下は、本書の機能名称および標準機能の存在確認に使用したInfor公式資料である。導入対象バージョンの資料で再確認すること。

- [Engineering data management summary / User Guide for Manufacturing](https://docs.infor.com/ln/10.7/en-us/lnolh/docs/ln_10.7_timanufactug__en-us.pdf)
- [Modifying Engineering Item Revision](https://docs.infor.com/ln/latest/en-us/lnolh/tiolh/tiom000735.html)
- [Engineering BOM (tiedm1110m000)](https://docs.infor.com/ln/10.7.in/en-us/lnolh/help/ti/edm/tiedm1110m000.html)
- [Engineering Data Management Parameters (tiedm0100m000)](https://docs.infor.com/ln/10.8/en-us/lnolh/tiolh/help/ti/edm/tiedm0100m000.html)
- [Production BOM glossary](https://docs.infor.com/ln/2026.x/en-us/lnolh/wholh/wholh-glossary.html)
- [Job Shop Control](https://docs.infor.com/ln/latest/en-us/lnolh/ffog/ffmanufacturingmanufacturing_ff_sfc.html)
- [Production Order (tisfc0101m100)](https://docs.infor.com/ln/2026.x/en-us/lnolh/tiolh/help/ti/sfc/tisfc0101m100.html)
- [User Guide for Project Pegging](https://docs.infor.com/ln/10.7/en-us/useradminlist/ln_10.7_crossppegug__en-us_60521.pdf)
- [Purchase requisition approval process](https://docs.infor.com/ln/10.4/en-us/lnolh/help/td/onlinemanual/000025.html)
- [Purchase Requisition (tdpur2600m000)](https://docs.infor.com/ln/2022.x/en-us/lnolh/tdolh/help/td/pur/tdpur2600m000.html)
- [User Guide for Requests for Quotation](https://docs.infor.com/ln/10.7/en-us/lnolh/docs/ln_10.7_procrfqug__en-us.pdf)
- [Purchase order procedure](https://docs.infor.com/ln/2023.x/en-us/lnolh/procpoug/tdom000040.html)
- [Receipt and inbound inspection procedures](https://docs.infor.com/ln/latest/en-us/lnolh/whinboundug/whom000443.html)
- [Infor LN company](https://docs.infor.com/ln/2022.x/en-us/lnolh/multisitecsug/tcom006024.html)
- [Share company data](https://docs.infor.com/ln/2026.10/en-us/lnolh/setupcompug/ega1577520029386.html)
- [Logical Tables (ttaad4120m000)](https://docs.infor.com/ln/2026.10/en-us/lnesolh/ttolh_cl/help/tt/aad/ttaad4120m000.html)

## 16. 次回確認時の優先順位

1. 導入対象のInfor LNバージョンと有効化予定機能を確定する
2. 新製品開発試作と顧客向けサンプルの代表シナリオを各1件選ぶ
3. Engineering Item／EBOMからProduction Orderを作るまでの実機デモを受ける
4. 品目未登録調達を、購買依頼・RFQ・発注・入荷・請求の段階ごとに確認する
5. Project Peggingで案件別原価が必要粒度まで取得できるか確認する
6. 同一Company、別Company、別環境の3案を、運用・統制・費用・移行で比較する
7. 標準対応と追加開発を確定し、RFP回答へ反映する

