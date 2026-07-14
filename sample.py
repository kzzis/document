"""
install_osv_scan.py

OsvScan インストーラ(exe化前提)

- ファイルサーバー(UNCパス)上の osv_scan.py を毎回コピーして配置
  (osv_scan.py の更新はファイルサーバー側の上書きだけで完結し、インストーラの作り直し不要)
- run_osv_scan.bat を生成
- タスクスケジューラに AtLogOn トリガーを登録(現在ユーザースコープ、管理者権限不要)
- バージョンファイルで冪等化(タスク未登録なら再登録するが、ファイル取得はスキップしない
  ※ osv_scan.py は毎回最新を取得する設計。スキップしたい場合は --skip-if-installed を使う)

ビルド方法 (Windows機、Python + pyinstaller インストール済みの環境で):
    pip install pyinstaller
    pyinstaller --onefile --name OsvScanInstaller install_osv_scan.py
    -> dist\\OsvScanInstaller.exe ができる。これをzipに入れてメールで配布する。

使い方 (exe化後):
    OsvScanInstaller.exe                 通常インストール/更新
    OsvScanInstaller.exe --uninstall     アンインストール
"""

import os
import sys
import shutil
import subprocess

# ==== 環境に合わせて書き換える設定値 ====
# osv_scan.py の配布元(社内ファイルサーバーの共有フォルダ、更新はここへの上書きだけで完結)
SOURCE_UNC_PATH = r"\\fileserver\share\osv_scan_dist\osv_scan.py"
# スキャン結果レポートのアップロード先
UPLOAD_UNC_PATH = r"\\fileserver\share\osv_reports"
INSTALLER_VERSION = "1.0.0"

INSTALL_DIR = os.path.join(os.environ["LOCALAPPDATA"], "OsvScan")
TASK_NAME = "OsvScan_AtLogOn"
PY_PATH = os.path.join(INSTALL_DIR, "osv_scan.py")
BAT_PATH = os.path.join(INSTALL_DIR, "run_osv_scan.bat")
VERSION_FILE = os.path.join(INSTALL_DIR, "installer_version.txt")

BAT_TEMPLATE = """@echo off
cd /d "%~dp0"

set MARKER=last_scan_date.txt
set TODAY=%date:~0,4%%date:~5,2%%date:~8,2%

if exist "%MARKER%" (
    set /p LAST_SCAN=<"%MARKER%"
) else (
    set LAST_SCAN=
)

if "%LAST_SCAN%"=="%TODAY%" (
    echo [OsvScan] 本日は実行済みのためスキップします。
    exit /b 0
)

rem 実行前に共有フォルダから最新のosv_scan.pyを同期(取得失敗時はローカルの既存版で続行)
copy /Y "{source_path}" "osv_scan.py" >nul 2>&1
if errorlevel 1 (
    echo [OsvScan] 最新版の取得に失敗。ローカルの既存バージョンで実行します。
)

python osv_scan.py --upload {upload_path}
echo %TODAY% > "%MARKER%"
""".format(source_path=SOURCE_UNC_PATH, upload_path=UPLOAD_UNC_PATH)


def log(msg: str) -> None:
    print(f"[OsvScanInstaller] {msg}")


def task_exists() -> bool:
    result = subprocess.run(
        ["schtasks", "/query", "/tn", TASK_NAME],
        capture_output=True, text=True
    )
    return result.returncode == 0


def remove_task() -> None:
    if task_exists():
        subprocess.run(
            ["schtasks", "/delete", "/tn", TASK_NAME, "/f"],
            check=True, capture_output=True, text=True
        )
        log(f"既存タスクを削除しました: {TASK_NAME}")


def register_task() -> None:
    remove_task()
    subprocess.run(
        [
            "schtasks", "/create",
            "/tn", TASK_NAME,
            "/tr", BAT_PATH,
            "/sc", "onlogon",
            "/rl", "limited",
            "/f",
        ],
        check=True, capture_output=True, text=True
    )
    log(f"タスクスケジューラに登録しました: {TASK_NAME} (AtLogOn)")


def fetch_osv_scan_py() -> bool:
    try:
        log(f"osv_scan.py を取得中: {SOURCE_UNC_PATH}")
        if not os.path.isfile(SOURCE_UNC_PATH):
            log(f"取得失敗: ファイルが見つかりません ({SOURCE_UNC_PATH})")
            return False
        shutil.copyfile(SOURCE_UNC_PATH, PY_PATH)
        size = os.path.getsize(PY_PATH)
        log(f"取得完了: {PY_PATH} ({size} bytes)")
        return True
    except Exception as e:
        log(f"取得失敗: {e}")
        return False


def uninstall() -> None:
    remove_task()
    if os.path.isdir(INSTALL_DIR):
        import shutil
        shutil.rmtree(INSTALL_DIR, ignore_errors=True)
        log(f"インストールフォルダを削除しました: {INSTALL_DIR}")
    log("アンインストール完了。")


def install() -> None:
    os.makedirs(INSTALL_DIR, exist_ok=True)

    if not fetch_osv_scan_py():
        log("osv_scan.py の取得に失敗したため、インストールを中止します。")
        log("ファイルサーバーへの疎通、共有フォルダのアクセス権限を確認してください。")
        sys.exit(1)

    with open(BAT_PATH, "w", encoding="utf-8") as f:
        f.write(BAT_TEMPLATE)
    log(f"run_osv_scan.bat を生成しました: {BAT_PATH}")

    with open(VERSION_FILE, "w", encoding="utf-8") as f:
        f.write(INSTALLER_VERSION)

    register_task()
    log(f"セットアップ完了 (installer v{INSTALLER_VERSION})")


def main() -> None:
    if "--uninstall" in sys.argv:
        uninstall()
        return
    install()


if __name__ == "__main__":
    main()
