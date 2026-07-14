<#
.SYNOPSIS
    2つのIPを常時ping監視し、「片方だけ落ちた」「両方落ちた」を判定してアラート+tracertを記録するスクリプト

.USAGE
    .\Monitor-Ips.ps1 -Ip1 192.168.1.1 -Ip2 8.8.8.8
    .\Monitor-Ips.ps1 -Ip1 192.168.1.1 -Ip2 8.8.8.8 -PingIntervalSec 5 -TracertIntervalSec 60

.NOTES
    - pingは PingIntervalSec ごとに毎回実行し、結果を常時ログに記録します
    - 2つのIPの結果を組み合わせて以下の4状態を判定します
        BOTH_UP        : 両方生存
        ONLY_IP1_DOWN  : IP1のみ死亡(IP2は生存)
        ONLY_IP2_DOWN  : IP2のみ死亡(IP1は生存)
        BOTH_DOWN      : 両方死亡
    - 組み合わせ状態が変化した瞬間に [ALERT] としてログに強調記録し、
      死亡している方のIPに対して即座にtracertを実行します
      (片方だけ死んでいる場合は経路上のどこで切れているか特定しやすくなります)
    - さらにTracertIntervalSecごとに両IPの定期tracertも記録します(任意、0で無効)
    - ログファイルはスクリプトと同じフォルダの monitor_ips.log
    - Ctrl+Cで終了できます
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Ip1,

    [Parameter(Mandatory = $true)]
    [string]$Ip2,

    [int]$PingIntervalSec = 5,

    [int]$TracertIntervalSec = 60
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "monitor_ips.log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

function Test-IpUp {
    param([string]$IpAddress)
    $result = Test-Connection -ComputerName $IpAddress -Count 1 -ErrorAction SilentlyContinue
    if ($result) {
        Write-Log "PING $IpAddress -> UP (応答時間: $($result.ResponseTime)ms)"
        return $true
    } else {
        Write-Log "PING $IpAddress -> DOWN (応答なし)"
        return $false
    }
}

function Invoke-Tracert {
    param([string]$IpAddress)
    Write-Log "----- tracert $IpAddress 開始 -----"
    try {
        $result = tracert -d -w 1000 $IpAddress 2>&1
        foreach ($line in $result) {
            Add-Content -Path $LogFile -Value $line
        }
    } catch {
        Write-Log "tracert 実行エラー: $_"
    }
    Write-Log "----- tracert $IpAddress 終了 -----"
}

function Get-CombinedState {
    param([bool]$Up1, [bool]$Up2)
    if ($Up1 -and $Up2) { return "BOTH_UP" }
    if (-not $Up1 -and -not $Up2) { return "BOTH_DOWN" }
    if (-not $Up1) { return "ONLY_IP1_DOWN" }
    return "ONLY_IP2_DOWN"
}

Write-Log "監視開始: IP1=$Ip1, IP2=$Ip2, Ping間隔=${PingIntervalSec}秒, Tracert間隔=${TracertIntervalSec}秒"

$prevState = ""
$lastTracertTime = [datetime]::MinValue

try {
    while ($true) {
        $up1 = Test-IpUp -IpAddress $Ip1
        $up2 = Test-IpUp -IpAddress $Ip2
        $state = Get-CombinedState -Up1 $up1 -Up2 $up2

        if ($state -ne $prevState) {
            switch ($state) {
                "BOTH_UP"       { Write-Log "[ALERT] 状態変化 -> 両方生存 (BOTH_UP)" }
                "BOTH_DOWN"     { Write-Log "[ALERT] 状態変化 -> 両方死亡 (BOTH_DOWN) : 上位回線/共通経路の障害の可能性" }
                "ONLY_IP1_DOWN" { Write-Log "[ALERT] 状態変化 -> IP1($Ip1)のみ死亡、IP2($Ip2)は生存 (ONLY_IP1_DOWN)" }
                "ONLY_IP2_DOWN" { Write-Log "[ALERT] 状態変化 -> IP2($Ip2)のみ死亡、IP1($Ip1)は生存 (ONLY_IP2_DOWN)" }
            }

            # 死んでいるIPに対して即座にtracertを実行(原因切り分け用)
            if (-not $up1) { Invoke-Tracert -IpAddress $Ip1 }
            if (-not $up2) { Invoke-Tracert -IpAddress $Ip2 }

            $prevState = $state
        }

        # 定期tracert(任意)
        if ($TracertIntervalSec -gt 0) {
            $now = Get-Date
            if (($now - $lastTracertTime).TotalSeconds -ge $TracertIntervalSec) {
                Invoke-Tracert -IpAddress $Ip1
                Invoke-Tracert -IpAddress $Ip2
                $lastTracertTime = $now
            }
        }

        Start-Sleep -Seconds $PingIntervalSec
    }
} finally {
    Write-Log "監視を終了します"
}
