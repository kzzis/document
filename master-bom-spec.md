# マスターBOM(許可ライブラリ一覧)管理仕様書

## 1. 目的

企業として使用を許可するPythonライブラリを、CycloneDX形式のマスターBOM
(`approved-libs.json`)として管理する。各プロジェクトの実BOMとこのマスター
BOMを突合し、未承認コンポーネントの混入を検知できるようにする。

## 2. 全体方針

| 項目 | 方針 |
|---|---|
| 対象言語 | Python のみ(初期スコープ) |
| 依存関係 | 直接依存(direct)・推移的依存(transitive)の両方を含める |
| 複数バージョン | 同一ライブラリの複数バージョン許可を可能とする |
| ライセンス情報 | 含める(Syftによる自動検出) |
| CI連携 | 使用しない。ローカル実行 + 生成物をgitコミットする運用 |
| 承認プロセス | Gitリポジトリへの変更はPRベース、レビュー必須 |

## 3. ディレクトリ構成

```
security/approved-libraries/
├── requirements/
│   ├── <ライブラリ名>/
│   │   └── <バージョン>/
│   │       └── requirements.txt   # 例: requests==2.31.0 の1行のみ
│   └── ...
├── boms/                          # 中間生成物(ライブラリ×バージョンごとのBOM)
│   └── <ライブラリ名>-<バージョン>-bom.json
├── build.sh                       # ビルドスクリプト(venv作成→Syftスキャン)
├── merge_boms.py                  # boms/ を1つのマスターBOMに統合
└── approved-libs.json             # 最終成果物(マスターBOM)。git管理対象
```

### 3.1 命名規則

- ディレクトリパス: `requirements/<lib>/<version>/requirements.txt`
- `requirements.txt` は当該ライブラリ・バージョンの1行のみを記載
  ```
  requests==2.31.0
  ```
- 内部識別子(tag): `<lib>-<version>`(例: `requests-2.31.0`)
  - venv名、BOMファイル名に使用

## 4. 承認フロー

1. 承認したいライブラリ・バージョンについて、対応するディレクトリと
   `requirements.txt` を作成する
2. Gitea上でPRを作成する。PR説明に「なぜこのライブラリ/バージョンが
   必要か」を記載する
3. レビュアーがCodeRabbit + 人間レビューで内容を確認し、承認・マージする
4. マージ後、承認者(または申請者)がローカルで `build.sh` を実行し、
   `approved-libs.json` を再生成する
5. 再生成した `approved-libs.json` を追加コミットしてプッシュする

> CIを使わないため、ステップ4・5の実行漏れが唯一のリスク。
> `build.sh` の末尾に差分チェックを入れ、実行忘れを可視化する(6.3参照)。

## 5. BOM生成処理

### 5.1 処理の流れ(1ライブラリ・バージョンあたり)

```
requirements.txt
    ↓ python -m venv (専用の使い捨てvenvを作成)
venv
    ↓ pip install -r requirements.txt (依存関係含めて全インストール)
インストール済み環境
    ↓ syft dir:<venv path> -o cyclonedx-json
boms/<tag>-bom.json (ライセンス情報込み)
    ↓ venv削除
```

### 5.2 venvを都度作り直す理由

Pythonは同一環境内に同一パッケージの複数バージョンを共存させられない。
そのため、ライブラリ・バージョンの組み合わせごとに独立したvenvを作成し、
使用後は破棄する。

### 5.3 依存関係を含める理由

`pip install -r requirements.txt` は `--no-deps` を付けず、指定パッケージの
推移的依存も含めて全てインストールする。これにより実運用で実際に展開される
コンポーネント一式が許可リストに反映される。

### 5.4 ライセンス情報取得ツールにSyftを採用する理由

`cyclonedx-py` はライセンスフィールドが空になる既知の問題があるため、
ディレクトリ(venv)を直接スキャンしてライセンス情報込みのCycloneDX JSONを
生成できるSyftを採用する。

```bash
syft dir:"/tmp/venv-${tag}" -o cyclonedx-json="boms/${tag}-bom.json"
```

### 5.5 build.sh

```bash
#!/bin/bash
set -e
mkdir -p boms

for f in requirements/*/*/requirements.txt; do
  lib=$(echo "$f" | cut -d/ -f2)
  ver=$(echo "$f" | cut -d/ -f3)
  tag="${lib}-${ver}"

  python -m venv "/tmp/venv-${tag}"
  "/tmp/venv-${tag}/bin/pip" install -r "$f" -q

  # direct指定パッケージ名を抽出(scope判定用)
  grep -vE '^\s*#|^\s*$' "$f" | sed -E 's/[=<>!~].*//' | tr 'A-Z' 'a-z' \
    > "/tmp/${tag}-direct.txt"

  syft dir:"/tmp/venv-${tag}" -o cyclonedx-json="boms/${tag}-bom.json"

  rm -rf "/tmp/venv-${tag}"
done

python merge_boms.py

# 生成物の未コミットチェック
if ! git diff --quiet approved-libs.json 2>/dev/null; then
  echo "⚠️  approved-libs.json is out of date. Commit the regenerated file."
fi
```

## 6. direct / transitive 判定

### 6.1 目的

マスターBOM上の各コンポーネントが「人間が明示承認したもの(direct)」か
「承認済みライブラリの依存として自動的に含まれたもの(transitive)」かを
区別し、将来の禁止判断・監査説明を正確に行えるようにする。

### 6.2 判定方法

`requirements.txt` に明記された行(direct名一覧)と、venv内の全パッケージ
(Syftスキャン結果)を突合し、一致しないものをtransitiveとする。

### 6.3 merge_boms.py

```python
import json
import glob

all_components = {}

for bom_path in glob.glob("boms/*-bom.json"):
    tag = bom_path.split("/")[-1].replace("-bom.json", "")

    direct_path = f"/tmp/{tag}-direct.txt"
    with open(direct_path) as f:
        direct_names = set(line.strip() for line in f if line.strip())

    with open(bom_path) as f:
        bom = json.load(f)

    for c in bom.get("components", []):
        purl = c.get("purl")
        if not purl:
            continue

        comp_name = c.get("name", "").lower()
        scope = "direct" if comp_name in direct_names else "transitive"

        c.setdefault("properties", []).extend([
            {"name": "approved-source", "value": tag},
            {"name": "dependency-scope", "value": scope},
        ])

        # 同一purlが複数setから来た場合、directを優先
        if purl in all_components:
            existing_scope = next(
                (p["value"] for p in all_components[purl].get("properties", [])
                 if p["name"] == "dependency-scope"), None
            )
            if existing_scope == "direct":
                continue
        all_components[purl] = c

master_bom = {
    "bomFormat": "CycloneDX",
    "specVersion": "1.6",
    "version": 1,
    "components": list(all_components.values()),
}

with open("approved-libs.json", "w") as f:
    json.dump(master_bom, f, indent=2, ensure_ascii=False)

print(f"{len(all_components)} approved components merged.")
```

### 6.4 出力データ構造(properties)

各コンポーネントには以下のカスタムプロパティが付与される。

| プロパティ名 | 値の例 | 意味 |
|---|---|---|
| `approved-source` | `requests-2.31.0` | どのディレクトリ(承認単位)由来か |
| `dependency-scope` | `direct` / `transitive` | 明示承認か、自動的に含まれたものか |

## 7. マスターBOM(approved-libs.json)の位置づけ

- `bomFormat: CycloneDX`, `specVersion: 1.6` に準拠
- `components` には承認済みライブラリ(direct)とその依存(transitive)が
  purlをキーに重複排除された状態で格納される
- ライセンス情報はSyftが検出した内容がそのまま `licenses` フィールドに反映される
- 生成物であり手動編集はしない。変更は必ず `requirements/` の追加・削除経由で行う

## 8. 突合(各プロジェクトとの比較)運用

- 各プロジェクトはCI等で実BOMを生成(`cyclonedx-py` または `syft` を使用)
- 実BOMの `components[].purl` を `approved-libs.json` の許可PURL集合と比較
- 未許可のPURLが存在する場合、違反として検出・通知する
- `dependency-scope` を利用し、「directのみ厳格にチェック」「transitiveは
  参考情報として表示のみ」といった重み付けも可能

## 9. whlファイル配布(ファイルサーバー経由)

### 9.1 目的

マスターBOMで許可したライブラリを、社内ファイルサーバー(UNCパス)経由で
whl形式で配布し、`pip install --no-index` により承認済みライブラリ以外を
インストールできない状態を作る。

### 9.2 配布方式

| 方式 | 特徴 |
|---|---|
| フラットな `--find-links` ディレクトリ | サーバープロセス不要。UNCパスに置くだけ。本仕様ではこちらを採用 |
| PEP 503準拠 simple index | `--index-url` で通常のPyPIのように使える。`index.html`の自動生成が必要なため見送り |

### 9.3 whl取得スクリプト

`requirements/*/*/requirements.txt` をそのまま利用し、`pip download` で
PyPI上の既存whlを取得する。`pip wheel` はsdistしかないパッケージを
ローカルでビルドしようとしてコンパイラ依存が発生するため使用しない。

```bash
#!/bin/bash
set -e
mkdir -p wheelhouse

for f in requirements/*/*/requirements.txt; do
  pip download -r "$f" -d wheelhouse/ \
    --platform win_amd64 \
    --python-version 311 \
    --only-binary=:all: \
    --no-cache-dir
done
```

- `--platform` / `--python-version`: 社内実行環境を固定し、環境不一致のwhlが
  混入するのを防ぐ
- `--only-binary=:all:`: whlが存在しないパッケージ(sdistのみ)はエラーにし、
  社内で利用不可なパッケージを事前検知する
- C拡張を含むパッケージ(numpy, pandas等)はOS・Pythonバージョンごとに
  別whlが必要な点に留意する

### 9.4 ファイルサーバーへの配置

```bash
cp -r wheelhouse/* //fileserver/share/python-wheels/
```

```
\\fileserver\share\python-wheels\
├── requests-2.31.0-py3-none-any.whl
├── urllib3-2.0.7-py3-none-any.whl
├── flask-2.3.0-py3-none-any.whl
└── ...
```

### 9.5 クライアント側の利用方法

```bash
pip install requests==2.31.0 --find-links \\fileserver\share\python-wheels --no-index
```

`--no-index` を付与することで外部PyPIへ一切アクセスせず、社内ファイル
サーバー上のwhlのみからインストールする。これにより「マスターBOMで
承認したものだけがインストール可能」という強制力を持たせる。

固定設定する場合(Windows):
```ini
; pip.ini
[global]
find-links = \\fileserver\share\python-wheels
no-index = true
```

### 9.6 マスターBOMとの整合性チェック

`wheelhouse/` 内のファイル名とマスターBOMのPURL一覧を突合し、
「承認済みだがwhlが存在しない」「whlは存在するが承認リストにない」
というズレを検知する。

```python
import json, glob, re

with open("approved-libs.json") as f:
    approved = {c["purl"] for c in json.load(f)["components"]}

for whl in glob.glob("wheelhouse/*.whl"):
    m = re.match(r"([^-]+)-([^-]+)-", whl.split("/")[-1])
    if m:
        name, ver = m.group(1).lower().replace("_", "-"), m.group(2)
        purl = f"pkg:pypi/{name}@{ver}"
        if purl not in approved:
            print(f"⚠️ Not in master BOM: {whl}")
```

### 9.7 整合性の強化(オプション)

- whlの改ざん検知が必要な場合、`pip download --require-hashes` と
  `pip hash <file>` によるSHA256事前計算・検証を組み合わせる
- `build.sh`(セクション5.5)にwhlダウンロード・配布処理を統合し、
  `requirements/` 更新 → BOM再生成 → whl再配布 を一連のフローにまとめる
  ことも可能

## 10. 既知の制約・今後の課題

- 依存関係を含める方針のため、1つのライブラリを承認すると、その推移的
  依存も自動的に許可リストに追加される。「厳密な許可制」ではなく
  「明示的に禁止したいものを弾く」緩やかな運用に近くなる点に留意する
- CIを使わないため、`requirements/` の変更と `approved-libs.json` の
  再生成にタイムラグが生じうる。運用ルール(PRマージ後は必ず
  `build.sh` を実行する)を徹底する
- バージョン範囲指定(例: `4.x` のような許容範囲)には未対応。
  現状は固定バージョンのみのサポート
- ライブラリ名・バージョンのtypoや実在しないバージョンの検証は
  `pip install` 失敗時にのみ検出される(事前バリデーションなし)
