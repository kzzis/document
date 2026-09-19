# shadcn/ui テーマ設定メモ

Vite + React + TypeScript / shadcn/ui (Base UI) / Tailwind CSS v4

## 構成

| 項目 | 値 |
|---|---|
| ビルド | Vite 8 + `@tailwindcss/vite` |
| プリミティブ | Base UI (`@base-ui/react`) |
| shadcn style | `base-vega` |
| ベースカラー | `slate` |
| アイコン | Lucide (`lucide-react`) |
| テーマ方式 | CSS Variables |
| alias | `@/*` → `src/*` |
| CSS エントリ | `src/index.css` |

## デザイン方針

- 白を基調
- 青はメインアクションや選択状態に使用
- 青みのあるグレーを補助色にする
- 清潔感のある SaaS / 管理画面風
- フラットでシンプル、Shadow は控えめ、Border を活用
- Border radius は 6〜10px
- 派手なグラデーションは使わない

## 色の対応表

`--radius: 0.625rem` (10px) を基準に `--radius-md` = 8px, `--radius-sm` = 6px が自動計算される。

| 変数 | 意図 | Tailwind 相当 |
|---|---|---|
| `--background` | ページ地色 | White |
| `--foreground` | 本文 | Slate 900 |
| `--primary` | メインアクション | **Blue 600** |
| `--primary-foreground` | primary 上の文字 | White |
| `--secondary` | 控えめなボタン | Slate 100 |
| `--muted` | 補助背景 | Slate 100 |
| `--muted-foreground` | 弱い文字 | Slate 500 |
| `--accent` | hover / 選択状態 | **Blue 50** |
| `--accent-foreground` | accent 上の文字 | Blue 700 |
| `--border` / `--input` | 枠線 | Slate 200 |
| `--ring` | フォーカスリング | **Blue 500** |
| `--destructive` | 破壊的操作 | Red 600 |

## フォント

```css
@import "@fontsource-variable/inter";
@import "@fontsource-variable/noto-sans-jp";

@theme inline {
  --font-sans: 'Inter Variable', 'Noto Sans JP Variable', system-ui, sans-serif;
}
```

Inter を先、Noto Sans JP を後に置く。ブラウザは文字ごとにフォールバックするため、
英数字は Inter、日本語は Noto Sans JP で描画される。逆順にすると英数字まで
Noto Sans JP になる。

Fontsource は unicode-range でサブセット分割して配信するので、
CJK でも実際に使う文字のファイルだけが読み込まれる。

## src/index.css（色定義の全体）

```css
:root {
    /* Base: White / Slate 900 */
    --background: oklch(1 0 0);
    --foreground: oklch(0.208 0.042 265.755);

    /* Surfaces */
    --card: oklch(1 0 0);
    --card-foreground: oklch(0.208 0.042 265.755);
    --popover: oklch(1 0 0);
    --popover-foreground: oklch(0.208 0.042 265.755);

    /* Primary: Blue 600 / White */
    --primary: oklch(0.546 0.245 262.881);
    --primary-foreground: oklch(1 0 0);

    /* Secondary: Slate 100 / Slate 900 */
    --secondary: oklch(0.968 0.007 247.896);
    --secondary-foreground: oklch(0.208 0.042 265.755);

    /* Muted: Slate 100 / Slate 500 */
    --muted: oklch(0.968 0.007 247.896);
    --muted-foreground: oklch(0.554 0.046 257.417);

    /* Accent: Blue 50 / Blue 700 */
    --accent: oklch(0.97 0.014 254.604);
    --accent-foreground: oklch(0.488 0.243 264.376);

    /* Destructive: Red 600 */
    --destructive: oklch(0.577 0.245 27.325);

    /* Border / Input: Slate 200, Ring: Blue 500 */
    --border: oklch(0.929 0.013 255.508);
    --input: oklch(0.929 0.013 255.508);
    --ring: oklch(0.623 0.214 259.815);

    /* Charts: blue scale */
    --chart-1: oklch(0.546 0.245 262.881);
    --chart-2: oklch(0.623 0.214 259.815);
    --chart-3: oklch(0.707 0.165 254.624);
    --chart-4: oklch(0.809 0.105 251.813);
    --chart-5: oklch(0.882 0.059 254.128);

    --radius: 0.625rem;

    /* Sidebar */
    --sidebar: oklch(0.984 0.003 247.858);
    --sidebar-foreground: oklch(0.208 0.042 265.755);
    --sidebar-primary: oklch(0.546 0.245 262.881);
    --sidebar-primary-foreground: oklch(1 0 0);
    --sidebar-accent: oklch(0.97 0.014 254.604);
    --sidebar-accent-foreground: oklch(0.488 0.243 264.376);
    --sidebar-border: oklch(0.929 0.013 255.508);
    --sidebar-ring: oklch(0.623 0.214 259.815);
}

.dark {
    --background: oklch(0.129 0.042 264.695);
    --foreground: oklch(0.984 0.003 247.858);

    --card: oklch(0.208 0.042 265.755);
    --card-foreground: oklch(0.984 0.003 247.858);
    --popover: oklch(0.208 0.042 265.755);
    --popover-foreground: oklch(0.984 0.003 247.858);

    --primary: oklch(0.623 0.214 259.815);
    --primary-foreground: oklch(1 0 0);

    --secondary: oklch(0.279 0.041 260.031);
    --secondary-foreground: oklch(0.984 0.003 247.858);

    --muted: oklch(0.279 0.041 260.031);
    --muted-foreground: oklch(0.704 0.04 256.788);

    --accent: oklch(0.279 0.041 260.031);
    --accent-foreground: oklch(0.882 0.059 254.128);

    --destructive: oklch(0.704 0.191 22.216);

    --border: oklch(1 0 0 / 10%);
    --input: oklch(1 0 0 / 15%);
    --ring: oklch(0.546 0.245 262.881);

    --chart-1: oklch(0.707 0.165 254.624);
    --chart-2: oklch(0.623 0.214 259.815);
    --chart-3: oklch(0.546 0.245 262.881);
    --chart-4: oklch(0.488 0.243 264.376);
    --chart-5: oklch(0.424 0.199 265.638);

    --sidebar: oklch(0.208 0.042 265.755);
    --sidebar-foreground: oklch(0.984 0.003 247.858);
    --sidebar-primary: oklch(0.623 0.214 259.815);
    --sidebar-primary-foreground: oklch(1 0 0);
    --sidebar-accent: oklch(0.279 0.041 260.031);
    --sidebar-accent-foreground: oklch(0.984 0.003 247.858);
    --sidebar-border: oklch(1 0 0 / 10%);
    --sidebar-ring: oklch(0.546 0.245 262.881);
}
```

## なぜ oklch か

Tailwind v4 が採用する知覚均等な色空間。`oklch(明度 彩度 色相)` の3値で、
明度を揃えると人間の目に同じ明るさに見える。上の値は Tailwind v4 公式の
slate / blue パレットそのままなので、`bg-blue-600` と `bg-primary` が一致する。

不透明度指定（`bg-primary/80` など）は内部的に `color-mix()` に変換される。
shadcn の secondary hover は直書きされている:

```
hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)]
```

oklch 空間で混ぜるため色相がずれず自然に暗くなる。

## components.json

```json
{
  "style": "base-vega",
  "tailwind": {
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "iconLibrary": "lucide",
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
```

## alias 設定

TypeScript 6 では `baseUrl` が非推奨（TS5101）。`paths` のみを書き、
パスは tsconfig 自身からの相対で解決させる。

`tsconfig.json` / `tsconfig.app.json`:

```json
"compilerOptions": {
  "paths": { "@/*": ["./src/*"] }
}
```

`vite.config.ts`:

```ts
resolve: {
  alias: { '@': path.resolve(import.meta.dirname, './src') },
}
```

## 導入済みコンポーネント

Button / Input / Label / Select / Dialog / Dropdown Menu / Tooltip / Separator / Badge

## ハマりどころメモ

- **import 元を必ず `@/components/ui/*` にする。** `@base-ui/react` から入れると
  スタイルが当たらず（`class` も `data-slot` も付かない）、`variant` は型エラーになる。
- **Base UI は Radix と API が違う。** ネット上の記事は Radix 前提が大半。
  `asChild` → `render={...}`、`data-[state=open]:` → `data-open:`、
  `onValueChange` は第2引数に eventDetails が付く。
- **props の正解は `node_modules` の `.d.ts` を grep するのが最速。**
- **DropdownMenuLabel は DropdownMenuGroup の中に置く。** GroupLabel は
  Group の Context から id を受け取るため、外に置くと実行時エラー。
- **縦向き Separator は親に高さが要る**（`h-full` のため）。
- **typeahead は日本語ラベルでは機能しない。** IME がキー入力を横取りするため。
