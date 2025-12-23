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

# Log toast module import success
if (Get-Module -ListAvailable -Name BurntToast) {
  Log "BurntToast module found; toast notifications available"
} else {
  Log "BurntToast module not found; toast notifications disabled"
}

# Snapshot before scan
$statusBefore = Get-MpComputerStatus
Log "Engine: $($statusBefore.AMEngineVersion)"
Log "Last full scan: $($statusBefore.FullScanEndTime)"

# Heartbeat job
$heartbeat = Start-Job -ScriptBlock {
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
  # Stop heartbeat
  Stop-Job $heartbeat -Force | Out-Null
  Remove-Job $heartbeat | Out-Null
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

Log "=== Defender full scan completed ==="
