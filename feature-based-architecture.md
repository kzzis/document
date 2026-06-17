# React + Vite Feature-based アーキテクチャ導入提案

**対象：** DXチーム内部  
**目的：** 新フロントエンド開発の設計指針策定

---

## 1. 現行システムの構成を整理する

現行は Classic ASP で、ファイルの役割をサフィックスで区別している。

| サフィックス | 役割 | 例 |
|---|---|---|
| `f` | 画面（フォーム） | `123f.asp` |
| `b` | DBアクセス | `123b.asp` |
| `w` | モーダル・サブウィンドウ | `123w.asp` |

メニュー単位では `Resw`（埼玉工場業務）のようなグループ名で機能をまとめており、
**「メニュー名で業務を把握する」という感覚は、チームにすでに根付いている。**

---

## 2. React + Vite への移行でやりたいこと

この「メニュー名で業務を把握する」感覚を、そのままディレクトリ構造に持ち込む。

> **業務メニューの単位 ＝ Feature ディレクトリの単位**

サフィックス（f/b/w）が担っていた役割分担は、Feature 内のサブディレクトリで表現する。
命名規則を覚えなくても、**メニュー名を知っていればコードが探せる**構成にする。

---

## 3. 構成の対応イメージ

```
【ASP の感覚】                        【Feature-based の構成】

Resw（埼玉工場業務）
  ├── 受注管理                →    features/saitama-orders/
  │     123f（画面）          →      components/OrderForm.tsx
  │     123b（DBアクセス）    →      api/orderApi.ts
  │     123w（モーダル）      →      components/OrderDetailModal.tsx
  │
  ├── 在庫照会                →    features/saitama-inventory/
  └── 出荷指示                →    features/saitama-shipping/
```

メニューを開いたら機能があった、というASPの構造を、ディレクトリでそのまま再現する。

---

## 4. 提案するディレクトリ構成

```
src/
├── features/                        ← 業務機能の本体
│   │
│   ├── saitama-orders/              ← Resw「受注管理」
│   │   ├── components/
│   │   │   ├── OrderForm.tsx        ← 旧 123f（入力画面）
│   │   │   └── OrderDetailModal.tsx ← 旧 123w（モーダル）
│   │   ├── api/
│   │   │   └── orderApi.ts          ← 旧 123b（DBアクセス）
│   │   ├── hooks/
│   │   │   └── useOrderForm.ts      ← 画面ロジック・状態管理
│   │   ├── types/
│   │   │   └── order.ts
│   │   └── index.ts                 ← 外部への公開インターフェース
│   │
│   ├── saitama-inventory/           ← Resw「在庫照会」
│   └── saitama-shipping/            ← Resw「出荷指示」
│
├── shared/                          ← 複数 Feature をまたぐ共通部品
│   ├── components/                  ← 汎用UIコンポーネント
│   ├── hooks/
│   ├── utils/
│   └── types/
│
├── pages/                           ← ルーティング用の薄いページ層
│   └── SaitamaOrdersPage.tsx        ← features を呼ぶだけ
│
└── app/
    ├── router.tsx
    └── App.tsx
```

---

## 5. Feature 内の責務分担

| 旧 ASP | Feature 内の位置 | 内容 |
|---|---|---|
| `123f.asp` | `components/OrderForm.tsx` | 入力・表示画面 |
| `123b.asp` | `api/orderApi.ts` | APIコール・データ取得 |
| `123w.asp` | `components/OrderDetailModal.tsx` | モーダル・サブ画面 |
| ―（暗黙） | `hooks/useOrderForm.ts` | 画面ロジック・状態管理 |
| ―（暗黙） | `types/order.ts` | 型定義 |

---

## 6. 守るべきルール（依存の方向）

Feature-based を機能させるために、依存の向きを一方向に保つ。

```
OK  pages/    → features/   （ページは Feature を呼ぶ）
OK  features/ → shared/     （Feature は Shared を使う）

NG  features/saitama-orders/ → features/saitama-inventory/
    （Feature 同士の直接参照は避ける）
```

Feature 間で共通化したいものが出てきたら、`shared/` に昇格させるルールにする。

---

## 7. 段階的な進め方

新規画面から始めて、必要に応じて順次移行していく。

```
Phase 1（新規開発）
  新しい画面・機能は最初から Feature-based で作る

Phase 2（順次移行）
  改修が発生した機能を Feature-based に切り出す
  ※ 触らない機能は無理に移行しない

Phase 3（整理）
  shared/ の共通部品を整備し、チームのルールとして定着させる
```

---

## 8. まとめ

| 観点 | 現行 ASP | React + Feature-based |
|---|---|---|
| ファイルの探し方 | サフィックス（f/b/w）で判断 | メニュー名 → Feature ディレクトリ |
| 変更のまとまり | 役割別に分散 | Feature 内に集約 |
| 並行開発 | Feature 単位で分担しやすい | Feature 単位で分担しやすい |
| 新メンバーの習熟 | 命名規則を覚える | 業務知識だけで探せる |

**ASP 時代に培った「メニュー＝機能のまとまり」という感覚をそのまま引き継いで、
React でも同じように業務単位でコードを整理できる構成にする。**
