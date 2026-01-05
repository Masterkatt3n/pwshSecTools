# RunDefenderFullScan.ps1

$logFile = "$env:USERPROFILE\DefenderFullScan.log"
$scanStart = Get-Date

function Show-Toast {
    param (
        [string]$Title,
        [string]$Message
    )

    Import-Module BurntToast -ErrorAction SilentlyContinue
    New-BurntToastNotification -Text $Title, $Message
}

function Log {
    param([string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "[$ts] $Message"
}

Log "=== Starting Microsoft Defender FULL scan ==="

# Check Execution Policy and(will install) toast notification module
$ep = Get-ExecutionPolicy -List | Out-String
Log "Execution Policy:`n$ep"

$toastOn = $false
if (-not(Get-Module -ListAvailable -Name BurntToast)) {
    try {
        Install-Module BurntToast `
            -Scope CurrentUser `
            -Force `
            -Confirm:$false `
            -ErrorAction Stop
        $toastOn = $true
        Log "Notification module sucessfully installed"
    } catch {
        Log "Failed to install BurntToast: $($_.Exception.Message)"
    }
} else {
    try {
        Import-Module BurntToast -ErrorAction Stop
        $toastOn = $true
        Show-Toast `
            -Title "✔ Defender Full Scan: Running..." `
            -Message "BurntToast module enabled, proceeding with Full Scan..."
        Log "ToastNotify enabled"

    } catch {
        Log "BurntToast present but failed to import: $($_.Exception.Message)"
    }
}

# Snapshot before scan
$statusBefore = Get-MpComputerStatus
Log "Engine: $($statusBefore.AMEngineVersion)"
Log "Last full scan: $($statusBefore.FullScanEndTime)"

# If multiple sessions, cleanup before moving on
Get-Job -Name 'DefenderScanHeartbeat' -ErrorAction SilentlyContinue |
    Stop-Job -ErrorAction SilentlyContinue

Get-Job -Name 'DefenderScanHeartbeat' -ErrorAction SilentlyContinue |
    Remove-Job -Force -ErrorAction SilentlyContinue

# Heartbeat job
$heartbeat = Start-Job -Name 'DefenderScanHeartbeat' -ScriptBlock {
    param($startTime, $logFile)
    while ($true) {
        Start-Sleep -Seconds 60
        $elapsed = [math]::Max(1, [int]((Get-Date) - $startTime).TotalMinutes)
        $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content -Path $logFile -Value "[$ts] Scan still running ($elapsed min elapsed)"
    }
} -ArgumentList $scanStart, $logFile

try {
    # Start scan (elevated)
    Start-Process powershell `
        -Verb RunAs `
        -Wait `
        -ArgumentList '-NoProfile -Command "Start-MpScan -ScanType FullScan"'
} finally {
    if ($heartbeat) {
        try {
            if ($heartbeat.State -ne 'Stopped') {
                Stop-Job -Job $heartbeat | Out-Null
            }
        } catch {
        }

        try {
            Remove-Job -Job $heartbeat -Force | Out-Null
        } catch {
        }
    }
}

$scanEnd = Get-Date
$duration = New-TimeSpan $scanStart $scanEnd

Log "Full scan finished"
Log "Duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s"

# Snapshot after scan
$statusAfter = Get-MpComputerStatus
Log "Threats detected: $($statusAfter.ThreatsDetected)"
Log "FullScanEndTime: $($statusAfter.FullScanEndTime)"

# Threat details
$detections = Get-MpThreatDetection -ErrorAction SilentlyContinue |
    Where-Object { $_.InitialDetectionTime -ge $scanStart }

if ($detections) {
    Show-Toast `
        -Title "⚠ Microsoft Defender Alert" `
        -Message "Threats detected during full scan. Check Protection History."

    Log "Threat detections:"
    foreach ($d in $detections) {
        Log "  Threat: $($d.ThreatName)"
        Log "  Severity: $($d.SeverityID)"
        Log "  ActionSuccess: $($d.ActionSuccess)"
        Log "  Resources: $($d.Resources)"
    }
} else {
    Log "No threat detections reported."
}

if (-not $detections -and $toastOn) {
    Show-Toast `
        -Title "✔ Defender Scan Complete" `
        -Message "Full scan completed. No new threats detected."
}

Log "=== Defender full scan completed ==="
